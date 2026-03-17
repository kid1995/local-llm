# PoC Demo-Guide: Was zeigen, was coden, wie praesentieren

> Anleitung fuer die Live-Demo und Ergebnis-Darstellung im Confluence-Wiki.
> Ziel: In 3 Tagen ein ueberzeugendes PoC mit konkreten Ergebnissen liefern.

## Zeitplan (3 Tage)

| Tag | Fokus | Ergebnis |
|---|---|---|
| Tag 1 | Setup + Code-Tests | Laufendes System, ausgefuellte Test-Tabelle |
| Tag 2 | Datenschutz + Performance + Security | Screenshots, Messwerte, Trivy-Scan |
| Tag 3 | Confluence-Seite + Demo-Vorbereitung | Fertige Wiki-Seite, Demo-Script |

---

## Tag 1: Setup und Code-Generierungs-Tests

### 1.1 Setup dokumentieren (fuer Confluence)

Waehrend der Installation Screenshots machen von:

```bash
# Docker-Start (Screenshot: Terminal-Ausgabe)
cd docker/
cp .env.example .env
docker compose up

# Healthcheck (Screenshot: "PASS"-Meldung)
./healthcheck.sh

# Modell-Test (Screenshot: Erste Antwort)
curl http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Write hello world in Python"}],
    "stream": false
  }'
```

**Screenshot-Checkliste Tag 1:**

```
[ ] Docker compose up -- erfolgreich gestartet
[ ] Healthcheck -- PASS
[ ] Erster API-Call -- Antwort erhalten
[ ] Cline in VS Code -- verbunden mit Ollama
[ ] Aider im Terminal -- verbunden mit Ollama
```

### 1.2 Code-Generierungs-Tests durchfuehren

Die 10 Aufgaben aus `docs/testing-guide.md` durchfuehren. **Fuer jede Aufgabe:**

1. Prompt eingeben (in Cline ODER Aider)
2. Antwort bewerten (1-5 Skala)
3. **Screenshot der besten 3 Ergebnisse** machen (fuer Confluence)

**Empfohlene Demo-Aufgaben (diese 3 zeigen, die anderen nur scoren):**

#### Demo 1: Security Review (Aufgabe 8)

Warum: Zeigt, dass das Modell Sicherheitsluecken erkennt -- hoher Wert fuer
Versicherung/Compliance.

```
Prompt: "Review this code for security vulnerabilities:
[SQL-Injection-Beispiel aus testing-guide.md]"
```

**Was Stakeholder sehen wollen:** Das Modell erkennt SQL Injection, XSS,
Klartext-Passwoerter. Screenshot der Analyse.

#### Demo 2: Unit Tests generieren (Aufgabe 6)

Warum: Zeigt, dass das Modell die Testabdeckung erhoehen kann -- direkte
Produktivitaetssteigerung.

```
Prompt: "Write comprehensive unit tests for this function using pytest:
[parse_csv_row aus testing-guide.md]"
```

**Was Stakeholder sehen wollen:** Generierte Tests sind ausfuehrbar und
decken Edge Cases ab. Screenshot von `pytest`-Ausgabe mit gruenen Tests.

#### Demo 3: Multi-File-Aenderung in Cline (Aufgabe 10)

Warum: Zeigt die IDE-Integration und dass das Modell ueber mehrere Dateien
hinweg arbeiten kann.

```
Prompt: "Add logging to all functions in this module"
```

**Was Stakeholder sehen wollen:** Cline modifiziert mehrere Dateien
gleichzeitig im VS Code. Screenshot der Diff-Ansicht.

---

## Tag 2: Datenschutz, Performance, Sicherheit

### 2.1 Datenschutz-Nachweis (Screenshots sammeln)

Drei Methoden ausfuehren und jeweils einen Screenshot machen:

#### Nachweis 1: lsof (einfachster Beweis)

```bash
# Waehrend einer Coding-Session ausfuehren
sudo lsof -i -n -P | grep ollama
```

