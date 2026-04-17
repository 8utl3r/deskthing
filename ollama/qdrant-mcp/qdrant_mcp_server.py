#!/usr/bin/env python3
"""Qdrant MCP Server

MCP server for Qdrant vector database operations.
Provides tools for:
- Searching vectors
- Indexing text
- Managing collections
- Health checks
"""

import asyncio
import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional

import httpx
from mcp.server.fastmcp import FastMCP

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment
QDRANT_URL = os.getenv("QDRANT_URL", "http://192.168.0.158:6333")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")
DEFAULT_COLLECTION = os.getenv("QDRANT_COLLECTION", "atlas_conversations")

# HTTP clients - created lazily to avoid event loop issues
_qdrant_client = None
_ollama_client = None

def get_qdrant_client():
    """Get or create Qdrant HTTP client."""
    global _qdrant_client
    if _qdrant_client is None:
        _qdrant_client = httpx.AsyncClient(
            base_url=QDRANT_URL.rstrip('/'),
            timeout=30.0
        )
    return _qdrant_client

def get_ollama_client():
    """Get or create Ollama HTTP client."""
    global _ollama_client
    if _ollama_client is None:
        _ollama_client = httpx.AsyncClient(
            base_url=OLLAMA_URL.rstrip('/'),
            timeout=60.0
        )
    return _ollama_client

# Initialize MCP server
mcp = FastMCP("qdrant-mcp")


