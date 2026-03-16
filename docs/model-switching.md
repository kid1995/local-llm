# Modellwechsel bei Hardware-Upgrade

> Anleitung zum schnellen Wechsel auf groessere Modelle bei besserer Hardware

## Ueberblick

Der Wechsel zu einem groesseren (besseren) Modell ist trivial -- ein einziger
`ollama pull` Befehl genuegt. Die Tool-Konfiguration (Cline/Aider) erfordert
nur die Aenderung des Modellnamens.

## Hardware -> Modell Zuordnung

| RAM | CPU/GPU | Empfohlenes Modell | Ollama-Tag | Qualitaet |
|---|---|---|---|---|
| 8 GB | M1/M2 | Qwen2.5-Coder 3B | `qwen2.5-coder:3b` | Basis |
| **16 GB** | **M1/M2** | **Qwen2.5-Coder 7B** | **`qwen2.5-coder:7b`** | **Gut (PoC)** |
| 32 GB | M2 Pro/Max | Qwen2.5-Coder 14B | `qwen2.5-coder:14b` | Sehr gut |
| 32 GB | M2 Pro/Max | Qwen3.5 9B | `qwen3.5:9b` | Sehr gut |
| 64 GB | M2 Ultra/M3 | Qwen2.5-Coder 32B | `qwen2.5-coder:32b` | Exzellent |
| 64 GB+ | M3 Pro/Max | Qwen3.5 27B | `qwen3.5:27b` | Nahe Frontier |

## Schritt-fuer-Schritt: Modellwechsel

### 1. Neues Modell herunterladen

```bash
# Beispiel: Wechsel von 7B auf 14B (nach RAM-Upgrade auf 32 GB)
ollama pull qwen2.5-coder:14b

# Oder: Wechsel auf Qwen3.5 (naechste Generation)
ollama pull qwen3.5:27b
```

### 2. Modell testen

```bash
# Schnelltest
ollama run qwen2.5-coder:14b "Write a binary search in Python"

# Performance messen
curl -s http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5-coder:14b",
    "messages": [{"role": "user", "content": "Write quicksort in Python"}],
    "stream": false
  }' | python3 -c "
import sys, json
d = json.load(sys.stdin)
t = d.get('total_duration', 0)
n = d.get('eval_count', 0)
if t > 0 and n > 0:
    print(f'{n/(t/1e9):.1f} tokens/sec')
"
```

### 3. Cline umstellen

In VS Code:
1. Cline Settings oeffnen (Zahnrad-Icon)
2. Model aendern: `qwen2.5-coder:14b`
3. Speichern -- fertig

Oder in `settings.json`:

```json
{
  "cline.ollamaModelId": "qwen2.5-coder:14b"
}
```

### 4. Aider umstellen

**Option A: Kommandozeile**

```bash
aider --model ollama_chat/qwen2.5-coder:14b
```

**Option B: Konfigurationsdatei**

```yaml
# .aider.conf.yml
model: ollama_chat/qwen2.5-coder:14b
```

**Option C: Live in der Session**

```
> /model ollama_chat/qwen2.5-coder:14b
Switched to ollama_chat/qwen2.5-coder:14b
```

### 5. Altes Modell entfernen (optional)

```bash
# Speicherplatz freigeben
ollama rm qwen2.5-coder:7b

# Pruefen, welche Modelle installiert sind
ollama list
```

## Automatisierung: Model-Switch Script

```bash
#!/bin/bash
# scripts/switch-model.sh
# Schneller Modellwechsel mit Validierung

set -euo pipefail

NEW_MODEL="${1:?Usage: switch-model.sh <model-tag>}"

echo "=== Modellwechsel auf: $NEW_MODEL ==="

# 1. Modell herunterladen (falls noetig)
echo "Pruefe/lade Modell..."
ollama pull "$NEW_MODEL"

# 2. Schnelltest
echo "Teste Modell..."
RESPONSE=$(ollama run "$NEW_MODEL" "Say 'OK' if you work" 2>&1)
if echo "$RESPONSE" | grep -qi "ok\|yes\|hello\|hi"; then
    echo "Modell antwortet korrekt."
else
    echo "WARNUNG: Unerwartete Antwort: $RESPONSE"
fi

# 3. Aider-Konfiguration aktualisieren
AIDER_CONF=".aider.conf.yml"
if [ -f "$AIDER_CONF" ]; then
    sed -i '' "s|^model:.*|model: ollama_chat/$NEW_MODEL|" "$AIDER_CONF"
    echo "Aider-Konfiguration aktualisiert: $AIDER_CONF"
else
    echo "model: ollama_chat/$NEW_MODEL" > "$AIDER_CONF"
    echo "Aider-Konfiguration erstellt: $AIDER_CONF"
fi

# 4. Hinweis fuer Cline
echo ""
echo "=== Naechste Schritte ==="
echo "Cline: Settings -> Model -> '$NEW_MODEL'"
echo "Aider: Konfiguration bereits aktualisiert"
echo ""
echo "Modellwechsel abgeschlossen."
```

## Upgrade-Pfade

### Pfad 1: Schrittweises Upgrade (empfohlen)

```
16 GB (jetzt)                32 GB                    64 GB
qwen2.5-coder:7b    ->    qwen2.5-coder:14b    ->    qwen3.5:27b
                           oder qwen3.5:9b
```

### Pfad 2: Zwei Modelle parallel (32+ GB)

Bei genuegend RAM koennen zwei Modelle geladen werden:
- Schnelles kleines Modell fuer einfache Aufgaben (3B/7B)
- Groesseres Modell fuer komplexe Aufgaben (14B/32B)

```bash
# In Aider: Live wechseln je nach Aufgabe
> /model ollama_chat/qwen2.5-coder:7b    # Schnelle Antwort fuer einfache Fragen
> /model ollama_chat/qwen2.5-coder:14b   # Bessere Qualitaet fuer komplexen Code
```

### Pfad 3: Qwen3.5 Migration

Wenn Qwen3.5 in Ollama verfuegbar wird (ab v0.17):

```bash
# Ollama aktualisieren
brew upgrade ollama

# Qwen3.5 verfuegbarkeit pruefen
ollama search qwen3.5

# Wenn verfuegbar: herunterladen und testen
ollama pull qwen3.5:9b   # fuer 32 GB
ollama pull qwen3.5:27b  # fuer 64 GB
```

## Vergleich: Qualitaetssprung bei Modellwechsel

| Aufgabe | 3B | 7B | 14B | 32B |
|---|---|---|---|---|
| Einfache Funktionen | OK | Gut | Sehr gut | Exzellent |
| Komplexe Algorithmen | Schwach | Mittel | Gut | Sehr gut |
| Multi-File Refactoring | Schwach | Mittel | Gut | Gut |
| Security Review | Schwach | Mittel | Gut | Sehr gut |
| Dokumentation | OK | Gut | Sehr gut | Exzellent |
| Geschwindigkeit (M1) | ~50 t/s | ~25 t/s | ~12 t/s | Zu langsam |

**Empfehlung:** Der Sprung von 7B auf 14B bringt den groessten Qualitaetsgewinn
pro zusaetzlichem RAM.
