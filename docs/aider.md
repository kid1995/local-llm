# Aider -- Deep Dive

> Terminal-basierter KI-Assistent fuer Pair Programming | Lizenz: Apache 2.0

## Was ist Aider?

Aider ist ein Terminal-nativer KI-Coding-Assistent, der direkt mit Git-Repositories
arbeitet. Anders als Cline (VS Code Extension) laeuft Aider komplett im Terminal --
aehnlich wie Claude Code, aber vollstaendig Open Source.

**Kernmerkmale:**
- Terminal-nativ und IDE-unabhaengig
- Git-aware: erstellt automatische Commits fuer Aenderungen
- Multi-File-Editing: kann mehrere Dateien gleichzeitig aendern
- Model-agnostisch: unterstuetzt Ollama, OpenAI, Anthropic, etc.
- Repository-Map: versteht die Struktur des gesamten Projekts
- Apache 2.0 Lizenz -- vollstaendig Open Source

## Installation

### Voraussetzungen

- Python 3.10+
- Git
- Ollama (lokal installiert und laufend)

### Installation via pip

```bash
# Empfohlen: in einer virtuellen Umgebung
python3 -m venv ~/.aider-venv
source ~/.aider-venv/bin/activate

# Aider installieren
pip install aider-chat

# Version pruefen
aider --version
```

### Alternative: pipx (isoliert)

```bash
# pipx installiert Aider in einer eigenen Umgebung
pipx install aider-chat
```

## Konfiguration

### Aider mit Ollama starten

```bash
# Basiskommando
aider --model ollama_chat/qwen2.5-coder:7b

# Mit spezifischer Ollama-URL (Standard ist localhost:11434)
aider --model ollama_chat/qwen2.5-coder:7b --api-base http://localhost:11434

# Nur bestimmte Dateien im Kontext
aider --model ollama_chat/qwen2.5-coder:7b src/main.py src/utils.py
```

### Konfigurationsdatei (.aider.conf.yml)

Erstelle `.aider.conf.yml` im Projekt-Root oder Home-Verzeichnis:

```yaml
# ~/.aider.conf.yml oder .aider.conf.yml im Projekt
model: ollama_chat/qwen2.5-coder:7b

# Git-Integration
auto-commits: true
dirty-commits: false
attribute-author: false
attribute-committer: false

# Editor-Verhalten
edit-format: diff
stream: true
pretty: true

# Context-Management
map-tokens: 1024
map-refresh: auto
```

### Umgebungsvariablen

```bash
# In ~/.zshrc oder ~/.bashrc
export OLLAMA_API_BASE=http://localhost:11434

# Alias fuer schnellen Start
alias ai="aider --model ollama_chat/qwen2.5-coder:7b"
```

## Grundlegende Nutzung

### Session starten

```bash
# Im Projekt-Verzeichnis
cd /pfad/zum/projekt
aider --model ollama_chat/qwen2.5-coder:7b
```

### Wichtige Befehle in der Session

| Befehl | Funktion |
|---|---|
| `/add <datei>` | Datei zum Kontext hinzufuegen |
| `/drop <datei>` | Datei aus dem Kontext entfernen |
| `/ls` | Dateien im Kontext anzeigen |
| `/diff` | Aenderungen anzeigen |
| `/undo` | Letzten Commit rueckgaengig machen |
| `/clear` | Konversation zuruecksetzen |
| `/tokens` | Token-Verbrauch anzeigen |
| `/model <name>` | Modell wechseln (live!) |
| `/help` | Hilfe anzeigen |
| `/quit` | Session beenden |

### Typische Workflows

**Feature implementieren:**
```
> /add src/auth.py src/models.py
> Implement JWT-based authentication with refresh tokens
```

**Bug fixen:**
```
> /add src/parser.py
> Fix the off-by-one error in the CSV parser that skips the last row
```

**Refactoring:**
```
> /add src/handlers/*.py
> Refactor all handlers to use the repository pattern instead of direct DB access
```

**Code Review:**
```
> /add src/api.py
> Review this file for security issues, especially SQL injection and input validation
```

## Aider + Git Integration

Aider ist tief in Git integriert:

```
+------------------+                +------------------+
|   Aider Session  |                |   Git Repo       |
|                  |  auto-commit   |                  |
|   1. Analyse     | ------------> |   feat: add auth |
|   2. Edit        |                |                  |
|   3. Commit      |  /undo        |   (revert)       |
|                  | <------------ |                  |
+------------------+                +------------------+
```

- Jede Aenderung wird automatisch als Git-Commit gespeichert
- `/undo` macht den letzten Commit rueckgaengig
- Dirty Working Directory wird erkannt und behandelt
- Commit-Messages werden automatisch generiert

## Modell live wechseln

Ein grosser Vorteil von Aider: Modelle koennen waehrend der Session gewechselt werden.

```
> /model ollama_chat/qwen2.5-coder:7b
Switched to ollama_chat/qwen2.5-coder:7b

> /model ollama_chat/qwen2.5-coder:14b
Switched to ollama_chat/qwen2.5-coder:14b
```

Dies ist besonders nuetzlich beim Hardware-Upgrade -- siehe [model-switching.md](model-switching.md).

## Performance mit lokalen Modellen

### Erwartete Geschwindigkeit (Apple M1, 16 GB)

| Modell | Tokens/Sekunde | Gefuehlt |
|---|---|---|
| qwen2.5-coder:3b | ~40-50 t/s | Sehr fluessig |
| qwen2.5-coder:7b | ~20-30 t/s | Fluessig |
| qwen2.5-coder:14b | ~8-12 t/s | Nutzbar, aber spuerbar |

### Optimierung

```yaml
# .aider.conf.yml
# Weniger Kontext = schnellere Antworten
map-tokens: 512

# Streaming aktivieren (Antwort erscheint sofort)
stream: true
```

## Vergleich mit Claude Code

| Merkmal | Aider | Claude Code |
|---|---|---|
| Lizenz | Apache 2.0 (Open Source) | Proprietaer |
| Interface | Terminal | Terminal |
| Lokale Modelle | Ja (Ollama) | Nein (nur Anthropic API) |
| Git-Integration | Automatische Commits | Ja |
| Quellcode | Oeffentlich | Nicht oeffentlich |
| Model-Wechsel | Live in Session | Nicht moeglich |
| Preis | Kostenlos | API-Kosten |

Aider ist die beste Open-Source-Alternative zu Claude Code fuer Terminal-basierte Workflows.

## Troubleshooting

### Aider findet Ollama nicht

```bash
# Pruefen ob Ollama laeuft
curl http://localhost:11434/api/tags

# Explizite URL angeben
aider --model ollama_chat/qwen2.5-coder:7b --api-base http://localhost:11434
```

### Langsame Antworten

```bash
# Kleineres Modell verwenden
aider --model ollama_chat/qwen2.5-coder:3b

# Context reduzieren
aider --model ollama_chat/qwen2.5-coder:7b --map-tokens 512
```

### Git-Fehler

```bash
# Aider braucht ein initialisiertes Git-Repo
git init
git add .
git commit -m "Initial commit"

# Dann Aider starten
aider --model ollama_chat/qwen2.5-coder:7b
```

## Quellcode-Referenz

Repository: https://github.com/paul-gauthier/aider

Relevante Dateien fuer Datenschutz-Audit:
- `aider/llm.py` -- LLM API Kommunikation
- `aider/models.py` -- Modell-Konfiguration
- `aider/coders/` -- Kern-Logik