async def generate_embedding(text: str) -> Optional[List[float]]:
    """Generate embedding using Ollama."""
    try:
        client = get_ollama_client()
        response = await client.post(
            "/api/embeddings",
            json={
                "model": EMBEDDING_MODEL,
                "prompt": text
            }
        )
        if response.status_code == 200:
            data = response.json()
            return data.get("embedding")
        else:
            logger.error(f"Failed to generate embedding: {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
        return None


async def ensure_collection(collection_name: str, vector_size: int = 768):
    """Ensure Qdrant collection exists."""
    try:
        client = get_qdrant_client()
        # Check if collection exists
        response = await client.get(f"/collections/{collection_name}")
        if response.status_code == 200:
            logger.info(f"Collection '{collection_name}' exists")
            return True
    except httpx.HTTPError:
        pass
    
        # Create collection
    try:
        client = get_qdrant_client()
        collection_config = {
            "vectors": {
                "size": vector_size,
                "distance": "Cosine"
            }
        }
        response = await client.put(
            f"/collections/{collection_name}",
            json=collection_config
        )
        if response.status_code in (200, 201):
            logger.info(f"Created collection '{collection_name}'")
            return True
        else:
            logger.error(f"Failed to create collection: {response.status_code}")
            return False
    except Exception as e:
        logger.error(f"Error creating collection: {e}")
        return False


@mcp.tool()
async def qdrant_search(
    query: str,
    collection: str = DEFAULT_COLLECTION,
    limit: int = 5,
    score_threshold: float = 0.7
) -> str:
    """Search Qdrant vector database for semantically similar content. Returns relevant context with source file information.
    
    Args:
        query: Search query text
        collection: Collection name (default: atlas_conversations)
        limit: Maximum number of results (default: 5, max: 20)
        score_threshold: Minimum similarity score 0-1 (default: 0.7)
    """
    # Generate embedding
    embedding = await generate_embedding(query)
    if not embedding:
        return "Error: Failed to generate embedding"
    
    # Ensure collection exists
    await ensure_collection(collection, len(embedding))
    
        # Search Qdrant
    try:
        client = get_qdrant_client()
        search_payload = {
            "vector": embedding,
            "limit": limit,
            "score_threshold": score_threshold,
            "with_payload": True,
            "with_vector": False
        }
        
        response = await client.post(
            f"/collections/{collection}/points/search",
            json=search_payload
        )
        
        if response.status_code == 200:
            data = response.json()
            results = []
            
            for result in data.get("result", []):
                payload = result.get("payload", {})
                score = result.get("score", 0.0)
                text = payload.get("text", "")
                source_file = payload.get("source_file", "unknown")
                source_type = payload.get("source_type", "unknown")
                
                results.append({
                    "text": text,
                    "source_file": source_file,
                    "source_type": source_type,
                    "score": score,
                    "metadata": {k: v for k, v in payload.items() 
                               if k not in ["text", "source_file", "source_type"]}
                })
            
            result_text = f"Found {len(results)} results:\n\n"
            for i, r in enumerate(results, 1):
                result_text += f"{i}. Score: {r['score']:.3f}\n"
                result_text += f"   Source: {r['source_file']} ({r['source_type']})\n"
                result_text += f"   Text: {r['text'][:200]}...\n\n"
            
            return result_text
        else:
            return f"Error: Search failed with status {response.status_code}: {response.text}"
    except Exception as e:
        logger.error(f"Search error: {e}")
        return f"Error: {str(e)}"


@mcp.tool()
async def qdrant_index(
    text: str,
    source_file: Optional[str] = None,
    source_type: str = "conversation",
    collection: str = DEFAULT_COLLECTION,
    metadata: Optional[Dict[str, Any]] = None
) -> str:
    """Index text in Qdrant vector database with metadata. Links vectors to source files for verification.
    
    Args:
        text: Text to index
        source_file: Path to source file (for linking)
        source_type: Source type (e.g., 'conversation', 'seafile', 'immich')
        collection: Collection name (default: atlas_conversations)
        metadata: Additional metadata (JSON object)
    """
    metadata = metadata or {}
    
    # Generate embedding
    embedding = await generate_embedding(text)
    if not embedding:
        return "Error: Failed to generate embedding"
    
    # Ensure collection exists
    await ensure_collection(collection, len(embedding))
    
    # Prepare payload
    payload = {
        "text": text,
        "source_type": source_type,
        **metadata
    }
    if source_file:
        payload["source_file"] = source_file
    
    # Index in Qdrant
    try:
        import uuid
        point_id = str(uuid.uuid4())  # Generate UUID for point
        
        point = {
            "id": point_id,
            "vector": embedding,
            "payload": payload
        }
        
        upsert_payload = {
            "points": [point]
        }
        
        client = get_qdrant_client()
        response = await client.put(
            f"/collections/{collection}/points",
            json=upsert_payload
        )
        
        if response.status_code in (200, 201):
            return f"Successfully indexed text in collection '{collection}'\nSource: {source_file or 'none'}\nLength: {len(text)} characters"
        else:
            return f"Error: Indexing failed with status {response.status_code}: {response.text}"
    except Exception as e:
        logger.error(f"Indexing error: {e}")
        return f"Error: {str(e)}"


@mcp.tool()
async def qdrant_health() -> str:
    """Check Qdrant server health and connection status."""
    try:
        # Use root endpoint which returns version info
        client = get_qdrant_client()
        response = await client.get("/")
        if response.status_code == 200:
            health_data = response.json()
            version = health_data.get('version', 'unknown')
            return f"Qdrant is healthy\nVersion: {version}\nURL: {QDRANT_URL}\nOllama: {OLLAMA_URL}\nEmbedding Model: {EMBEDDING_MODEL}"
        else:
            return f"Qdrant health check failed: {response.status_code}"
    except Exception as e:
        return f"Error connecting to Qdrant: {str(e)}"


@mcp.tool()
async def qdrant_list_collections() -> str:
    """List all collections in Qdrant."""
    try:
        client = get_qdrant_client()
        response = await client.get("/collections")
        if response.status_code == 200:
            data = response.json()
            collections = data.get("result", {}).get("collections", [])
            if collections:
                result_text = f"Found {len(collections)} collections:\n\n"
                for col in collections:
                    result_text += f"- {col.get('name', 'unknown')}\n"
            else:
                result_text = "No collections found"
            
            return result_text
        else:
            return f"Error: {response.status_code} {response.text}"
    except Exception as e:
        return f"Error: {str(e)}"


@mcp.tool()
async def qdrant_get_collection_info(collection: str = DEFAULT_COLLECTION) -> str:
    """Get information about a specific collection.
    
    Args:
        collection: Collection name (default: atlas_conversations)
    """
    try:
        client = get_qdrant_client()
        response = await client.get(f"/collections/{collection}")
        if response.status_code == 200:
            data = response.json()
            result = data.get("result", {})
            info_text = f"Collection: {collection}\n"
            info_text += f"Vectors count: {result.get('points_count', 0)}\n"
            info_text += f"Vector size: {result.get('config', {}).get('params', {}).get('vectors', {}).get('size', 'unknown')}\n"
            info_text += f"Distance: {result.get('config', {}).get('params', {}).get('vectors', {}).get('distance', 'unknown')}"
            
            return info_text
        else:
            return f"Error: Collection not found or error: {response.status_code}"
    except Exception as e:
        return f"Error: {str(e)}"


if __name__ == "__main__":
    logger.info(f"Starting Qdrant MCP Server")
    logger.info(f"Qdrant URL: {QDRANT_URL}")
    logger.info(f"Ollama URL: {OLLAMA_URL}")
    logger.info(f"Embedding Model: {EMBEDDING_MODEL}")
    
    # Test connections
    async def test_connections():
        try:
            qdrant_client = get_qdrant_client()
            health_response = await qdrant_client.get("/")
            if health_response.status_code == 200:
                version = health_response.json().get('version', 'unknown')
                logger.info(f"✓ Qdrant connection successful (version {version})")
            else:
                logger.warning(f"Qdrant check returned {health_response.status_code}")
        except Exception as e:
            logger.error(f"Failed to connect to Qdrant: {e}")
    
    asyncio.run(test_connections())
    
    # Run MCP server
    mcp.run()