[SCREENSHOT: Nur 127.0.0.1 sichtbar]

#### Nachweis 2: Firewall-Blockade (ueberzeugendster Beweis)

```bash
# Firewall aktivieren
cat > /tmp/pf-block-outgoing.conf << 'EOF'
block out all
pass out on lo0 all
pass in on lo0 all
EOF
sudo pfctl -f /tmp/pf-block-outgoing.conf -e

# Beweis: Internet blockiert
curl https://example.com          # TIMEOUT

# Beweis: LLM funktioniert trotzdem
ollama run qwen2.5-coder:7b "Write a function to add two numbers"  # OK

# Aufraumen
sudo pfctl -d
```

[SCREENSHOT: Side-by-side -- curl timeout links, ollama Antwort rechts]

#### Nachweis 3: Docker network=none

```bash
docker run --rm --network=none \
  ollama/ollama:0.6.2 \
  ollama run qwen2.5-coder:7b "Hello"
```

[SCREENSHOT: Funktioniert ohne Netzwerk]

### 2.2 Performance messen

```bash
# Benchmark ausfuehren
./scripts/benchmark.sh
```

**Manuell messen falls Script nicht vorhanden:**

```bash
# Tokens pro Sekunde
curl -s http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Write a quicksort in Python"}],
    "stream": false
  }' | python3 -c "
import sys, json
data = json.load(sys.stdin)
total_ns = data.get('total_duration', 0)
eval_count = data.get('eval_count', 0)
if total_ns > 0 and eval_count > 0:
    tps = eval_count / (total_ns / 1e9)
    print(f'Tokens: {eval_count}')
    print(f'Duration: {total_ns/1e9:.1f}s')
    print(f'Speed: {tps:.1f} tokens/sec')
"

# RAM-Verbrauch
ps aux | grep ollama | awk '{print \$6/1024 \" MB\"}'
```

[SCREENSHOT: Benchmark-Ergebnisse]

**Ergebnis-Tabelle ausfuellen (fuer Confluence):**

```
Time to First Token:   ___ s
Tokens pro Sekunde:    ___ t/s
RAM (Idle):            ___ MB
RAM (Inference):       ___ MB
```

### 2.3 Sicherheits-Scan (Trivy)

Trivy scannt das Docker-Image auf bekannte Schwachstellen (CVEs).
Dies ist der Nachweis, den IT-Security erwarten wird.

```bash
# Trivy installieren
brew install trivy

# Docker-Image scannen
trivy image ollama/ollama:0.6.2

# Nur kritische + hohe Schwachstellen anzeigen
trivy image --severity CRITICAL,HIGH ollama/ollama:0.6.2

# Report als Tabelle (Confluence-freundlich)
trivy image --format table ollama/ollama:0.6.2 > trivy-report.txt
```

[SCREENSHOT: Trivy-Scan-Ergebnis]

### 2.4 OpenSSF Scorecard (optional, hohe Glaubwuerdigkeit)

```bash
# Scorecard installieren
brew install scorecard

# Ollama bewerten
scorecard --repo=github.com/ollama/ollama --format=json

# Oder online pruefen (kein Install noetig):
# https://scorecard.dev/viewer/?uri=github.com/ollama/ollama
```

[SCREENSHOT: Scorecard-Ergebnis fuer Ollama]

---

## Tag 3: Confluence-Seite erstellen und Demo vorbereiten

### 3.1 Confluence-Seite aufbauen

1. Neue Seite erstellen im relevanten Confluence-Space
2. Inhalt aus `docs/confluence-wiki.md` kopieren
3. Platzhalter `[X]` mit den gesammelten Messwerten ersetzen
4. Screenshots an den markierten Stellen einfuegen `[SCREENSHOT: ...]`
5. Architektur-Diagramm als draw.io-Makro einfuegen (oder als Bild)

**Confluence-Formatierungstipps:**

