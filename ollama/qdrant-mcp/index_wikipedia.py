#!/usr/bin/env python3
"""Download and index Wikipedia into Qdrant.

Supports multiple Wikipedia formats:
- Individual .txt files (GitHub dump)
- Concatenated .txt files (Kaggle)
- JSONL format (Hugging Face)
"""

import asyncio
import json
import logging
import os
import sys
import uuid
from pathlib import Path
from typing import List, Optional, Tuple
import re

import httpx

# Configuration
QDRANT_URL = os.getenv("QDRANT_URL", "http://192.168.0.158:6333")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")
COLLECTION = os.getenv("QDRANT_COLLECTION", "wikipedia")
CHUNK_SIZE = 500  # Characters per chunk
BATCH_SIZE = 50   # Vectors per batch (reduced for stability)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def generate_embedding(text: str) -> Optional[List[float]]:
    """Generate embedding using Ollama."""
    try:
        async with httpx.AsyncClient(base_url=OLLAMA_URL, timeout=120.0) as client:
            response = await client.post(
                "/api/embeddings",
                json={"model": EMBEDDING_MODEL, "prompt": text}
            )
            if response.status_code == 200:
                return response.json().get("embedding")
            else:
                logger.error(f"Embedding failed: {response.status_code}")
    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
    return None


async def ensure_collection(vector_size: int = 768):
    """Ensure Qdrant collection exists."""
    async with httpx.AsyncClient(base_url=QDRANT_URL, timeout=30.0) as client:
        # Check if exists
        response = await client.get(f"/collections/{COLLECTION}")
        if response.status_code == 200:
            logger.info(f"Collection '{COLLECTION}' exists")
            return True
        
        # Create collection
        collection_config = {
            "vectors": {
                "size": vector_size,
                "distance": "Cosine"
            }
        }
        response = await client.put(
            f"/collections/{COLLECTION}",
            json=collection_config
        )
        if response.status_code in (200, 201):
            logger.info(f"Created collection '{COLLECTION}'")
            return True
        else:
            logger.error(f"Failed to create collection: {response.status_code} {response.text}")
            return False


def chunk_text(text: str, chunk_size: int = CHUNK_SIZE) -> List[str]:
    """Split text into chunks, preserving sentence boundaries when possible."""
    # Clean text
    text = re.sub(r'\s+', ' ', text.strip())
    if len(text) <= chunk_size:
        return [text]
    
    chunks = []
    sentences = re.split(r'([.!?]\s+)', text)
    current_chunk = []
    current_length = 0
    
    i = 0
    while i < len(sentences):
        sentence = sentences[i]
        if i + 1 < len(sentences):
            sentence += sentences[i + 1]  # Include punctuation
            i += 2
        else:
            i += 1
        
        sentence_length = len(sentence)
        
        if current_length + sentence_length > chunk_size and current_chunk:
            chunks.append(''.join(current_chunk))
            current_chunk = [sentence]
            current_length = sentence_length
        else:
            current_chunk.append(sentence)
            current_length += sentence_length
    
    if current_chunk:
        chunks.append(''.join(current_chunk))
    
    return chunks


async def index_batch(points: List[dict]):
    """Index a batch of points in Qdrant."""
    async with httpx.AsyncClient(base_url=QDRANT_URL, timeout=120.0) as client:
        try:
            response = await client.put(
                f"/collections/{COLLECTION}/points",
                json={"points": points}
            )
            return response.status_code in (200, 201)
        except Exception as e:
            logger.error(f"Batch indexing error: {e}")
            return False


async def index_article(title: str, text: str, article_id: Optional[str] = None):
    """Index a single Wikipedia article."""
    if not text or len(text.strip()) < 50:  # Skip very short articles
        return 0
    
    chunks = chunk_text(text)
    if not chunks:
        return 0
    
    # Generate embeddings for all chunks
    embeddings = []
    for chunk in chunks:
        embedding = await generate_embedding(chunk)
        if embedding:
            embeddings.append(embedding)
        else:
            logger.warning(f"Failed to generate embedding for chunk")
            # Continue with other chunks
    
    if not embeddings:
        return 0
    
    # Match embeddings to chunks (skip chunks without embeddings)
    valid_chunks = []
    valid_embeddings = []
    for chunk, embedding in zip(chunks, embeddings):
        if embedding:
            valid_chunks.append(chunk)
            valid_embeddings.append(embedding)
    
    if not valid_chunks:
        return 0
    
    # Create points
    points = []
    for i, (chunk, embedding) in enumerate(zip(valid_chunks, valid_embeddings)):
        point_id = str(uuid.uuid4())
        points.append({
            "id": point_id,
            "vector": embedding,
            "payload": {
                "text": chunk,
                "title": title,
                "article_id": article_id or title,
                "chunk_index": i,
                "total_chunks": len(valid_chunks),
                "source_type": "wikipedia"
            }
        })
    
    # Index in batches
    indexed = 0
    for i in range(0, len(points), BATCH_SIZE):
        batch = points[i:i + BATCH_SIZE]
        if await index_batch(batch):
            indexed += len(batch)
        else:
            logger.error(f"Failed to index batch {i//BATCH_SIZE + 1}")
    
    return indexed


