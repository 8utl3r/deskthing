# LLM Instruction Analysis

## Current State

### What We Provide ✅

1. **Priority order** - Clear 1, 2, 3 priorities
2. **Action list** - Available actions with examples
3. **Response format** - JSON format requirement
4. **Context detection** - Enemies, blueprints, resources highlighted
5. **Position information** - Entity positions provided

### What's Missing ❌

1. **Factorio game knowledge** - What Factorio is, what entities do
2. **Entity name understanding** - How to extract entity names from ghosts
3. **Resource knowledge** - What resources exist, what they're used for
4. **Recipe knowledge** - What recipes are available, what they make
5. **Action semantics** - What actually happens when actions execute
6. **Async understanding** - That some actions take time
7. **State interpretation** - How to read the state data structure
8. **Error handling** - What to do if actions fail
9. **Coordinate system** - How coordinates work in Factorio
10. **Game mechanics** - How mining, crafting, building actually work

## Recommended Enhancements

### 1. Comprehensive System Prompt

Add to system prompt:
- Factorio game context (what the game is about)
- Common entities and what they do
- Common resources and their uses
- Common recipes
- Coordinate system explanation
- Action semantics (what each action does)

### 2. Enhanced Context Messages

Add to each query:
- Explanation of how to read the state data
- How to extract entity names from ghost entities
- What the position coordinates mean
- Examples of interpreting reachable entities

### 3. Action Examples

Provide more detailed examples:
- How to extract "assembling-machine-1" from "entity-ghost-assembling-machine-1"
- How to use coordinates from detected entities
- How to interpret entity data structure

### 4. Error Recovery

Add instructions for:
- What to do if action fails
- How to retry actions
- How to handle invalid positions

## Updated System Prompt (Recommended)

See `llm_system_prompt.md` for the comprehensive version that includes:
- Full Factorio game context
- Entity and resource knowledge
- Recipe system explanation
- Action semantics
- Coordinate system
- State interpretation guide
- Error handling

This will give the LLM much better understanding of:
- What it's doing (Factorio game context)
- What entities/resources exist
- How to interpret the game state
- How to make better decisions
