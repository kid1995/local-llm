# Ollama -- Deep Dive

> Lokaler Model-Server fuer LLMs | Lizenz: MIT

## Was ist Ollama?

Ollama ist ein leichtgewichtiger Server, der LLMs lokal auf dem eigenen Geraet ausfuehrt.
Er abstrahiert die Komplexitaet von Modellformaten, Quantisierung und GPU-Beschleunigung
hinter einer einfachen API, die kompatibel mit dem OpenAI-API-Format ist.

**Kernmerkmale:**
- Laeuft vollstaendig offline nach dem initialen Modell-Download
- Automatische GPU-Beschleunigung (Metal auf Apple Silicon, CUDA auf NVIDIA)
- OpenAI-kompatible REST-API (`/v1/chat/completions`)
- Modell-Registry mit vorgefertigten, quantisierten Modellen
- Unterstuetzt GGUF-Modelle (llama.cpp Backend)

## Installation

### macOS (Homebrew)

```bash
brew install ollama
```

### macOS (manuell)

Download von https://ollama.com/download/mac

### Linux

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Pruefen der Installation

```bash
ollama --version
```

## Architektur

```
+------------------+     HTTP/REST      +------------------+
|  Cline / Aider   | ----------------> |   Ollama Server   |
|  (Client)        |   localhost:11434  |   (ollama serve)  |
+------------------+                    +--------+---------+
                                                 |
                                        +--------+---------+
                                        |   llama.cpp      |
                                        |   (Inference)    |
                                        +--------+---------+
                                                 |
                                        +--------+---------+
                                        |  Metal / CUDA    |
                                        |  (GPU Backend)   |
                                        +------------------+
```

Ollama bindet sich standardmaessig an `127.0.0.1:11434`. Ohne explizite Konfiguration
ist der Server **nur lokal erreichbar** -- kein Netzwerk-Listener.

## Server starten und verwalten

```bash
# Server starten (Vordergrund)
ollama serve

# Auf macOS: Ollama-App starten (laeuft als Menuebar-Service)
# Der Server startet automatisch

# Pruefen, ob der Server laeuft
curl http://localhost:11434/api/tags
```

## Modelle verwalten

```bash
# Modell herunterladen
ollama pull qwen2.5-coder:7b

# Alle lokalen Modelle auflisten
ollama list

# Modell-Details anzeigen (Groesse, Quantisierung, Parameter)
ollama show qwen2.5-coder:7b

# Modell loeschen
ollama rm qwen2.5-coder:7b

# Modell interaktiv testen
ollama run qwen2.5-coder:7b
```

## API-Endpunkte

### Chat Completion (OpenAI-kompatibel)

```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Native Ollama API

```bash
# Chat
curl http://localhost:11434/api/chat \
  -d '{"model": "qwen2.5-coder:7b", "messages": [{"role": "user", "content": "Hello"}]}'

# Embeddings
curl http://localhost:11434/api/embed \
  -d '{"model": "nomic-embed-text", "input": "Hello world"}'

# Laufende Modelle anzeigen
curl http://localhost:11434/api/ps
```

## Konfiguration

### Umgebungsvariablen

```bash
# Bind-Adresse aendern (Standard: 127.0.0.1:11434)
export OLLAMA_HOST=127.0.0.1:11434

# Modell-Verzeichnis aendern (Standard: ~/.ollama/models)
export OLLAMA_MODELS=/pfad/zu/modellen

# GPU-Layer begrenzen (nuetzlich bei wenig VRAM)
export OLLAMA_NUM_GPU=999  # alle Layer auf GPU

# Maximale gleichzeitige Anfragen
export OLLAMA_MAX_LOADED_MODELS=1  # bei 16 GB RAM empfohlen

# Context-Window-Groesse (Standard: 2048)
export OLLAMA_NUM_CTX=4096
```

### Modelfile (eigene Konfiguration)

```dockerfile
# Datei: Modelfile.custom-qwen
FROM qwen2.5-coder:7b

# System-Prompt setzen
SYSTEM "Du bist ein erfahrener Softwareentwickler. Antworte praezise und technisch korrekt."

# Parameter anpassen
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER num_ctx 8192
```

```bash
# Eigenes Modell erstellen
ollama create custom-qwen -f Modelfile.custom-qwen

# Testen
ollama run custom-qwen
```

## Performance-Tuning fuer 16 GB RAM

```bash
# Nur ein Modell gleichzeitig laden
export OLLAMA_MAX_LOADED_MODELS=1

# Context-Window begrenzen (spart RAM)
# 4096 Tokens ist ein guter Kompromiss
export OLLAMA_NUM_CTX=4096

# Modell nach Inaktivitaet entladen (Standard: 5 Minuten)
export OLLAMA_KEEP_ALIVE=5m
```

**RAM-Verbrauch nach Modellgroesse (q4_K_M Quantisierung):**

| Modell | Modell-RAM | + Context (4k) | Gesamt |
|---|---|---|---|
| qwen2.5-coder:3b | ~2.0 GB | ~0.5 GB | ~2.5 GB |
| qwen2.5-coder:7b | ~4.7 GB | ~1.0 GB | ~5.7 GB |
| qwen2.5-coder:14b | ~9.0 GB | ~1.5 GB | ~10.5 GB |

Bei 16 GB RAM (davon ~13 GB nutzbar nach macOS) ist `qwen2.5-coder:7b` die optimale Wahl.

## Troubleshooting

### Server startet nicht

```bash
# Pruefen, ob Port belegt ist
lsof -i :11434

# Ollama-Prozesse beenden
pkill ollama

# Neu starten
ollama serve
```

### Modell laeuft langsam

```bash
# GPU-Nutzung pruefen (macOS)
sudo powermetrics --samplers gpu_power -i 1000 -n 1

# Laufende Modelle und GPU-Nutzung anzeigen
curl http://localhost:11434/api/ps
```

### Speicherplatz pruefen

```bash
# Modellgroessen anzeigen
ollama list

# Gesamtgroesse des Modellverzeichnisses
du -sh ~/.ollama/models
```

## Sicherheitshinweise

- Ollama bindet sich standardmaessig an `127.0.0.1` (nur lokal erreichbar)
- **Niemals** `OLLAMA_HOST=0.0.0.0` setzen, ausser in kontrollierten Umgebungen
- Keine Authentifizierung am API-Endpunkt -- Netzwerkzugriff = voller Zugriff
- Siehe [data-privacy-proof.md](data-privacy-proof.md) fuer den Nachweis der Datensicherheit