def parse_txt_files(directory: Path) -> List[Tuple[str, str, str]]:
    """Parse individual .txt files (GitHub format)."""
    articles = []
    txt_files = list(directory.rglob("*.txt"))
    logger.info(f"Found {len(txt_files)} .txt files")
    
    for txt_file in txt_files:
        try:
            # Filename is usually the title
            title = txt_file.stem.replace('_', ' ')
            content = txt_file.read_text(encoding='utf-8', errors='ignore').strip()
            
            if content and len(content) > 50:
                articles.append((title, content, title))
        except Exception as e:
            logger.debug(f"Error reading {txt_file}: {e}")
            continue
    
    return articles


def parse_concatenated_txt(file_path: Path) -> List[Tuple[str, str, str]]:
    """Parse concatenated .txt file (Kaggle format - title on line, content follows)."""
    articles = []
    current_title = None
    current_content = []
    
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # Check if line is a title (usually all caps or starts with specific pattern)
            if line.isupper() or (len(line) < 100 and not line.endswith('.') and not line.endswith(',')):
                # Save previous article
                if current_title and current_content:
                    content = ' '.join(current_content)
                    if len(content) > 50:
                        articles.append((current_title, content, current_title))
                
                # Start new article
                current_title = line
                current_content = []
            else:
                current_content.append(line)
        
        # Save last article
        if current_title and current_content:
            content = ' '.join(current_content)
            if len(content) > 50:
                articles.append((current_title, content, current_title))
    
    return articles


def parse_jsonl(file_path: Path) -> List[Tuple[str, str, str]]:
    """Parse JSONL file (Kaggle/Hugging Face format - one JSON object per line)."""
    articles = []
    
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line_num, line in enumerate(f, 1):
            try:
                data = json.loads(line.strip())
                # Extract title and text (format varies by dataset)
                title = data.get('title') or data.get('name') or f"Article_{line_num}"
                text = data.get('text') or data.get('content') or data.get('body') or ''
                
                # Some datasets have structured content
                if not text and 'sections' in data:
                    sections = []
                    for section in data.get('sections', []):
                        if isinstance(section, dict):
                            sections.append(section.get('text', ''))
                        elif isinstance(section, str):
                            sections.append(section)
                    text = ' '.join(sections)
                
                if text and len(text.strip()) > 50:
                    article_id = data.get('id') or data.get('page_id') or title
                    articles.append((title, text, str(article_id)))
            except json.JSONDecodeError as e:
                logger.debug(f"Error parsing line {line_num}: {e}")
                continue
            except Exception as e:
                logger.debug(f"Error processing line {line_num}: {e}")
                continue
    
    return articles


async def main():
    """Main indexing function."""
    import argparse
    
    # Declare globals first
    global COLLECTION, CHUNK_SIZE
    
    parser = argparse.ArgumentParser(description="Index Wikipedia into Qdrant")
    parser.add_argument("--dir", help="Directory containing Wikipedia .txt files (can be NAS path)")
    parser.add_argument("--file", help="Path to Wikipedia file (.txt or .jsonl, can be NAS path)")
    parser.add_argument("--limit", type=int, help="Limit number of articles (for testing)")
    parser.add_argument("--collection", default=COLLECTION, help="Qdrant collection name")
    parser.add_argument("--chunk-size", type=int, default=CHUNK_SIZE, help="Characters per chunk")
    
    args = parser.parse_args()
    
    # Update global variables
    COLLECTION = args.collection
    CHUNK_SIZE = args.chunk_size
    
    # Ensure collection exists
    await ensure_collection()
    
    # Get articles
    articles = []
    if args.dir:
        directory = Path(args.dir)
        if not directory.exists():
            logger.error(f"Directory not found: {directory}")
            return
        articles = parse_txt_files(directory)
    elif args.file:
        file_path = Path(args.file)
        if not file_path.exists():
            logger.error(f"File not found: {file_path}")
            return
        
        # Detect file type
        if file_path.suffix == '.jsonl' or 'jsonl' in file_path.name.lower():
            logger.info("Detected JSONL format")
            articles = parse_jsonl(file_path)
        else:
            logger.info("Detected text format")
            articles = parse_concatenated_txt(file_path)
    else:
        logger.error("Must provide --dir or --file")
        return
    
    if args.limit:
        articles = articles[:args.limit]
        logger.info(f"Limited to {len(articles)} articles for testing")
    
    logger.info(f"Found {len(articles)} articles to index")
    
    if not articles:
        logger.error("No articles found!")
        return
    
    # Index articles
    total_indexed = 0
    total_chunks = 0
    
    for i, (title, text, article_id) in enumerate(articles, 1):
        if i % 100 == 0:
            logger.info(f"Progress: {i}/{len(articles)} articles, {total_indexed} chunks indexed")
        
        indexed = await index_article(title, text, article_id)
        total_indexed += indexed
        total_chunks += len(chunk_text(text))
    
    logger.info(f"✅ Complete!")
    logger.info(f"   Articles processed: {len(articles)}")
    logger.info(f"   Chunks indexed: {total_indexed}")
    logger.info(f"   Collection: {COLLECTION}")


if __name__ == "__main__":
    asyncio.run(main())
