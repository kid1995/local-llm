# PoC-Testplan und Evaluierung

> Systematische Bewertung des lokalen LLM-Stacks nach Aufwand/Nutzen

## Testziele

1. **Funktionalitaet:** Funktioniert das Setup fuer typische Entwicklungsaufgaben?
2. **Qualitaet:** Wie gut ist die Code-Generierung im Vergleich zu Frontier-Modellen?
3. **Performance:** Sind die Antwortzeiten akzeptabel?
4. **Usability:** Ist das Setup fuer Entwickler im Alltag nutzbar?
5. **Datenschutz:** Ist nachweisbar, dass keine Daten abfliessen?

## Phase 1: Installations-Test (Tag 1)

### Checkliste

```
[ ] Ollama installiert und gestartet
[ ] Modell heruntergeladen (qwen2.5-coder:7b)
[ ] Embedding-Modell heruntergeladen (nomic-embed-text)
[ ] Cline installiert und mit Ollama verbunden
[ ] Aider installiert und mit Ollama konfiguriert
[ ] Erster Prompt erfolgreich beantwortet (in Cline)
[ ] Erster Prompt erfolgreich beantwortet (in Aider)
```

### Metriken erfassen

```bash
# Installationsdauer messen
time brew install ollama
time ollama pull qwen2.5-coder:7b
time pip install aider-chat

# Speicherplatz dokumentieren
du -sh ~/.ollama/models
```

**Zu dokumentieren:**
- Gesamte Installationsdauer (Start bis erster Prompt)
- Download-Groessen
- Besondere Probleme oder Abhaengigkeiten

## Phase 2: Code-Generierungs-Tests (Tag 1-2)

### Test-Suite: 10 typische Aufgaben

Jede Aufgabe in Cline UND Aider durchfuehren. Ergebnis bewerten auf einer Skala
von 1-5 (1=unbrauchbar, 5=produktionsreif).

#### Aufgabe 1: Einfache Funktion

```
Prompt: "Write a Python function that validates an email address using regex.
Include type hints and a docstring."
```

Bewertungskriterien:
- Korrektheit der Regex
- Type Hints vorhanden
- Docstring vorhanden
- Edge Cases behandelt

#### Aufgabe 2: Datenstruktur

```
Prompt: "Implement a thread-safe LRU cache in Python with a maximum size of N items.
Use only standard library modules."
```

Bewertungskriterien:
- Thread-Safety (Lock/RLock verwendet)
- LRU-Logik korrekt
- Performance (O(1) fuer get/put)

#### Aufgabe 3: REST API

```
Prompt: "Create a Flask REST API with endpoints for CRUD operations on a 'Task' entity.
Include input validation and proper error handling."
```

Bewertungskriterien:
- Alle CRUD-Endpunkte vorhanden
- Input-Validation
- Fehlerbehandlung mit korrekten HTTP-Status-Codes

#### Aufgabe 4: Debugging

```
Prompt: "Find and fix all bugs in this code:

def merge_sorted_lists(list1, list2):
    result = []
    i = j = 0
    while i < len(list1) and j < len(list2):
        if list1[i] <= list2[j]:
            result.append(list1[i])
            i += 1
        else:
            result.append(list2[j])
            j += 1
    return result"
```

Bewertungskriterien:
- Erkennt den fehlenden Rest-Anhang
- Korrekte Loesung
- Erklaerung des Bugs

#### Aufgabe 5: Refactoring

```
Prompt: "Refactor this code to use immutable patterns and reduce complexity:

class UserService:
    def __init__(self):
        self.users = {}
        self.next_id = 1

    def create_user(self, name, email):
        user = {'id': self.next_id, 'name': name, 'email': email, 'active': True}
        self.users[self.next_id] = user
        self.next_id += 1
        return user

    def deactivate_user(self, user_id):
        if user_id in self.users:
            self.users[user_id]['active'] = False
            return True
        return False"
```

Bewertungskriterien:
- Immutability umgesetzt
- Funktionalitaet erhalten
- Code-Qualitaet verbessert

#### Aufgabe 6: Unit Tests

```
Prompt: "Write comprehensive unit tests for this function using pytest:

def parse_csv_row(row: str, delimiter: str = ',') -> list[str]:
    fields = []
    current = ''
    in_quotes = False
    for char in row:
        if char == '\"':
            in_quotes = not in_quotes
        elif char == delimiter and not in_quotes:
            fields.append(current.strip())
            current = ''
        else:
            current += char
    fields.append(current.strip())
    return fields"
```

Bewertungskriterien:
- Edge Cases abgedeckt (leere Strings, Quotes, Delimiter in Quotes)
- Pytest-Konventionen eingehalten
- Tests sind isoliert und ausfuehrbar

#### Aufgabe 7: SQL Query

```
Prompt: "Write a PostgreSQL query that finds the top 5 customers by total order value
in the last 30 days, including their order count and average order value.
Tables: customers(id, name, email), orders(id, customer_id, total, created_at)"
```

#### Aufgabe 8: Security Review

```
Prompt: "Review this code for security vulnerabilities:

from flask import Flask, request
import sqlite3

app = Flask(__name__)

@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    conn = sqlite3.connect('users.db')
    cursor = conn.execute(
        f\"SELECT * FROM users WHERE username='{username}' AND password='{password}'\"
    )
    user = cursor.fetchone()
    if user:
        return f'Welcome {username}!'
    return 'Invalid credentials', 401"
```

Bewertungskriterien:
- SQL Injection erkannt
- XSS erkannt
- Klartext-Passwort erkannt
- CSRF fehlt
- Korrekte Fixes vorgeschlagen

#### Aufgabe 9: Dokumentation

```
Prompt: "Generate API documentation for this module including usage examples:
[Eigenes Modul aus aktuellem Projekt einfuegen]"
```

