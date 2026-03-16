# CLAUDE.md

## Project Overview

This is a **documentation-only PoC repository** (Proof of Concept) for running local LLMs
for software development in a corporate environment (SI). No application code -- only
documentation, scripts, and configuration.

**Goal:** Prove that AI-assisted development is possible fully offline, with no data
leaving the device, using only open-source tools (Apache 2.0 / MIT).

**Target audience:** Michael, Oliver, and other stakeholders evaluating this approach
alongside Gemini CLI rollout.

## Repository Structure

```
README.md                    -- Main overview, quick start, strategic context
docs/
  ollama.md                  -- Ollama local model server (MIT)
  qwen-models.md             -- Qwen model family, sizing, quantization (Apache 2.0)
  cline.md                   -- Cline VS Code extension (Apache 2.0)
  aider.md                   -- Aider terminal assistant (Apache 2.0)
  lancedb-embeddings.md      -- LanceDB + nomic-embed-text for RAG (Apache 2.0)
  data-privacy-proof.md      -- 6 methods to prove no data leaves the device
  testing-guide.md           -- 5-phase PoC test plan with scoring templates
  model-switching.md         -- How to switch models on hardware upgrade
scripts/
  network-monitor.sh         -- Automated network traffic monitoring
  benchmark.sh               -- LLM performance benchmarking (tokens/sec, RAM)
  switch-model.sh            -- One-command model switch with config update
docker/
  .env                       -- Active configuration (all settings)
  .env.example               -- Template for new developers
  docker-compose.yml         -- Stack definition (Ollama + models)
  entrypoint.sh              -- Auto-pulls models and configures on first start
  healthcheck.sh             -- Post-start validation
  Modelfile.template         -- Custom model config template
  versions.lock              -- Pinned, team-verified versions
  README.md                  -- Docker-specific setup guide
```

## Language and Style

- Documentation is written in **German** (for SI stakeholders), with technical terms
  in English where standard (e.g., "Embedding", "Token", "Context Window").
- Umlauts are written as ae/oe/ue (ASCII-safe for maximum compatibility).
- Code examples, commands, and config files are in **English**.

## Key Constraints

- **Hardware baseline:** Apple M1, 16 GB RAM -- all recommendations must work on this.
- **Primary model:** `qwen2.5-coder:7b` (fits in 16 GB with room for IDE).
- **No cloud dependencies:** The entire stack must work with internet disconnected.
- **All components Apache 2.0 or MIT** -- Docker packaging and redistribution must
  remain license-clean.

## When Editing Documentation

- Keep docs self-contained -- each file should be readable independently.
- Include concrete commands and expected output where possible.
- Always mention RAM requirements when discussing models.
- Update the main README.md table if adding new docs.
- Scripts must work on macOS (Apple Silicon) without additional dependencies.

## When Editing Docker Configuration

- All user-facing config goes in `.env` -- never hardcode values in docker-compose.yml.
- Every `.env` variable must have a default in docker-compose.yml (`${VAR:-default}`).
- Update `versions.lock` when pinning a new component version.
- Update `docker/README.md` settings table when adding new `.env` variables.
- The entrypoint.sh must remain idempotent (safe to run repeatedly).

## When Adding New Components

- Verify the license is Apache 2.0, MIT, or similarly permissive.
- Add a dedicated deep-dive doc in `docs/`.
- Add the component to the stack table in `README.md`.
- Update `docs/data-privacy-proof.md` with verification steps for the new component.
- Update `docs/testing-guide.md` if the component affects the test plan.

## This Is NOT

- A software project with application code (no src/, no tests/).
- A replacement for Gemini CLI -- it is a complementary local approach.
- Production-ready -- it is a PoC for evaluation purposes.
