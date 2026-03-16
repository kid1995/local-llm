# Qwen-Modelle -- Deep Dive

> Open-Source LLMs von Alibaba Cloud | Lizenz: Apache 2.0

## Warum Qwen?

Qwen (Tongyi Qianwen) ist eine Familie von Open-Source-LLMs, die in Coding-Benchmarks
konsistent zu den besten Open-Source-Modellen gehoeren. Die Apache 2.0 Lizenz erlaubt
uneingeschraenkte kommerzielle Nutzung.

**Vorteile fuer diesen PoC:**
- Apache 2.0 Lizenz -- keine Einschraenkungen
- Spezialisierte Coder-Varianten (Qwen2.5-Coder)
- Verfuegbar in verschiedenen Groessen (0.5B bis 72B Parameter)
- Optimiert fuer Instruction-Following und Code-Generierung
- Unterstuetzen Tool-Use / Function-Calling

## Modell-Uebersicht

### Qwen2.5-Coder (aktuell empfohlen)

Speziell fuer Code-Aufgaben trainierte Variante mit 5.5 Billionen Tokens Code-Daten.

| Modell | Parameter | RAM (q4_K_M) | Ollama-Tag | Empfehlung |
|---|---|---|---|---|
| Qwen2.5-Coder 3B | 3.1B | ~2.5 GB | `qwen2.5-coder:3b` | Minimaler Test |
| Qwen2.5-Coder 7B | 7.6B | ~5.7 GB | `qwen2.5-coder:7b` | **16 GB RAM (PoC)** |
| Qwen2.5-Coder 14B | 14.8B | ~10.5 GB | `qwen2.5-coder:14b` | 32 GB RAM |
| Qwen2.5-Coder 32B | 32.8B | ~21 GB | `qwen2.5-coder:32b` | 64 GB RAM |

### Qwen3.5 (naechste Generation)

Qwen3.5 wird ab Ollama v0.17 unterstuetzt und bietet deutliche Verbesserungen in
Reasoning und Code-Generierung.

| Modell | Parameter | RAM (q4_K_M) | Ollama-Tag | Empfehlung |
|---|---|---|---|---|
| Qwen3.5 9B | ~9B | ~7 GB | `qwen3.5:9b` | 16 GB RAM (knapp) |
| Qwen3.5 27B | ~27B | ~18 GB | `qwen3.5:27b` | 32-64 GB RAM |

**Hinweis:** Qwen3.5-Modelle befinden sich zum Zeitpunkt dieses PoC moeglicherweise noch
in der Einfuehrungsphase. Verfuegbarkeit in Ollama pruefen mit:

```bash
ollama search qwen3.5
```

## Modell fuer diesen PoC: Qwen2.5-Coder 7B

### Warum dieses Modell?

Fuer die aktuelle Hardware (Apple M1, 16 GB RAM) ist `qwen2.5-coder:7b` die optimale
Wahl:

- **RAM:** ~5.7 GB bei 4-Bit-Quantisierung -- laesst genuegend RAM fuer IDE und Tools
- **Qualitaet:** Erreicht auf HumanEval ~80% (vergleichbar mit deutlich groesseren Modellen)
- **Geschwindigkeit:** ~20-30 Tokens/Sekunde auf M1 (fluessig nutzbar)
- **Context Window:** 32.768 Tokens (ausreichend fuer die meisten Dateien)

### Installation

```bash
# Modell herunterladen (~4.7 GB Download)
ollama pull qwen2.5-coder:7b

# Funktionstest
ollama run qwen2.5-coder:7b "Explain the difference between a mutex and a semaphore"
```

### Code-Qualitaet testen

```bash
# Einfacher Code-Test
ollama run qwen2.5-coder:7b "Write a Python function to find the longest common subsequence of two strings. Include type hints and docstring."

# Debugging-Test
ollama run qwen2.5-coder:7b "Find the bug in this code:
def binary_search(arr, target):
    left, right = 0, len(arr)
    while left < right:
        mid = (left + right) / 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1"

# Code-Review-Test
ollama run qwen2.5-coder:7b "Review this code for security issues:
def login(username, password):
    query = f'SELECT * FROM users WHERE name=\"{username}\" AND pass=\"{password}\"'
    return db.execute(query)"
```

## Quantisierung erklaert

Ollama liefert Modelle standardmaessig in 4-Bit-Quantisierung (Q4_K_M). Dies reduziert
den RAM-Bedarf um ca. 75% bei minimalem Qualitaetsverlust.

| Quantisierung | Bits | RAM-Faktor | Qualitaet | Ollama-Suffix |
|---|---|---|---|---|
| FP16 | 16 | 1.0x (Basis) | 100% | `:fp16` |
| Q8_0 | 8 | ~0.5x | ~99% | `:q8_0` |
| Q4_K_M | 4 | ~0.27x | ~95% | (Standard) |
| Q2_K | 2 | ~0.15x | ~85% | `:q2_K` |

Fuer den PoC mit 16 GB RAM ist die Standard-Quantisierung (Q4_K_M) ideal.

```bash
# Standard (Q4_K_M) -- empfohlen
ollama pull qwen2.5-coder:7b

# Hoehere Qualitaet, mehr RAM
ollama pull qwen2.5-coder:7b-instruct-q8_0

# Noch kleiner, weniger Qualitaet (falls RAM knapp)
ollama pull qwen2.5-coder:3b
```

## Modellwechsel bei Hardware-Upgrade

Der Wechsel zu einem groesseren Modell ist ein einziger Befehl. Siehe
[model-switching.md](model-switching.md) fuer die vollstaendige Anleitung.

Kurzversion:

```bash
# Auf 32 GB Maschine: groesseres Modell laden
ollama pull qwen2.5-coder:14b

# In Cline: Settings -> Model -> "qwen2.5-coder:14b"

# In Aider:
aider --model ollama_chat/qwen2.5-coder:14b
```

## Benchmark-Vergleich (Code-Aufgaben)

Qwen2.5-Coder Performance auf gaengigen Benchmarks (Stand 2025):

| Modell | HumanEval | MBPP | LiveCodeBench |
|---|---|---|---|
| Qwen2.5-Coder 7B | ~79% | ~75% | ~22% |
| Qwen2.5-Coder 14B | ~85% | ~80% | ~30% |
| Qwen2.5-Coder 32B | ~90% | ~86% | ~38% |
| GPT-4o (Referenz) | ~90% | ~87% | ~40% |

**Anmerkung:** Lokale Modelle sind Frontier-Modellen qualitativ noch unterlegen -- genau
das ist ein Feature des PoC: Entwickler lernen, KI kritisch einzusetzen.

## Sprachunterstuetzung

Qwen2.5-Coder wurde mit Code in ueber 90 Programmiersprachen trainiert, mit besonderer
Staerke in:

- Python, JavaScript/TypeScript, Java, C/C++, Go, Rust
- SQL, HTML/CSS, Shell/Bash
- Kotlin, Swift, PHP, Ruby

Die Modelle verstehen auch Deutsch, wenn auch Englisch bevorzugt werden sollte fuer
maximale Code-Qualitaet.
