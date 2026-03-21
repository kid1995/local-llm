# Cline + Ollama Experiment Protocol

> Datum: 2026-03-20
> Hardware: Apple M1, 16 GB RAM
> Ziel: Testen ob Cline (VS Code Extension) mit lokalen Modellen via Ollama funktioniert

## Setup

- **Ollama:** v0.18.2, installiert via Homebrew
- **Cline:** v3.74.0 (VS Code Extension `saoudrizwan.claude-dev`)
- **VS Code:** Aktuelle Version, macOS
- **Ollama Config:** Flash Attention enabled, KV Cache q8_0

## Test 1: qwen2.5-coder:7b (4.7 GB)

**Ergebnis: FEHLGESCHLAGEN**

- Modell laeuft korrekt und antwortet ueber die API in 7-9 Sekunden
- Cline sendet 16 aufeinanderfolgende Anfragen, alle mit HTTP 200
- **Problem:** Das 7b-Modell kann Clines strukturiertes Tool-Calling-Format nicht zuverlaessig erzeugen
- Fehlermeldung: `Cline tried to use ask_followup_question without value for required parameter 'question'. Retrying...`
- **Ursache:** Cline verwendet komplexe XML/JSON-strukturierte Prompts fuer Aktionen (Dateien lesen/schreiben, Terminal-Befehle). Das 7b-Modell erzeugt fehlerhaften Output (fehlende Parameter), Cline verwirft die Antwort und versucht es erneut -- Endlosschleife.

**Ollama-Log Auszug:**
```
[GIN] 2026/03/20 - 12:33:30 | 200 | 47.142s | 127.0.0.1 | POST "/api/chat"
[GIN] 2026/03/20 - 12:33:39 | 200 | 25.323s | 127.0.0.1 | POST "/api/chat"
[GIN] 2026/03/20 - 12:33:47 | 200 |  8.083s | 127.0.0.1 | POST "/api/chat"
... (16 Anfragen insgesamt, alle 200 OK)
```

**Fazit:** Modell-Kapazitaet zu gering fuer Clines Agentic-Workflow. Kein Konfigurationsfehler.

## Test 2: qwen2.5-coder:14b (9.0 GB)

**Ergebnis: FEHLGESCHLAGEN**

- Benutzerdefiniertes Modell `cline-14b` erstellt (Modelfile mit num_ctx=4096, temperature=0.2)
- Modell antwortet korrekt ueber direkte API-Aufrufe (1.4s fuer einfache Anfragen)

**Problem: Cline erzwingt 32k Context Window**

Cline sendet `num_ctx: 32768` in jeder API-Anfrage, unabhaengig von:
- Modelfile-Konfiguration (`PARAMETER num_ctx 4096`)
- Ollama Umgebungsvariable (`OLLAMA_NUM_CTX=4096`)
- Ollama LaunchAgent plist-Konfiguration
- VS Code settings.json (`cline.ollamaApiOptionsCtxNum`)

**Auswirkung auf 16 GB RAM:**

| Metrik | Mit 4k Context (gewuenscht) | Mit 32k Context (Cline erzwingt) |
|---|---|---|
| GPU-Layer | 49/49 (alle auf GPU) | 39/49 (10 auf CPU) |
| CPU-Mapped | 417 MB | 8566 MB |
| KV Cache | 408 MB | 3264 MB |
| Graph Splits | 2 | 111 |
| Antwortzeit | ~1.4s | 60-105s |

- Fehlermeldung: `Ollama request timed out after 30 seconds`
- Clines Timeout ist auf 30 Sekunden hardcoded (nicht konfigurierbar)
- Selbst wenn die Antwort durchkommt (69s laut Log), ist das Timeout laengst abgelaufen

**Ollama-Log Auszug:**
```
load_tensors: offloaded 39/49 layers to GPU
load_tensors: CPU_Mapped model buffer size = 8566.04 MiB
llama_context: n_ctx = 32768
llama_kv_cache: size = 3264.00 MiB (32768 cells, 48 layers)
llama_context: graph splits = 111 (with bs=512)

[GIN] 2026/03/20 - 13:42:43 | 500 | 1m45s  | 127.0.0.1 | POST "/api/chat"
[GIN] 2026/03/20 - 13:42:43 | 500 | 1m14s  | 127.0.0.1 | POST "/api/chat"
msg="aborting completion request due to client closing the connection"
```

**Fazit:** 14b-Modell funktioniert einwandfrei mit 4k Context, aber Cline ueberladt den Kontext auf 32k, was den verfuegbaren RAM sprengt und zu CPU-Spillover + Timeout fuehrt.

## Zusammenfassung

### Cline ist NICHT geeignet fuer lokale Modelle auf 16 GB RAM

**Zwei unloesbare Probleme:**

1. **Kleine Modelle (7b):** Zu geringe Instruction-Following-Faehigkeit fuer Clines komplexes Tool-Calling-Format. Modell erzeugt fehlerhaften strukturierten Output.

2. **Mittlere Modelle (14b):** Cline erzwingt 32k Context Window per API-Request. Nicht konfigurierbar (weder server-seitig noch client-seitig wirksam). Auf 16 GB RAM fuehrt das zu massivem CPU-Spillover und 60s+ Antwortzeiten, die Clines hardcoded 30s Timeout ueberschreiten.

### Empfehlung

| Tool | Geeignet fuer 7b/16GB | Geeignet fuer 14b/16GB | Grund |
|---|---|---|---|
| **Cline** | Nein | Nein | Komplexe Prompts + erzwungenes 32k Context |
| **Aider** | Ja | Ja | Einfache Diff-basierte Prompts, kein Tool-Calling |
| **Continue.dev** | Ja | Ja | Chat-basiert, kein Agentic-Workflow |

### Mindestanforderungen fuer Cline mit lokalen Modellen

- **RAM:** 32 GB+ (damit 14b+ mit 32k Context vollstaendig auf GPU laeuft)
- **Modell:** 14b+ (fuer zuverlaessiges Instruction-Following)
- **Oder:** Cline muesste `num_ctx` konfigurierbar machen (Feature Request)

### Verifizierte Konfiguration (funktioniert ohne Cline)

```bash
# Ollama mit qwen2.5-coder:14b, 4k Context -- antwortet in 1.4s
curl http://localhost:11434/v1/chat/completions \
  -d '{"model":"cline-14b","messages":[{"role":"user","content":"Fix this bug"}]}'
```

Die direkte API-Nutzung funktioniert einwandfrei. Das Problem liegt ausschliesslich bei Clines Client-Verhalten.