#### Aufgabe 10: Multi-File-Aenderung (nur Aider/Cline)

```
Prompt: "Add logging to all functions in src/services/ using the standard logging module.
Use the function name as the logger name."
```

### Ergebnis-Template

| Aufgabe | Cline Score | Aider Score | Anmerkungen |
|---|---|---|---|
| 1. Einfache Funktion | /5 | /5 | |
| 2. Datenstruktur | /5 | /5 | |
| 3. REST API | /5 | /5 | |
| 4. Debugging | /5 | /5 | |
| 5. Refactoring | /5 | /5 | |
| 6. Unit Tests | /5 | /5 | |
| 7. SQL Query | /5 | /5 | |
| 8. Security Review | /5 | /5 | |
| 9. Dokumentation | /5 | /5 | |
| 10. Multi-File | /5 | /5 | |
| **Durchschnitt** | **/5** | **/5** | |

## Phase 3: Performance-Tests (Tag 2)

### Antwortzeit messen

```bash
# Script: Antwortzeit messen
# Siehe scripts/benchmark.sh

# Einfacher Benchmark
time curl -s http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Write a Python hello world"}],
    "stream": false
  }' > /dev/null

# Tokens pro Sekunde messen
curl -s http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Write a Python function to sort a list using quicksort"}],
    "stream": false
  }' | python3 -c "
import sys, json
data = json.load(sys.stdin)
total_ns = data.get('total_duration', 0)
eval_count = data.get('eval_count', 0)
if total_ns > 0 and eval_count > 0:
    tokens_per_sec = eval_count / (total_ns / 1e9)
    print(f'Tokens: {eval_count}')
    print(f'Duration: {total_ns/1e9:.1f}s')
    print(f'Speed: {tokens_per_sec:.1f} tokens/sec')
"
```

### RAM-Verbrauch dokumentieren

```bash
# Waehrend einer Coding-Session:
# 1. Nur Ollama
ps aux | grep ollama | awk '{print $6/1024 " MB"}'

# 2. Ollama + VS Code + Cline
# (manuell aus Activity Monitor ablesen)

# 3. System-Gesamtverbrauch
vm_stat | head -5
```

### Ergebnis-Template

| Metrik | Wert |
|---|---|
| Time to First Token | s |
| Tokens pro Sekunde | t/s |
| RAM: Ollama Idle | MB |
| RAM: Ollama + Inference | MB |
| RAM: Gesamt (System) | GB |

## Phase 4: Datenschutz-Nachweis (Tag 2-3)

Siehe [data-privacy-proof.md](data-privacy-proof.md) fuer die vollstaendige Anleitung.

### Minimaler Nachweis fuer den PoC

```
[ ] Firewall-Test bestanden (Setup funktioniert offline)
[ ] lsof/netstat zeigt nur localhost-Verbindungen
[ ] Quellcode-Referenzen dokumentiert (Open Source)
```

## Phase 5: Usability-Bewertung (Tag 3-5)

### Entwickler-Feedback (nach 2-3 Tagen Nutzung)

Fragebogen (1-5 Skala):

1. Wie einfach war die Installation? (1=sehr schwierig, 5=trivial)
2. Wie nuetzlich ist die Code-Generierung fuer Ihre taegliche Arbeit?
3. Sind die Antwortzeiten akzeptabel?
4. Wuerden Sie das Tool weiterhin nutzen?
5. Wie bewerten Sie die Qualitaet der generierten Code-Vorschlaege?
6. Fuer welche Aufgaben ist das Tool am nuetzlichsten?
7. Wo liegen die groessten Einschraenkungen?

### Vergleich mit Frontier-Modellen

| Dimension | Lokal (Qwen 7B) | Frontier (GPT-4/Claude) |
|---|---|---|
| Einfache Code-Gen | Gut (7/10) | Sehr gut (9/10) |
| Komplexe Architektur | Begrenzt (4/10) | Sehr gut (9/10) |
| Debugging | Mittel (5/10) | Sehr gut (9/10) |
| Antwortzeit | 2-5s (lokal) | 1-3s (Cloud) |
| Datenschutz | 10/10 | Abhaengig von Vertrag |
| Kosten | 0 EUR/Monat | 20-100 EUR/Nutzer/Monat |

## Aufwand/Nutzen-Bewertung

### Aufwand

| Posten | Einmalig | Laufend |
|---|---|---|
| Installation pro Geraet | ~30 Minuten | - |
| Modell-Download | ~5 GB | Updates gelegentlich |
| Einarbeitung Entwickler | ~1-2 Stunden | - |
| Wartung/Updates | - | ~15 Min/Monat |
| Lizenzkosten | 0 EUR | 0 EUR |
| Hardware-Anforderung | Vorhandene Geraete | Keine zusaetzliche |

### Nutzen

| Nutzen | Bewertung |
|---|---|
| KI-Erfahrung fuer Entwickler | Hoch |
| Vorbereitung auf Gemini CLI | Hoch |
| Datenschutz-Konformitaet | Sehr hoch |
| Code-Qualitaets-Verbesserung | Mittel |
| Produktivitaetssteigerung | Mittel (lokal) vs. Hoch (Frontier) |
| Kostenersparnis gegenueber Cloud-Tools | Hoch |

## PoC-Erfolgskriterien

Der PoC gilt als erfolgreich, wenn:

1. **Installation** in unter 1 Stunde abgeschlossen
2. **Code-Generierung** durchschnittlich >= 3/5 in der Test-Suite
3. **Antwortzeiten** unter 10 Sekunden fuer typische Prompts
4. **Datenschutz** nachweisbar (Firewall-Test bestanden)
5. **Entwickler-Feedback** durchschnittlich >= 3/5
