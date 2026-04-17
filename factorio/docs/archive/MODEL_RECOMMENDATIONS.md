# Model Recommendations for Factorio NPCs

## Best Models for Quick Decisions

### 1. **mistral** (7B) - ⭐ RECOMMENDED
- **Size**: ~4.4 GB
- **Speed**: Fast (good balance)
- **JSON**: Excellent structured output support
- **Reasoning**: Good for complex instructions
- **Best for**: NPC decision-making with complex rules

### 2. **phi3:mini** (3.8B) - FASTEST
- **Size**: ~2.2 GB
- **Speed**: Very fast (smallest practical model)
- **JSON**: Good structured output
- **Reasoning**: Decent, but simpler than mistral
- **Best for**: When speed is critical, simpler decision trees

### 3. **qwen2.5:7b** (7B) - ALTERNATIVE
- **Size**: ~4.7 GB
- **Speed**: Fast
- **JSON**: Good structured output
- **Reasoning**: Excellent reasoning capabilities
- **Best for**: When you need better reasoning than mistral

## Current Recommendation

**Use `mistral`** - It's the best balance of:
- Speed (fast enough for 5-second decision cycles)
- Capability (handles complex instructions well)
- JSON output (reliable structured responses)
- Availability (widely used, well-tested)

## Switching Models

1. **Pull the model**:
   ```bash
   ollama pull mistral
   # or
   ollama pull phi3:mini
   ```

2. **Update config.py**:
   ```python
   OLLAMA_MODEL = "mistral"  # or "phi3:mini"
   ```

3. **Run the controller**:
   ```bash
   python factorio_ollama_npc_controller.py
   ```

## Speed Comparison

- **phi3:mini**: ~0.5-1 second per decision
- **mistral**: ~1-2 seconds per decision
- **atlas**: ~5-10+ seconds per decision (too slow)

For 5-second decision cycles, both phi3:mini and mistral work well. Mistral is recommended for better instruction following.
