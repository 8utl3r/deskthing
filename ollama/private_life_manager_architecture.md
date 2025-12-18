# Private Life Manager Architecture

## Summary

We have defined a complete architecture for a local, private AI assistant tailored to minimize cognitive load and run efficiently on your specific hardware.

## 1. The Hardware Reality

**Device**: MacBook Pro M3 (18GB Unified Memory)

**Constraint**: You are in the "awkward middle ground" of local AI.

- **8B Models (Llama 3)**: Too small. They run fast but lack the deep reasoning to manage a complex human life without "forgetting" details.
- **70B Models**: Impossible. They require ~40GB+ RAM.
- **The Solution**: We targeted the 12B–14B parameter class, which utilizes ~9-11GB of your RAM, leaving sufficient overhead for your OS and browser.

## 2. The Chosen Model: Mistral Nemo 12B

We selected Mistral Nemo 12B over Llama 3 (8B) and Qwen 2.5 (14B).

**Why it won**:

- **Context Window**: It natively supports 128k context. This allows it to hold weeks of schedule data or long documents in "memory" without hallucinating, unlike Llama 3 which degrades rapidly after 8k.
- **Efficiency**: It uses the Tekken tokenizer, which is more efficient at compressing text and code, effectively making it "smarter" per gigabyte of RAM than competitors.
- **Stability**: Unlike Qwen 14B, which would force you to close background apps to prevent swapping, Nemo leaves you ~7GB of breathing room.

## 3. The Specific Variant: Dolphin-Mistral-Nemo

We refined the choice to the Dolphin fine-tune (specifically Dolphin-2.9.3-Mistral-Nemo).

**Why this flavor**:

- **Alignment**: You require a "direct, factual, and minimally polite" assistant. Standard models are trained to be overly apologetic and chatty. Dolphin has these "safety" and "politeness" layers abliterated.
- **Behavior**: It executes commands immediately without moralizing or conversational filler, directly reducing the friction (and cognitive load) of interacting with it.

## 4. The Configuration Strategy

We moved beyond the default ollama run command to a custom "Power User" setup to maximize performance.

- **Installation**: Download the GGUF manually (Quantization: Q5_K_M or Q6_K) to ensure exact RAM usage control.
- **The Modelfile**:
  - `num_ctx 32768`: Explicitly setting memory to ~32k tokens to leverage the model's retention capabilities.
  - `temperature 0.2`: Lowering randomness to ensure the assistant is a reliable scheduler rather than a creative writer.
  - **System Prompt**: Hard-coding your specific persona (ADHD accommodations, brevity requirements) so you never have to repeat them.
- **System Environment**:
  - `OLLAMA_KV_CACHE_TYPE=q8_0`: Compressing the "memory" cache to fit more context into your 18GB RAM.
  - `OLLAMA_KEEP_ALIVE=24h`: Keeping the model loaded to ensure instant, zero-latency responses.

## The Final Path

You are building a Dolphin-Mistral-Nemo 12B agent, manually quantized to Q6_K, running with a 32k context window via a custom Modelfile. This creates a private assistant that is smart enough to plan your life, fast enough to reply instantly, and direct enough to never annoy you.

## Next Step

Would you like me to generate the final, copy-pasteable Modelfile and the exact terminal commands to download and install this specific configuration?

