"""Atlas HTTP Proxy Server.

FastAPI server that intercepts Ollama requests, injects context, forwards to Ollama,
parses responses, executes commands, updates variables, and logs conversations.
"""

import logging
import httpx
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from typing import Dict, Any, List, Optional
import json

from components.config import Config
from components.variable_manager import VariableManager
from components.context_injector import ContextInjector
from components.command_parser import CommandParser
from components.file_ops import FileOperationsManager
from components.conversation_logger import ConversationLogger

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Atlas Proxy", version="1.0.0")

# Initialize configuration
config = Config()

# Initialize components
variable_manager = VariableManager(config.data_dir)
context_injector = ContextInjector(
    config.files_dir,
    max_context_size=config.max_context_size,
    max_context_tokens=config.max_context_tokens,
    dynamic_context=config.dynamic_context
)
command_parser = CommandParser()
file_ops = FileOperationsManager(
    config.files_dir,
    allowed_extensions=config.allowed_extensions,
    max_size=config.max_file_size
)
conversation_logger = ConversationLogger(
    config.history_dir,
    retention_days=config.log_retention_days
)

# Create httpx client for Ollama requests
ollama_client = httpx.AsyncClient(
    base_url=config.ollama_url,
    timeout=60.0
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "atlas-proxy"}


