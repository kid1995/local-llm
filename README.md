# Lokale LLM-Entwicklungsumgebung -- PoC

> **Proof of Concept:** Lokale Modelle auf privaten Geraeten in der SI
>
> Ziel: KI-gestuetzte Softwareentwicklung ohne Cloud-Anbindung, ohne laufende Kosten,
> mit vollstaendiger Kontrolle ueber Datensicherheit.

## Ueberblick

Dieses Repository dokumentiert ein vollstaendig lokales Setup fuer KI-gestuetzte
Entwicklung. Der gesamte Stack laeuft offline -- Code verlasst das Geraet zu keinem
Zeitpunkt, nicht nur konfigurativ, sondern architektonisch.

### Stack-Komponenten

| Komponente | Rolle | Lizenz | Dokumentation |
|---|---|---|---|
| [Ollama](https://ollama.com) | Lokaler Model-Server | MIT | [docs/ollama.md](docs/ollama.md) |
| [Qwen-Modelle](https://huggingface.co/Qwen) | LLM fuer Code-Generierung | Apache 2.0 | [docs/qwen-models.md](docs/qwen-models.md) |
| [Cline](https://github.com/cline/cline) | VS Code KI-Assistent | Apache 2.0 | [docs/cline.md](docs/cline.md) |
| [Aider](https://github.com/paul-gauthier/aider) | Terminal KI-Assistent | Apache 2.0 | [docs/aider.md](docs/aider.md) |
| [LanceDB](https://lancedb.github.io/lancedb/) + [nomic-embed-text](https://ollama.com/library/nomic-embed-text) | Lokale Vektor-DB + Embeddings | Apache 2.0 / MIT | [docs/lancedb-embeddings.md](docs/lancedb-embeddings.md) |

### Weitere Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/data-privacy-proof.md](docs/data-privacy-proof.md) | Nachweis: Kein Datenabfluss |
| [docs/testing-guide.md](docs/testing-guide.md) | PoC-Testplan und Evaluierung |
| [docs/model-switching.md](docs/model-switching.md) | Modellwechsel bei Hardware-Upgrade |
| [docs/confluence-wiki.md](docs/confluence-wiki.md) | Confluence-Wiki (1:1 kopierbar) |
| [docs/poc-demo-guide.md](docs/poc-demo-guide.md) | Demo-Guide: Was zeigen, was coden |
| [docker/](docker/) | Docker-Distribution fuer Team-Rollout |

## Schnellstart

### Option A: Docker (empfohlen fuer Team-Verteilung)

```bash
cd docker/
cp .env.example .env   # Konfiguration anpassen (Modell, RAM, etc.)
docker compose up       # Fertig -- Modell wird automatisch geladen
./healthcheck.sh        # Pruefen, ob alles laeuft
```

Siehe [docker/README.md](docker/README.md) fuer alle Details.

### Option B: Native Installation

### Voraussetzungen

- macOS mit Apple Silicon (M1/M2/M3/M4) oder Linux mit GPU
- Mindestens 16 GB RAM (fuer Qwen2.5-Coder:7b)
- VS Code (fuer Cline) oder Terminal (fuer Aider)
- Python 3.10+ (fuer Aider)

### 1. Ollama installieren und Modell laden

```bash
# Ollama installieren (macOS)
brew install ollama

# Ollama-Server starten
ollama serve

# In einem neuen Terminal: Modell laden
# Fuer 16 GB RAM -- Qwen2.5-Coder 7B (quantisiert, ~5 GB RAM)
ollama pull qwen2.5-coder:7b

# Embedding-Modell laden
ollama pull nomic-embed-text
```

### 2a. Cline einrichten (VS Code)

```bash
# Cline-Extension installieren
code --install-extension saoudrizwan.claude-dev
```

Dann in VS Code:
1. Cline-Sidebar oeffnen (Cmd+Shift+P -> "Cline: Open")
2. Settings -> API Provider: "Ollama"
3. Model: "qwen2.5-coder:7b"
4. Base URL: "http://localhost:11434"

### 2b. Aider einrichten (Terminal)

```bash
# Aider installieren
pip install aider-chat

# Aider mit lokalem Modell starten
aider --model ollama_chat/qwen2.5-coder:7b
```

### 3. Funktionstest

```bash
# Pruefen, ob Ollama laeuft
curl http://localhost:11434/api/tags

# Modell direkt testen
ollama run qwen2.5-coder:7b "Write a Python function that checks if a number is prime"
```

## Hardware-Empfehlungen

| RAM | Empfohlenes Modell | Qualitaet | Details |
|---|---|---|---|
| 16 GB | `qwen2.5-coder:7b` | Gut fuer PoC | [docs/qwen-models.md](docs/qwen-models.md) |
| 32 GB | `qwen2.5-coder:14b` | Deutlich besser | Empfehlung fuer Entwickler-Laptops |
| 64 GB+ | `qwen3.5:27b` | Nahe Frontier | Optimal fuer Power-User |

Siehe [docs/model-switching.md](docs/model-switching.md) fuer den Wechsel bei Hardware-Upgrade.

## Lizenzuebersicht

Alle Komponenten sind Open Source (Apache 2.0 oder MIT). Docker-Packaging und
Weiterverteilung sind lizenzrechtlich unproblematisch.

| Komponente | Lizenz | Kommerziell nutzbar |
|---|---|---|
| Ollama | MIT | Ja |
| Qwen-Modelle | Apache 2.0 | Ja |
| Cline | Apache 2.0 | Ja |
| Aider | Apache 2.0 | Ja |
| LanceDB | Apache 2.0 | Ja |
| nomic-embed-text | Apache 2.0 | Ja |

## Strategischer Kontext

Dieses Setup ist **kein Ersatz** fuer Gemini CLI, sondern eine Ergaenzung:

1. **Low-Cost-Survey:** Fruehzeitig Entwickler-Reaktionen auf CLI-basierte KI-Assistenten
   beobachten -- ohne Lizenzkosten, ohne Cloud.
2. **Entlastung:** Fallback bei hoher Gemini-CLI-Nutzung (Kosten/Quotas).
3. **Fruehere Verfuegbarkeit:** Weichere ISO 27001/DORA-Anforderungen ermoeglichen
   sofortigen Einsatz.
4. **Ausbildung:** Lokale Modelle sind Frontier-Modellen unterlegen -- Entwickler lernen,
   KI kritisch als Werkzeug einzusetzen, statt sich auf sie zu verlassen.
