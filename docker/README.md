# Docker Distribution

> Reproduzierbare Installation des lokalen LLM-Stacks fuer das gesamte Team.

## Ueberblick

Dieses Docker-Setup verpackt den gesamten Stack in einen einzigen `docker compose up`
Befehl. Alle Entwickler erhalten dieselbe geprueffte Modellversion und Konfiguration.

```
+------------------------------------------------------------------+
|  Docker Container: local-llm-ollama                               |
|                                                                   |
|  +------------------+    +------------------+                     |
|  | Ollama Server    |    | Models (Volume)  |                     |
|  | (Inference)      |    | - qwen2.5-coder  |                     |
|  |                  |    | - nomic-embed    |                     |
|  +--------+---------+    +------------------+                     |
|           |                                                       |
|    localhost:11434                                                 |
+-----------|-------------------------------------------------------+
            |
   +--------+---------+
   | Host Machine      |
   | - Cline (VS Code) |
   | - Aider (Terminal) |
   +-------------------+
```

## Schnellstart

### Voraussetzungen

- Docker Desktop 4.0+ (macOS/Linux/Windows)
- Mindestens 16 GB RAM

### 1. Starten

```bash
cd docker/

# Standard-Konfiguration (qwen2.5-coder:7b, 4096 Context)
docker compose up

# Oder im Hintergrund:
docker compose up -d
```

Beim ersten Start wird das Modell heruntergeladen (~5 GB). Danach startet es in
Sekunden dank des persistenten Volumes.

### 2. Pruefen

```bash
# Health Check
./healthcheck.sh

# Oder manuell:
curl http://localhost:11434/api/tags
```

### 3. Clients verbinden

**Cline (VS Code):**
- Provider: Ollama
- Base URL: `http://localhost:11434`
- Model: `qwen2.5-coder:7b` (oder `local-llm` fuer vorkonfiguriertes Modell)

**Aider (Terminal):**
```bash
aider --model ollama_chat/qwen2.5-coder:7b
```

### 4. Stoppen

```bash
docker compose down        # Stoppen (Modelle bleiben im Volume)
docker compose down -v     # Stoppen + Modelle loeschen
```

## Konfiguration

Alle Einstellungen stehen in `.env`. Aendern und neu starten:

```bash
# .env editieren
vim .env

# Aenderungen uebernehmen
docker compose up -d
```

### Wichtige Einstellungen

| Variable | Default | Beschreibung |
|---|---|---|
| `LLM_MODEL` | `qwen2.5-coder:7b` | LLM-Modell (siehe Tabelle unten) |
| `EMBEDDING_MODEL` | `nomic-embed-text` | Embedding-Modell fuer RAG |
| `NUM_CTX` | `4096` | Context Window (Tokens) |
| `TEMPERATURE` | `0.2` | Kreativitaet (0.0-1.0) |
| `TOP_P` | `0.9` | Sampling-Parameter |
| `MAX_LOADED_MODELS` | `1` | Gleichzeitig geladene Modelle |
| `KEEP_ALIVE` | `10m` | Modell-Entladung nach Inaktivitaet |
| `OLLAMA_PORT` | `11434` | API-Port |
| `OLLAMA_HOST` | `127.0.0.1` | Bind-Adresse (Sicherheit!) |
| `OLLAMA_VERSION` | `0.6.2` | Gepinnte Ollama-Version |

### Modell wechseln

```bash
# In .env aendern:
LLM_MODEL=qwen2.5-coder:14b

# Neu starten (laedt neues Modell automatisch):
docker compose up -d
```

### Modell-Auswahl nach Hardware

| RAM | LLM_MODEL | NUM_CTX |
|---|---|---|
| 8 GB | `qwen2.5-coder:3b` | `2048` |
| 16 GB | `qwen2.5-coder:7b` | `4096` |
| 32 GB | `qwen2.5-coder:14b` | `8192` |
| 64 GB | `qwen2.5-coder:32b` | `16384` |
| 64 GB+ | `qwen3.5:27b` | `16384` |

## Dateistruktur

```
docker/
├── .env                  # Aktive Konfiguration (git-ignored falls gewuenscht)
├── .env.example          # Template zum Kopieren
├── docker-compose.yml    # Stack-Definition
├── entrypoint.sh         # Model-Pull und Konfiguration beim Start
├── healthcheck.sh        # Validierung nach dem Start
├── Modelfile.template    # Template fuer Custom-Modell-Konfiguration
├── versions.lock         # Gepinnte, verifizierte Versionen
└── README.md             # Diese Datei
```

## Versionierung

Die Datei `versions.lock` enthaelt alle geprueften Komponentenversionen.
Der Workflow fuer ein Update:

1. Neue Version lokal testen
2. `docker compose up --build` mit neuer Version
3. `../scripts/benchmark.sh` -- Performance pruefen
4. `./healthcheck.sh` -- Funktionalitaet pruefen
5. `../scripts/network-monitor.sh check` -- Datenschutz pruefen
6. `versions.lock` aktualisieren
7. Commit und Team benachrichtigen

## Verteilung an Entwickler

### Option A: Compose-Datei teilen (empfohlen)

```bash
# Entwickler klont das Repository
git clone <repo-url>
cd local-llm/docker

# Konfiguration anpassen
cp .env.example .env
vim .env  # RAM-passende Modellgroesse waehlen

# Starten
docker compose up -d
```

### Option B: Vorgefertigtes Image mit Modell

Falls der Modell-Download zu lange dauert oder kein Internet verfuegbar ist:

```bash
# Admin: Image mit Modell exportieren
docker compose up -d
# Warten bis Modell geladen...
docker commit local-llm-ollama local-llm-prebaked:latest
docker save local-llm-prebaked:latest | gzip > local-llm-prebaked.tar.gz

# Entwickler: Image importieren
docker load < local-llm-prebaked.tar.gz
docker run -d -p 11434:11434 local-llm-prebaked:latest
```

### Option C: Internes Registry

```bash
# Admin: Pushen in internes Registry
docker tag local-llm-prebaked:latest registry.internal.si/local-llm:latest
docker push registry.internal.si/local-llm:latest

# Entwickler: Pullen
docker pull registry.internal.si/local-llm:latest
```

## Troubleshooting

### Container startet nicht

```bash
# Logs pruefen
docker compose logs -f

# Container-Status
docker compose ps
```

### Modell-Download schlaegt fehl

```bash
# Manuell in den Container gehen
docker compose exec ollama bash

# Modell manuell pullen
ollama pull qwen2.5-coder:7b
```

### Nicht genug RAM

```bash
# In .env: kleineres Modell waehlen
LLM_MODEL=qwen2.5-coder:3b
NUM_CTX=2048

# Neu starten
docker compose up -d
```

### Port-Konflikt

```bash
# In .env: anderen Port waehlen
OLLAMA_PORT=11435

# Neu starten
docker compose up -d

# Clients muessen den neuen Port verwenden
```

## Sicherheit

- Container bindet standardmaessig an `127.0.0.1` (nur lokal)
- Kein Internet-Zugang noetig nach dem initialen Modell-Download
- Modelle werden in einem benannten Docker Volume persistiert
- Keine Telemetrie, keine Cloud-Verbindungen
- Gesamter Stack Open Source (auditierbar)

Fuer den vollstaendigen Datenschutz-Nachweis siehe
[../docs/data-privacy-proof.md](../docs/data-privacy-proof.md).
