# AI-Research-Skills Marketplace Analysis

**Date**: 2026-02-08
**Repository**: [Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-research-SKILLs)
**Install**: `npx @orchestra-research/ai-research-skills`

## Summary

83 production-ready skills across 20 categories for ML/AI research automation. MIT licensed, 2.5k GitHub stars. Focused on the full AI research lifecycle: model architecture, training, optimization, interpretability, evaluation, inference, safety, and deployment.

## Scale

| Category | Skills | Key Tools |
|----------|--------|-----------|
| Model Architecture | 5 | LitGPT, Mamba, RWKV, NanoGPT, TorchTitan |
| Tokenization | 2 | HuggingFace Tokenizers, SentencePiece |
| Fine-Tuning | 4 | Axolotl, LLaMA-Factory, PEFT, Unsloth |
| Mechanistic Interpretability | 4 | TransformerLens, SAELens, pyvene, nnsight |
| Data Processing | 2 | Ray Data, NeMo Curator |
| Post-Training | 8 | TRL, GRPO, OpenRLHF, SimPO, verl, slime, miles, torchforge |
| Safety & Alignment | 4 | Constitutional AI, LlamaGuard, NeMo Guardrails, Prompt Guard |
| Distributed Training | 6 | Megatron-Core, DeepSpeed, FSDP2, Accelerate, Lightning, Ray Train |
| Infrastructure | 3 | Modal, SkyPilot, Lambda Labs |
| Optimization | 6 | Flash Attention, bitsandbytes, GPTQ, AWQ, HQQ, GGUF |
| Evaluation | 3 | lm-eval-harness, BigCode, NeMo Evaluator |
| Inference & Serving | 4 | vLLM, TensorRT-LLM, llama.cpp, SGLang |
| MLOps | 3 | W&B, MLflow, TensorBoard |
| Agents | 4 | LangChain, LlamaIndex, CrewAI, AutoGPT |
| RAG | 5 | Chroma, FAISS, Sentence Transformers, Pinecone, Qdrant |
| Prompt Engineering | 4 | DSPy, Instructor, Guidance, Outlines |
| Observability | 2 | LangSmith, Phoenix |
| Multimodal | 7 | CLIP, Whisper, LLaVA, Stable Diffusion, SAM, BLIP-2, AudioCraft |
| Emerging Techniques | 6 | MoE, Model Merging, Long Context, Speculative Decoding, Distillation, Pruning |
| ML Paper Writing | 1 | LaTeX templates, citation verification |
| **Total** | **83** | |

## Top 5 for Autonomous AI Research

1. **vLLM** — Production inference engine, 2-3x memory reduction
2. **GRPO + TRL** — Post-training preference optimization without reward models
3. **Megatron-Core** — Distributed training (TP, PP, DP, EP, CP combinations)
4. **TransformerLens + SAELens** — Mechanistic interpretability, circuit analysis
5. **lm-eval-harness** — 100+ standardized evaluation benchmarks

## Relevance to Jarvis

**Current relevance**: LOW — These are GPU-heavy ML research skills requiring training infrastructure (Mac Studio, GPU cloud, or HPC). Not applicable to current laptop-based development.

**Future relevance**: HIGH — When Mac Studio or cloud GPU access is available:
- vLLM for local model serving
- lm-eval-harness for benchmark evaluation
- DSPy/Instructor for prompt optimization
- RAG skills (Chroma, FAISS) align with planned db-ops skill

## Actionable Extractions (Now)

1. **DSPy prompt optimization patterns** → Could enhance research-ops prompt templates
2. **Evaluation methodology from lm-eval-harness** → Research reporting patterns
3. **RAG skill patterns (Chroma)** → Directly relevant to P1 #8 (db-ops skill)

## Deferred (After Infrastructure)

- Full skill installation (`npx @orchestra-research/ai-research-skills`)
- Training pipeline integration (Megatron-Core, TRL)
- Interpretability workflows (TransformerLens)

---

*Analysis from background agent a97b5a6, 2026-02-08*
