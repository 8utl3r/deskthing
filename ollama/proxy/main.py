"""Entry point for Atlas HTTP Proxy Server.

Starts the FastAPI server using uvicorn.
"""

import uvicorn
import logging
from components.config import Config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Start the Atlas proxy server."""
    config = Config()
    
    logger.info(f"Starting Atlas Proxy Server on port {config.proxy_port}")
    logger.info(f"Ollama URL: {config.ollama_url}")
    logger.info(f"Data directory: {config.data_dir}")
    
    uvicorn.run(
        "atlas_proxy:app",
        host="0.0.0.0",
        port=config.proxy_port,
        reload=False,  # Set to True for development
        log_level="info"
    )


if __name__ == "__main__":
    main()




