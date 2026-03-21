# Aider + Ollama Test Workspace

This directory is a working space for testing Aider (terminal-based AI coding assistant)
with Ollama running local models.

## Setup

1. Ollama is installed and running: `ollama list`
2. Models: `qwen2.5-coder:7b` (4.7 GB) and `qwen2.5-coder:14b` (9.0 GB)
3. Aider installed in venv: `~/.aider-venv`

## Quick Start

```bash
# Activate venv and start Aider in this directory
source ~/.aider-venv/bin/activate
cd workspace/
aider

# Or with the shell alias (if configured in ~/.zshrc):
ai
```

## Configuration

See `.aider.conf.yml` for default settings (model, context, git behavior).

## Test Tasks for Aider

Same tasks as the Cline experiment, for direct comparison:

### Task 1: Fix a bug (easy)
```
> /add calculator.py
> The divide function has a bug -- it doesn't handle division by zero. Fix it.
```

### Task 2: Add a feature (medium)
```
> /add calculator.py
> Add a power/exponent function to calculator.py
```

### Task 3: Generate tests (medium)
```
> /add calculator.py
> Write pytest tests for calculator.py in a new file test_calculator.py
```

### Task 4: Explain code (easy)
```
> /add todo_api.py
> Explain what todo_api.py does
```

### Task 5: Refactor (harder)
```
> /add todo_api.py
> Refactor todo_api.py to use dataclasses instead of plain dicts
```

## Switching Models

```
> /model ollama_chat/qwen2.5-coder:14b
```

## Previous Experiment: Cline

Cline was tested first but failed on 16 GB RAM. See `docs/cline-experiment-protocol.md`
for the full protocol.