| Markdown | Confluence |
|---|---|
| Code-Block (```) | Makro "Code Block" einfuegen, Sprache waehlen |
| Tabelle | Direkt kompatibel (Ctrl+Shift+T) |
| Blockquote (>) | Info-Panel-Makro oder Hinweis-Makro |
| ASCII-Diagramm | draw.io-Makro oder Screenshot |
| Checkliste | Aufgabenlisten-Makro (Confluence-nativ) |

**Seitenstruktur in Confluence:**

```
Space: [Team/Projekt-Space]
  └── Lokale LLM-Entwicklungsumgebung -- PoC
       ├── Management Summary (oben, sichtbar ohne Scrollen)
       ├── Architektur + Komponenten
       ├── Datenschutz-Nachweis (mit Screenshots)
       ├── Ergebnisse (Performance + Code-Qualitaet)
       └── Empfehlung + naechste Schritte
```

### 3.2 Demo-Script (5-10 Minuten)

Falls eine Live-Demo gewuenscht ist, dieses Script verwenden:

**Minute 1-2: Setup zeigen**

```bash
# "Das gesamte Setup ist ein Dreizeiler"
cd docker/
docker compose up -d
./healthcheck.sh   # Zeigt PASS
```

**Minute 3-5: Code-Generierung live**

```bash
# In VS Code mit Cline: Security-Review-Prompt zeigen
# Oder im Terminal:
ollama run qwen2.5-coder:7b "Review this Flask login for vulnerabilities:

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
    if user: return f'Welcome {username}!'
    return 'Invalid', 401"
```

**Minute 6-7: Datenschutz beweisen**

```bash
# "Schauen wir, was das Netzwerk macht"
sudo lsof -i -n -P | grep ollama
# Zeigen: nur 127.0.0.1
```

**Minute 8-9: Kosten und Vergleich**

Folie/Confluence-Tabelle zeigen:
- Lokal: 0 EUR/Monat, 10/10 Datenschutz
- Cloud: 20-100 EUR/Nutzer/Monat, vertragabhaengig

**Minute 10: Empfehlung**

"Pilotphase mit 3-5 Entwicklern, parallel zu Gemini CLI."

---

## Welche Ergebnisse muessen in Confluence stehen

### Muss (ohne diese ist die Wiki-Seite unvollstaendig)

```
[ ] Management Summary mit Ergebnis-Tabelle
[ ] Architektur-Diagramm
[ ] Lizenz-Tabelle mit Links zu LICENSE-Dateien
[ ] Mindestens 1 Datenschutz-Nachweis mit Screenshot
[ ] Performance-Messwerte (Tokens/sec, RAM)
[ ] Code-Qualitaets-Scores (mindestens 3 Aufgaben)
[ ] Empfehlung und naechste Schritte
```

### Soll (erhoehen die Glaubwuerdigkeit)

```
[ ] Trivy-Scan-Ergebnis
[ ] OpenSSF Scorecard
[ ] Firewall-Blockade-Test (Screenshot)
[ ] Vergleichstabelle Lokal vs. Cloud
[ ] Hardware-Skalierungs-Tabelle
```

### Kann (bei Zeit)

```
[ ] Vollstaendige 10-Aufgaben-Tabelle
[ ] Entwickler-Feedback-Fragebogen
[ ] Detaillierter Trivy-Report als Anhang
[ ] Live-Demo-Recording (Bildschirm-Aufnahme)
```

---

## Tipps fuer die Praesentation

1. **Fuehre mit Datenschutz** -- bei Versicherung ist das der Tueroeffner
2. **Zeige die Firewall-Blockade** -- "Es funktioniert ohne Internet" ist
   der staerkste einzelne Satz
3. **Erwarte die Frage "Wie gut ist es wirklich?"** -- sei ehrlich:
   "70% so gut wie ChatGPT, aber 100% datensicher und 100% kostenlos"
4. **Positioniere als Ergaenzung** -- nicht als Konkurrenz zu Gemini CLI
5. **Betone den Lerneffekt** -- Entwickler lernen, KI kritisch einzusetzen,
   bevor teure Cloud-Tools ausgerollt werden
