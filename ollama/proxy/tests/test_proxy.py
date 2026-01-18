"""Tests for Atlas HTTP Proxy Server."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
import json

from atlas_proxy import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


def test_health_endpoint(client):
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "atlas-proxy"


@pytest.mark.asyncio
async def test_chat_endpoint_basic(client):
    """Test /api/chat endpoint with mocked Ollama."""
    # Mock Ollama response
    mock_ollama_response = {
        "model": "atlas",
        "message": {
            "role": "assistant",
            "content": "Hello! This is a test response."
        },
        "done": True
    }
    
    with patch("atlas_proxy.ollama_client.post") as mock_post:
        # Setup mock
        mock_response = AsyncMock()
        mock_response.json.return_value = mock_ollama_response
        mock_response.raise_for_status = MagicMock()
        mock_post.return_value = mock_response
        
        # Make request
        request_data = {
            "model": "atlas",
            "messages": [
                {"role": "user", "content": "Hello"}
            ],
            "stream": False
        }
        
        response = client.post("/api/chat", json=request_data)
        
        # Verify response
        assert response.status_code == 200
        data = response.json()
        assert "message" in data or "response" in data
        assert "atlas_metadata" in data


@pytest.mark.asyncio
async def test_chat_endpoint_with_commands(client):
    """Test /api/chat endpoint with FILE commands in response."""
    # Mock Ollama response with FILE command
    mock_ollama_response = {
        "model": "atlas",
        "message": {
            "role": "assistant",
            "content": "I'll create that file for you.\n**FILE_CREATE** test.txt \"Hello World\"\nDone!"
        },
        "done": True
    }
    
    with patch("atlas_proxy.ollama_client.post") as mock_post, \
         patch("atlas_proxy.file_ops.create_file") as mock_create:
        
        # Setup mocks
        mock_response = AsyncMock()
        mock_response.json.return_value = mock_ollama_response
        mock_response.raise_for_status = MagicMock()
        mock_post.return_value = mock_response
        
        mock_create.return_value = {
            "success": True,
            "message": "File created successfully"
        }
        
        # Make request
        request_data = {
            "model": "atlas",
            "messages": [
                {"role": "user", "content": "Create a file test.txt with Hello World"}
            ],
            "stream": False
        }
        
        response = client.post("/api/chat", json=request_data)
        
        # Verify response
        assert response.status_code == 200
        data = response.json()
        assert "atlas_metadata" in data
        assert data["atlas_metadata"]["commands_executed"] > 0
        
        # Verify file command was executed
        mock_create.assert_called_once()


@pytest.mark.asyncio
async def test_chat_endpoint_with_variables(client):
    """Test /api/chat endpoint with variable assignments."""
    # Mock Ollama response with variable assignment
    mock_ollama_response = {
        "model": "atlas",
        "message": {
            "role": "assistant",
            "content": "I'll remember that. x = 10"
        },
        "done": True
    }
    
    with patch("atlas_proxy.ollama_client.post") as mock_post, \
         patch("atlas_proxy.variable_manager.save_variables") as mock_save, \
         patch("atlas_proxy.variable_manager.load_variables") as mock_load:
        
        # Setup mocks
        mock_response = AsyncMock()
        mock_response.json.return_value = mock_ollama_response
        mock_response.raise_for_status = MagicMock()
        mock_post.return_value = mock_response
        
        mock_load.return_value = {}
        
        # Make request
        request_data = {
            "model": "atlas",
            "messages": [
                {"role": "user", "content": "Remember x is 10"}
            ],
            "stream": False
        }
        
        response = client.post("/api/chat", json=request_data)
        
        # Verify response
        assert response.status_code == 200
        
        # Verify variables were saved
        mock_save.assert_called()


def test_chat_endpoint_missing_messages(client):
    """Test /api/chat endpoint with missing messages."""
    request_data = {
        "model": "atlas",
        "messages": [],
        "stream": False
    }
    
    response = client.post("/api/chat", json=request_data)
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_proxy_to_ollama(client):
    """Test proxying other routes to Ollama."""
    mock_ollama_response = {
        "models": [
            {"name": "atlas", "size": 1000000}
        ]
    }
    
    with patch("atlas_proxy.ollama_client.request") as mock_request:
        # Setup mock
        mock_response = AsyncMock()
        mock_response.json.return_value = mock_ollama_response
        mock_response.status_code = 200
        mock_response.headers = {"content-type": "application/json"}
        mock_request.return_value = mock_response
        
        # Make request
        response = client.get("/api/tags")
        
        # Verify proxy was called
        mock_request.assert_called()
        assert response.status_code == 200


def test_cors_headers(client):
    """Test CORS headers are present."""
    response = client.options("/api/chat", headers={"Origin": "http://localhost:3000"})
    # CORS middleware should handle OPTIONS requests
    assert response.status_code in [200, 204]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])




