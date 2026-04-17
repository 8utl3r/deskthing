"""RAG Manager for Qdrant vector database integration.

Handles:
- Generating embeddings via Ollama
- Storing vectors in Qdrant
- Searching for relevant context
- Linking vectors to source files
"""

import logging
import httpx
from typing import List, Dict, Any, Optional
import json

logger = logging.getLogger(__name__)


class RAGManager:
    """Manages RAG operations with Qdrant vector database."""

    def __init__(
        self,
        qdrant_url: str,
        ollama_url: str,
        collection_name: str = "atlas_conversations",
        embedding_model: str = "nomic-embed-text"
    ):
        """Initialize RAG Manager.
        
        Args:
            qdrant_url: Qdrant API URL (e.g., "http://192.168.0.158:6333")
            ollama_url: Ollama API URL (e.g., "http://localhost:11434")
            collection_name: Qdrant collection name
            embedding_model: Ollama embedding model name
        """
        self.qdrant_url = qdrant_url.rstrip('/')
        self.ollama_url = ollama_url.rstrip('/')
        self.collection_name = collection_name
        self.embedding_model = embedding_model
        
        # Create HTTP clients
        self.qdrant_client = httpx.AsyncClient(
            base_url=self.qdrant_url,
            timeout=30.0
        )
        self.ollama_client = httpx.AsyncClient(
            base_url=self.ollama_url,
            timeout=60.0
        )
        
        # Ensure collection exists
        self._collection_initialized = False

    async def _ensure_collection(self):
        """Ensure Qdrant collection exists."""
        if self._collection_initialized:
            return
            
        try:
            # Check if collection exists
            response = await self.qdrant_client.get(
                f"/collections/{self.collection_name}"
            )
            if response.status_code == 200:
                logger.info(f"Collection '{self.collection_name}' already exists")
                self._collection_initialized = True
                return
        except httpx.HTTPError:
            pass
        
        # Create collection if it doesn't exist
        try:
            collection_config = {
                "vectors": {
                    "size": 768,  # nomic-embed-text produces 768-dim vectors
                    "distance": "Cosine"
                }
            }
            
            response = await self.qdrant_client.put(
                f"/collections/{self.collection_name}",
                json=collection_config
            )
            
            if response.status_code in (200, 201):
                logger.info(f"Created collection '{self.collection_name}'")
                self._collection_initialized = True
            else:
                logger.error(f"Failed to create collection: {response.status_code} {response.text}")
        except Exception as e:
            logger.error(f"Error ensuring collection: {e}")

    async def generate_embedding(self, text: str) -> Optional[List[float]]:
        """Generate embedding for text using Ollama.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector or None if failed
        """
        try:
            response = await self.ollama_client.post(
                "/api/embeddings",
                json={
                    "model": self.embedding_model,
                    "prompt": text
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("embedding")
            else:
                logger.error(f"Failed to generate embedding: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return None

    async def search(
        self,
        query: str,
        limit: int = 5,
        score_threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """Search for relevant context in Qdrant.
        
        Args:
            query: Search query text
            limit: Maximum number of results
            score_threshold: Minimum similarity score (0-1)
            
        Returns:
            List of relevant context items with metadata
        """
        await self._ensure_collection()
        
        # Generate embedding for query
        embedding = await self.generate_embedding(query)
        if not embedding:
            logger.warning("Failed to generate embedding for search")
            return []
        
        try:
            # Search Qdrant
            search_payload = {
                "vector": embedding,
                "limit": limit,
                "score_threshold": score_threshold,
                "with_payload": True,
                "with_vector": False
            }
            
            response = await self.qdrant_client.post(
                f"/collections/{self.collection_name}/points/search",
                json=search_payload
            )
            
            if response.status_code == 200:
                data = response.json()
                results = []
                
                for result in data.get("result", []):
                    payload = result.get("payload", {})
                    results.append({
                        "text": payload.get("text", ""),
                        "source_file": payload.get("source_file"),
                        "source_type": payload.get("source_type"),
                        "metadata": payload.get("metadata", {}),
                        "score": result.get("score", 0.0)
                    })
                
                logger.info(f"Found {len(results)} relevant results for query")
                return results
            else:
                logger.error(f"Search failed: {response.status_code} {response.text}")
                return []
        except Exception as e:
            logger.error(f"Error searching Qdrant: {e}")
            return []

    async def index(
        self,
        text: str,
        metadata: Dict[str, Any],
        point_id: Optional[int] = None
    ) -> bool:
        """Index text in Qdrant.
        
        Args:
            text: Text to index
            metadata: Metadata including source_file, source_type, etc.
            point_id: Optional point ID (auto-generated if None)
            
        Returns:
            True if successful, False otherwise
        """
        await self._ensure_collection()
        
        # Generate embedding
        embedding = await self.generate_embedding(text)
        if not embedding:
            logger.warning("Failed to generate embedding for indexing")
            return False
        
        try:
            # Prepare payload
            payload = {
                "text": text,
                **metadata
            }
            
            point = {
                "vector": embedding,
                "payload": payload
            }
            
            if point_id is not None:
                point["id"] = point_id
            
            # Upsert point
            upsert_payload = {
                "points": [point]
            }
            
            response = await self.qdrant_client.put(
                f"/collections/{self.collection_name}/points",
                json=upsert_payload
            )
            
            if response.status_code in (200, 201):
                logger.info(f"Indexed text with metadata: {metadata.get('source_file', 'unknown')}")
                return True
            else:
                logger.error(f"Indexing failed: {response.status_code} {response.text}")
                return False
        except Exception as e:
            logger.error(f"Error indexing in Qdrant: {e}")
            return False

    async def health_check(self) -> bool:
        """Check if Qdrant is accessible.
        
        Returns:
            True if Qdrant is healthy, False otherwise
        """
        try:
            response = await self.qdrant_client.get("/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Qdrant health check failed: {e}")
            return False

    async def close(self):
        """Close HTTP clients."""
        await self.qdrant_client.aclose()
        await self.ollama_client.aclose()
