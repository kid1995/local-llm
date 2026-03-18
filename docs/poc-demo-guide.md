# PoC Demo-Guide: Was zeigen, was coden, wie praesentieren

> Anleitung fuer die Live-Demo und Ergebnis-Darstellung im Confluence-Wiki.
> Ziel: In 3 Tagen ein ueberzeugendes PoC mit konkreten Ergebnissen liefern.

## Zeitplan (3 Tage)

| Tag | Fokus | Ergebnis |
|---|---|---|
| Tag 1 | Setup + Code-Tests + SI-Use-Cases | Laufendes System, Test-Tabelle, Legacy-Code-Demo |
| Tag 2 | Datenschutz + Performance + Security + Vergleich | Screenshots, Messwerte, CoSI-Vergleich |
| Tag 3 | Confluence-Seite + Demo-Vorbereitung | Fertige Wiki-Seite, Demo-Script mit SI-Kontext |

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

### 1.3 SI-spezifische Use-Cases demonstrieren (Bonus, hoher Impact)

Aus der internen Ideensammlung "KI-gestuetzte Dokumentation" sind die
Anwendungsfaelle 3 und 4 die staerksten Kandidaten fuer den PoC.

#### Demo 4: Legacy-Code-Analyse (Anwendungsfall 3 -- 6 Unterstuetzer)

Warum: Adressiert das Problem der "Kopfmonopole" und Wissensverlusts.
Hoechste Anzahl Unterstuetzer (Marian, Patrick, Oliver, Marc, Maik, Timo).

```bash
# Nimm ein echtes Stueck Legacy-Code (z.B. ein altes Java-Modul)
# und lass das lokale Modell es analysieren:
cat LegacyPaymentService.java | ollama run qwen2.5-coder:7b \
  "Analysiere diesen Code. Erklaere:
   1. Was macht dieser Service?
   2. Welche externen Abhaengigkeiten gibt es?
   3. Welche Geschaeftslogik ist implementiert?
   4. Welche Risiken siehst du bei einer Modernisierung?"
```

**Was Stakeholder sehen wollen:** Das Modell versteht die Geschaeftslogik
und kann sie in verstaendlicher Sprache erklaeren -- **ohne dass der Code
das Geraet verlaesst**.

**Warum besser als CoSI API:** Bei Legacy-Code mit versicherungsspezifischer
Geschaeftslogik ist es ein klarer Vorteil, dass keine Daten an GCP gesendet werden.

#### Demo 5: Automatische Code-Dokumentation (Anwendungsfall 4 -- 5 Unterstuetzer)

```bash
# In Aider: Docstrings automatisch generieren
aider --model ollama_chat/qwen2.5-coder:7b \
  "Fuege zu allen oeffentlichen Methoden in diesem Modul \
   Javadoc-Kommentare hinzu. Beschreibe Parameter, Rueckgabewerte \
   und Geschaeftslogik."
```

**Was Stakeholder sehen wollen:** Bestehender Code bekommt automatisch
Dokumentation -- direkt in der IDE, ohne Copy-Paste in ein externes Tool.

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

### 2.4 SBOM generieren (Software Bill of Materials)

Die SBOM dokumentiert alle Abhaengigkeiten im Docker-Image.
BaFin/DORA erfordern zunehmend diese Transparenz.

```bash
# Trivy installieren (falls noch nicht vorhanden)
brew install trivy

# SBOM im CycloneDX-Format generieren
trivy image --format cyclonedx \
  ollama/ollama:0.6.2 > sbom-ollama-cyclonedx.json

# SBOM auf Schwachstellen pruefen
trivy sbom sbom-ollama-cyclonedx.json

# Statistik ausgeben: Anzahl Komponenten + Lizenzen
cat sbom-ollama-cyclonedx.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
components = data.get('components', [])
print(f'Gesamt-Komponenten: {len(components)}')
licenses = {}
for c in components:
    for l in c.get('licenses', []):
        lid = l.get('license', {}).get('id', 'Unbekannt')
        licenses[lid] = licenses.get(lid, 0) + 1
print('Lizenzen:')
for k, v in sorted(licenses.items(), key=lambda x: -x[1]):
    print(f'  {k}: {v}')
"
```

[SCREENSHOT: SBOM-Statistik -- Anzahl Komponenten und Lizenz-Verteilung]

### 2.5 OpenSSF Scorecard (optional, hohe Glaubwuerdigkeit)