@app.post("/api/chat")
async def chat_endpoint(request: Request):
    """Main chat endpoint that processes requests through Atlas pipeline.
    
    Flow:
    1. Load variables
    2. Load file context
    3. Format context
    4. Inject into messages
    5. Forward to Ollama
    6. Parse response
    7. Execute file commands
    8. Update variables
    9. Log conversation
    10. Return response
    """
    try:
        # Parse request body
        body = await request.json()
        messages = body.get("messages", [])
        model = body.get("model", "atlas")
        stream = body.get("stream", False)
        
        if not messages:
            raise HTTPException(status_code=400, detail="Messages are required")
        
        logger.info(f"Processing chat request with {len(messages)} messages")
        
        # Step 1: Load variables
        variables = variable_manager.load_variables()
        logger.debug(f"Loaded {len(variables)} variables")
        
        # Step 2: Load file context (keyword-based, only relevant files)
        file_context = context_injector.load_file_context(messages=messages)
        
        # Step 3: Format context (only includes relevant files that matched keywords)
        # Pass messages for dynamic context size calculation
        formatted_context = context_injector.format_context(file_context, variables, messages=messages)
        if formatted_context:
            logger.debug(f"Formatted context ({len(formatted_context)} chars) - keywords: {list(file_context.get('keywords', {}).keys())[:5]}")
        else:
            logger.debug("No context to inject (no keyword matches)")
        
        # Step 4: Inject context into messages
        enhanced_messages = context_injector.inject_into_messages(messages, formatted_context)
        
        # Step 5: Forward to Ollama
        ollama_request = {
            "model": model,
            "messages": enhanced_messages,
            "stream": stream
        }
        
        logger.info(f"Forwarding request to Ollama at {config.ollama_url}")
        
        if stream:
            # Handle streaming response
            async def generate():
                full_response_text = ""
                async with ollama_client.stream("POST", "/api/chat", json=ollama_request) as response:
                    response.raise_for_status()
                    async for chunk in response.aiter_text():
                        if chunk:
                            # Accumulate response text for post-processing
                            # Ollama SSE format: "data: {...}\n\n"
                            # Extract JSON from SSE format
                            for line in chunk.split('\n'):
                                if line.startswith('data: '):
                                    try:
                                        data = json.loads(line[6:])  # Remove "data: " prefix
                                        if 'message' in data and 'content' in data['message']:
                                            full_response_text += data['message']['content']
                                    except json.JSONDecodeError:
                                        pass
                            yield chunk
                    
                    # After streaming completes, process the full response
                    if full_response_text:
                        await _process_response(full_response_text, messages, variables)
            
            return StreamingResponse(generate(), media_type="text/event-stream")
        else:
            # Handle non-streaming response
            ollama_response = await ollama_client.post("/api/chat", json=ollama_request)
            ollama_response.raise_for_status()
            ollama_data = ollama_response.json()
            
            # Extract response text
            atlas_response_text = ""
            if "message" in ollama_data:
                atlas_response_text = ollama_data["message"].get("content", "")
            elif "response" in ollama_data:
                atlas_response_text = ollama_data["response"]
            
            # Step 6: Parse response
            parsed = command_parser.extract_commands(atlas_response_text)
            file_commands = parsed["file_commands"]
            variable_commands = parsed["variable_commands"]
            clean_response = parsed["clean_response"]
            
            # Step 7: Execute file commands
            commands_executed = []
            for cmd in file_commands:
                result = await _execute_file_command(cmd)
                commands_executed.append(result)
            
            # Step 8: Update variables
            variables_updated = {}
            for var_cmd in variable_commands:
                var_name = var_cmd.get("name")
                var_value = var_cmd.get("value")
                if var_name:
                    variables_updated[var_name] = var_value
            
            # Also parse variable updates from clean response
            var_updates_from_response = variable_manager.parse_updates(clean_response)
            variables_updated.update(var_updates_from_response)
            
            # Save updated variables
            if variables_updated:
                current_variables = variable_manager.load_variables()
                current_variables.update(variables_updated)
                # Preserve metadata if it exists
                if "_metadata" in variables:
                    current_variables["_metadata"] = variables["_metadata"]
                variable_manager.save_variables(current_variables)
                logger.info(f"Updated {len(variables_updated)} variables")
            
            # Step 9: Log conversation
            user_query = messages[-1].get("content", "") if messages else ""
            variables_used = list(variables.keys()) if variables else []
            conversation_logger.log_conversation(
                user_query=user_query,
                atlas_response=clean_response,
                commands_executed=commands_executed,
                variables_used=variables_used,
                variables_updated=variables_updated
            )
            
            # Step 10: Return response
            # Update the response with clean text (commands removed)
            response_data = ollama_data.copy()
            if "message" in response_data:
                response_data["message"]["content"] = clean_response
            elif "response" in response_data:
                response_data["response"] = clean_response
            
            # Add metadata about executed commands
            response_data["atlas_metadata"] = {
                "commands_executed": len(commands_executed),
                "variables_updated": len(variables_updated)
            }
            
            return response_data
            
    except httpx.HTTPError as e:
        logger.error(f"Error forwarding to Ollama: {e}")
        raise HTTPException(status_code=502, detail=f"Error communicating with Ollama: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error in chat endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


async def _execute_file_command(cmd: Dict[str, Any]) -> Dict[str, Any]:
    """Execute a file command and return result.
    
    Args:
        cmd: Command dictionary with type and parameters.
        
    Returns:
        Result dictionary with type, success, message, and command details.
    """
    cmd_type = cmd.get("type", "").upper()
    
    try:
        if cmd_type == "CREATE":
            result = file_ops.create_file(cmd.get("path", ""), cmd.get("content", ""))
            return {
                "type": "FILE_CREATE",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "READ":
            result = file_ops.read_file(cmd.get("path", ""))
            return {
                "type": "FILE_READ",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", ""),
                "content": result.get("content", "") if result.get("success") else None
            }
        elif cmd_type == "UPDATE":
            result = file_ops.update_file(cmd.get("path", ""), cmd.get("content", ""))
            return {
                "type": "FILE_UPDATE",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "APPEND":
            result = file_ops.append_file(cmd.get("path", ""), cmd.get("content", ""))
            return {
                "type": "FILE_APPEND",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "DELETE":
            result = file_ops.delete_file(cmd.get("path", ""))
            return {
                "type": "FILE_DELETE",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "MOVE":
            result = file_ops.move_file(cmd.get("old_path", ""), cmd.get("new_path", ""))
            return {
                "type": "FILE_MOVE",
                "old_path": cmd.get("old_path", ""),
                "new_path": cmd.get("new_path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "COPY":
            result = file_ops.copy_file(cmd.get("src_path", ""), cmd.get("dst_path", ""))
            return {
                "type": "FILE_COPY",
                "src_path": cmd.get("src_path", ""),
                "dst_path": cmd.get("dst_path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        elif cmd_type == "SEARCH":
            result = file_ops.search_files(cmd.get("directory", ""), cmd.get("term", ""))
            return {
                "type": "FILE_SEARCH",
                "directory": cmd.get("directory", ""),
                "term": cmd.get("term", ""),
                "success": result.get("success", False),
                "message": result.get("message", ""),
                "matches": result.get("matches", []) if result.get("success") else []
            }
        elif cmd_type == "LIST":
            result = file_ops.list_directory(cmd.get("directory", ""))
            return {
                "type": "FILE_LIST",
                "directory": cmd.get("directory", ""),
                "success": result.get("success", False),
                "message": result.get("message", ""),
                "files": result.get("files", []) if result.get("success") else [],
                "directories": result.get("directories", []) if result.get("success") else []
            }
        elif cmd_type == "ARCHIVE":
            result = file_ops.archive_file(cmd.get("path", ""))
            return {
                "type": "FILE_ARCHIVE",
                "path": cmd.get("path", ""),
                "success": result.get("success", False),
                "message": result.get("message", "")
            }
        else:
            logger.warning(f"Unknown command type: {cmd_type}")
            return {
                "type": cmd_type,
                "success": False,
                "message": f"Unknown command type: {cmd_type}"
            }
    except Exception as e:
        logger.error(f"Error executing command {cmd_type}: {e}", exc_info=True)
        return {
            "type": cmd_type,
            "success": False,
            "message": f"Error executing command: {str(e)}"
        }


async def _process_response(response_text: str, original_messages: List[Dict], variables: Dict[str, Any]):
    """Process response after streaming completes.
    
    This is called after streaming finishes to execute commands and update variables.
    """
    try:
        # Parse response
        parsed = command_parser.extract_commands(response_text)
        file_commands = parsed["file_commands"]
        variable_commands = parsed["variable_commands"]
        
        # Execute file commands
        for cmd in file_commands:
            await _execute_file_command(cmd)
        
        # Update variables
        variables_updated = {}
        for var_cmd in variable_commands:
            var_name = var_cmd.get("name")
            var_value = var_cmd.get("value")
            if var_name:
                variables_updated[var_name] = var_value
        
        var_updates_from_response = variable_manager.parse_updates(response_text)
        variables_updated.update(var_updates_from_response)
        
        if variables_updated:
            current_variables = variable_manager.load_variables()
            current_variables.update(variables_updated)
            if "_metadata" in variables:
                current_variables["_metadata"] = variables["_metadata"]
            variable_manager.save_variables(current_variables)
        
        # Log conversation
        user_query = original_messages[-1].get("content", "") if original_messages else ""
        variables_used = list(variables.keys()) if variables else []
        conversation_logger.log_conversation(
            user_query=user_query,
            atlas_response=parsed["clean_response"],
            commands_executed=[],  # Commands executed separately above
            variables_used=variables_used,
            variables_updated=variables_updated
        )
    except Exception as e:
        logger.error(f"Error processing streaming response: {e}", exc_info=True)


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def proxy_to_ollama(path: str, request: Request):
    """Proxy all other routes directly to Ollama."""
    try:
        # Get request body if present
        body = None
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.json()
            except:
                body = await request.body()
        
        # Get query parameters
        params = dict(request.query_params)
        
        # Forward request to Ollama
        url = f"/{path}"
        ollama_response = await ollama_client.request(
            method=request.method,
            url=url,
            json=body if isinstance(body, dict) else None,
            content=body if not isinstance(body, dict) else None,
            params=params,
            headers={k: v for k, v in request.headers.items() if k.lower() not in ["host", "content-length"]}
        )
        
        # Return response
        if ollama_response.headers.get("content-type", "").startswith("text/event-stream"):
            async def generate():
                async for chunk in ollama_response.aiter_bytes():
                    yield chunk
            return StreamingResponse(generate(), media_type="text/event-stream")
        else:
            return JSONResponse(
                content=ollama_response.json() if ollama_response.headers.get("content-type", "").startswith("application/json") else {"data": ollama_response.text},
                status_code=ollama_response.status_code,
                headers=dict(ollama_response.headers)
            )
    except httpx.HTTPError as e:
        logger.error(f"Error proxying to Ollama: {e}")
        raise HTTPException(status_code=502, detail=f"Error communicating with Ollama: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error proxying request: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown."""
    await ollama_client.aclose()
    logger.info("Atlas proxy server shutting down")

