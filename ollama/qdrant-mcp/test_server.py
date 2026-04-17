#!/usr/bin/env python3
"""Quick test script for Qdrant MCP Server"""

import asyncio
import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(__file__))

from qdrant_mcp_server import (
    get_qdrant_client,
    get_ollama_client,
    generate_embedding,
    ensure_collection,
    DEFAULT_COLLECTION
)


async def test_all():
    """Test all Qdrant MCP server functionality."""
    print("🧪 Testing Qdrant MCP Server...\n")
    
    # Test 1: Qdrant connection
    print("1. Testing Qdrant connection...")
    try:
        qdrant_client = get_qdrant_client()
        response = await qdrant_client.get("/")
        if response.status_code == 200:
            version = response.json().get('version', 'unknown')
            print(f"   ✓ Qdrant connected (version {version})")
        else:
            print(f"   ✗ Qdrant returned {response.status_code}")
            return False
    except Exception as e:
        print(f"   ✗ Qdrant connection failed: {e}")
        return False
    
    # Test 2: Ollama embedding
    print("2. Testing Ollama embedding generation...")
    try:
        embedding = await generate_embedding("test query")
        if embedding and len(embedding) > 0:
            print(f"   ✓ Embedding generated ({len(embedding)} dimensions)")
        else:
            print("   ✗ Failed to generate embedding")
            return False
    except Exception as e:
        print(f"   ✗ Embedding generation failed: {e}")
        return False
    
    # Test 3: Collection creation
    print("3. Testing collection creation...")
    try:
        result = await ensure_collection(DEFAULT_COLLECTION, len(embedding))
        if result:
            print(f"   ✓ Collection '{DEFAULT_COLLECTION}' ready")
        else:
            print(f"   ✗ Failed to create collection")
            return False
    except Exception as e:
        print(f"   ✗ Collection creation failed: {e}")
        return False
    
    # Test 4: Index a test document
    print("4. Testing document indexing...")
    try:
        import uuid
        test_text = "This is a test document for Qdrant MCP server."
        test_metadata = {
            "text": test_text,
            "source_file": "/test/path.txt",
            "source_type": "test"
        }
        
        payload = {
            "id": str(uuid.uuid4()),
            "vector": embedding,
            "payload": test_metadata
        }
        
        qdrant_client = get_qdrant_client()
        response = await qdrant_client.put(
            f"/collections/{DEFAULT_COLLECTION}/points",
            json={"points": [payload]}
        )
        
        if response.status_code in (200, 201):
            print("   ✓ Test document indexed")
        else:
            print(f"   ✗ Indexing failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Indexing failed: {e}")
        return False
    
    # Test 5: Search
    print("5. Testing vector search...")
    try:
        search_payload = {
            "vector": embedding,
            "limit": 1,
            "with_payload": True
        }
        
        qdrant_client = get_qdrant_client()
        response = await qdrant_client.post(
            f"/collections/{DEFAULT_COLLECTION}/points/search",
            json=search_payload
        )
        
        if response.status_code == 200:
            results = response.json().get("result", [])
            print(f"   ✓ Search successful (found {len(results)} results)")
        else:
            print(f"   ✗ Search failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ✗ Search failed: {e}")
        return False
    
    print("\n✅ All tests passed! Qdrant MCP server is ready.")
    return True


if __name__ == "__main__":
    try:
        success = asyncio.run(test_all())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted")
        sys.exit(1)
    finally:
        # Close clients if they exist
        qdrant_client = get_qdrant_client()
        ollama_client = get_ollama_client()
        try:
            await qdrant_client.aclose()
            await ollama_client.aclose()
        except:
            pass