```bash
# Scorecard installieren
brew install scorecard

# Ollama bewerten
scorecard --repo=github.com/ollama/ollama

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

**Minute 8-9: Einordnung in SI-Landschaft**

Confluence-Tabelle zeigen:

```
| Weg          | Qualitaet | Datenschutz | Kosten  | Verfuegbar? |
|--------------|-----------|-------------|---------|-------------|
| CoSI API     | Hoch      | GCP (EU)    | Gering  | Ja (Dev-Key)|
| Vertex AI    | Sehr hoch | GCP (EU)    | Mittel  | Teilweise*  |
| Lokales LLM  | Mittel    | MAXIMAL     | 0 EUR   | Sofort      |

* Anthropic: Einkaufsfreigabe fehlt noch
```

Kernbotschaft: "Das ist kein Entweder-Oder. Fuer Legacy-Code-Analyse
mit vertraulichem Code ist lokal ideal. Fuer komplexe Architektur-Fragen
ist CoSI API besser. Beides ergaenzt sich."

**Minute 10: Empfehlung**

"Pilotphase mit 3-5 Entwicklern, parallel zu CoSI API und Gemini CLI.
Erster Pilot-Use-Case: Legacy-Code-Analyse (6 Unterstuetzer intern).
Nach Google Cloud Next (April) Neubewertung der Cloud-Optionen."

---

## Welche Ergebnisse muessen in Confluence stehen

### Muss (ohne diese ist die Wiki-Seite unvollstaendig)

```
[ ] Management Summary mit Ergebnis-Tabelle
[ ] Einordnung in SI-Landschaft (CoSI API vs. Lokal vs. Vertex AI)
[ ] Architektur-Diagramm (inkl. CoSI-Vergleich)
[ ] Lizenz-Tabelle mit Links zu LICENSE-Dateien
[ ] Mindestens 1 Datenschutz-Nachweis mit Screenshot
[ ] Performance-Messwerte (Tokens/sec, RAM)
[ ] Code-Qualitaets-Scores (mindestens 3 Aufgaben)
[ ] Governance-Vorteil erklaert (OSS-Pfad, keine Cloud-Board-Pruefung)
[ ] Empfehlung und naechste Schritte
```

### Soll (erhoehen die Glaubwuerdigkeit)

```
[ ] Trivy-Scan-Ergebnis
[ ] OpenSSF Scorecard
[ ] Firewall-Blockade-Test (Screenshot)
[ ] Coding-Agents-Vergleichstabelle (Gemini CLI, Claude Code, MistralVibe, OpenCode)
[ ] SI-Use-Case-Demo: Legacy-Code-Analyse (Anwendungsfall 3)
[ ] SI-Use-Case-Demo: Code-Dokumentation (Anwendungsfall 4)
[ ] Hardware-Skalierungs-Tabelle
[ ] Verweis auf HuggingFace-Freigabeprozess als Vorbild
```

### Kann (bei Zeit)

```
[ ] Vollstaendige 10-Aufgaben-Tabelle
[ ] Entwickler-Feedback-Fragebogen
[ ] Detaillierter Trivy-Report als Anhang
[ ] Live-Demo-Recording (Bildschirm-Aufnahme)
[ ] Vertex AI Anthropic Auflagen-Vergleich (zeigt Komplexitaet der Cloud-Alternative)
```

---

## Tipps fuer die Praesentation

1. **Fuehre mit Datenschutz** -- bei Versicherung ist das der Tueroeffner
2. **Zeige die Firewall-Blockade** -- "Es funktioniert ohne Internet" ist
   der staerkste einzelne Satz
3. **Erwarte die Frage "Wie gut ist es wirklich?"** -- sei ehrlich:
   "70% so gut wie Gemini/Claude, aber 100% datensicher und 100% kostenlos"
4. **Positioniere als Ergaenzung** -- nicht als Konkurrenz zu CoSI API oder
   Gemini CLI, sondern als Offline-Fallback und Datenschutz-Maximum
5. **Betone den Lerneffekt** -- Entwickler lernen, KI kritisch einzusetzen,
   bevor teure Cloud-Tools ausgerollt werden
6. **Nutze die interne Ideenliste** -- "6 von euren Kollegen unterstuetzen
   Legacy-Code-Analyse als Use Case -- genau das kann dieses Tool"
7. **Governance-Argument** -- "Kein Softwareausbauprozess, kein Cloud Board,
   kein Einkauf -- OSS-Workflow genuegt, analog zu HuggingFace-Modellen"
8. **Timeline-Argument** -- "Waehrend wir auf die Einkaufsfreigabe fuer
   Anthropic und Klarheit nach Google Cloud Next warten, koennen Entwickler
   mit dem lokalen Setup bereits produktiv arbeiten"
