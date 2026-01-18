# n8n MCP Prompt Template

This is a template for creating an n8n MCP prompt, based on the structure and style of the GDAI MCP prompt.

## Prompt Content

# Important information and best practices for working with n8n workflows using MCP

Use the `search_workflows` tool to discover existing workflows and understand the project structure.

1. **n8n Workflow System Guide**
   - Workflows in n8n are JSON files that define automation pipelines
   - Workflows consist of nodes (processing units) connected by edges (data flow)
   - Each workflow has a unique ID and can be active (published) or inactive (draft)
   - Use the `search_workflows` tool to find workflows by name, description, or other criteria
   - Use the `get_workflow_details` tool to get complete information about a specific workflow including its trigger configuration

2. **Workflow Management**
   - ALWAYS use the Cursor API Bridge workflow (`cursor-workflow-api`) to create, update, or delete workflows programmatically
   - The API Bridge is accessible via webhook at `http://localhost:5678/webhook/cursor-workflow-api`
   - When creating workflows via the API Bridge:
     - Use the `operation: "create"` field in the request body
     - Include `name`, `nodes`, `connections`, and `settings` fields
     - DO NOT include `active` field during creation (it's read-only)
     - DO NOT include `id`, `versionId`, `createdAt`, `updatedAt` fields (they're auto-generated)
   - When updating workflows via the API Bridge:
     - Use the `operation: "update"` field
     - Include `workflowId` to identify the workflow
     - Include the full workflow structure (nodes, connections, settings)
     - You CAN set `active: true` to publish the workflow
   - When deleting workflows via the API Bridge:
     - Use the `operation: "delete"` field
     - Include `workflowId` to identify the workflow

3. **Workflow Structure**
   - **Nodes**: Array of node objects, each with:
     - `id`: Unique identifier (string)
     - `name`: Human-readable name
     - `type`: Node type (e.g., `n8n-nodes-base.webhook`, `n8n-nodes-base.httpRequest`)
     - `typeVersion`: Version of the node type
     - `position`: [x, y] coordinates for UI layout
     - `parameters`: Node-specific configuration
   - **Connections**: Object mapping node names to their output connections
     - Format: `{ "NodeName": { "main": [[{ "node": "TargetNode", "type": "main", "index": 0 }]] } }`
   - **Settings**: Workflow-level settings (optional)
   - **Webhook IDs**: For webhook nodes, include `webhookId` field to register the webhook path

4. **Node Types and Best Practices**
   - **Webhook Nodes**: Use for receiving HTTP requests
     - Set `responseMode: "responseNode"` to use a Respond to Webhook node
     - Use unique `path` values to avoid conflicts
     - Remember: Only ONE workflow can be active with a given webhook path at a time
   - **HTTP Request Nodes**: Use for calling external APIs
     - Set `continueOnFail: true` in options to prevent workflow failure on API errors
     - Use proper authentication headers (X-N8N-API-KEY for n8n's own API)
     - Handle errors gracefully with error output connections
   - **Set Nodes**: Use for data transformation
     - Pass data forward through the execution chain
     - Avoid cross-node references when possible (use `$json.field` instead of `$('NodeName').item.json.field`)
   - **If/Switch Nodes**: Use for conditional logic
     - Use Switch nodes for multiple conditions (prevents false errors from non-matching branches)
     - Use If nodes for simple true/false conditions
   - **Respond to Webhook Nodes**: Use to send responses back to webhook callers
     - Always connect these to webhook nodes with `responseMode: "responseNode"`

5. **Error Handling**
   - ALWAYS add `continueOnFail: true` to HTTP Request nodes that call external APIs
   - Use error output connections on nodes that support them
   - Provide fallback values in expressions when accessing data that might not exist
   - Use optional chaining or conditional checks: `$json.field || "default"` or `$json.field?.subfield`

6. **Data Flow Best Practices**
   - Pass data forward through the execution chain rather than referencing nodes from parallel branches
   - When a node needs data from a previous node, include that data in the current node's output
   - Use `$json.field` to access data from the current execution item
   - Use `$('NodeName').item.json.field` sparingly and only when necessary
   - For webhook workflows, access input data via `$json.body.field`

7. **Workflow Activation**
   - Workflows must be activated (published) to receive webhook requests
   - Only one workflow can be active with a given webhook path
   - To activate a workflow, use the update operation with `active: true`
   - Before activating, check if another workflow uses the same webhook path
   - Test workflows using `/webhook-test/` endpoint before activating

8. **Common Patterns**
   - **API Bridge Pattern**: Use the Cursor API Bridge workflow to manage workflows programmatically
   - **Error Handling Pattern**: Always include error output connections and fallback values
   - **Data Passing Pattern**: Pass all needed data forward through Set nodes rather than cross-referencing
   - **Webhook Pattern**: Use webhook → process → respond structure for HTTP-triggered workflows

9. **Troubleshooting**
   - If a workflow creates duplicates, check for multiple active workflows with the same webhook path
   - If webhook returns 404, ensure the workflow is activated or execute it once in test mode
   - If nodes fail, check for missing data dependencies or API errors
   - If expressions return null, verify data is being passed forward through the chain

10. **Workflow Naming and Organization**
    - Use descriptive names with version suffixes (e.g., "My Workflow v1", "My Workflow v2")
    - Keep workflow JSON files organized in a `workflows/` directory
    - Document workflow purpose and usage in README files
    - Use consistent naming conventions across related workflows

**General n8n Practices**
- Always check existing workflows before creating new ones to avoid duplication
- Use the search functionality to understand the project's workflow structure
- Test workflows in test mode before activating them
- Document complex workflows with comments or README files
- Keep workflows focused on a single purpose when possible
- Use the API Bridge for programmatic workflow management rather than manual creation

