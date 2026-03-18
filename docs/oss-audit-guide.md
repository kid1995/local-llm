# OSS-Audit-Leitfaden fuer die SI

> Systematische Pruefung von Open-Source-Software fuer den Einsatz
> in einer regulierten Versicherungsumgebung (ISO 27001, DORA, BaFin).
> Dieser Leitfaden ist als wiederverwendbare Vorlage fuer zukuenftige
> OSS-Evaluierungen konzipiert.

## 1. Ueberblick: Audit-Dimensionen

Jede OSS-Komponente muss in fuenf Dimensionen geprueft werden:

```
+------------------------------------------------------------------+
|                     OSS-Audit-Framework                           |
|                                                                   |
|  1. Lizenz-Compliance     "Duerfen wir das nutzen?"               |
|  2. Sicherheits-Scan      "Ist es sicher?"                        |
|  3. Community-Vertrauen    "Wird es gepflegt?"                     |
|  4. Datenschutz-Nachweis   "Verlassen Daten das Geraet?"           |
|  5. SBOM-Dokumentation     "Was steckt drin?"                      |
+------------------------------------------------------------------+
```

---

## 2. Dimension 1: Lizenz-Compliance

### 2.1 Erlaubte Lizenzen in der SI

| Lizenztyp | Kommerziell nutzbar? | Redistribution? | SI-Status |
|---|---|---|---|
| MIT | Ja | Ja | Freigegeben |
| Apache 2.0 | Ja | Ja | Freigegeben |
| BSD 2-Clause / 3-Clause | Ja | Ja | Freigegeben |
| ISC | Ja | Ja | Freigegeben |
| GPL v2/v3 | Eingeschraenkt | Copyleft-Pflicht | Einzelpruefung |
| LGPL | Eingeschraenkt | Schwaches Copyleft | Einzelpruefung |
| AGPL | Nein | Netzwerk-Copyleft | Abgelehnt |
| CC-BY-NC | Nein | Nicht-kommerziell | Abgelehnt |
| Proprietaer / Custom | Einzelpruefung | Abhaengig von Bedingungen | Einzelpruefung |

### 2.2 Lizenz-Pruefung durchfuehren

```bash
# Methode 1: Manuell -- LICENSE-Datei im Repository pruefen
# Immer die LICENSE-Datei im Root des Repositories pruefen,
# NICHT die Homepage oder Marketing-Seite.

# Methode 2: Trivy License-Scan (automatisiert)
trivy image --scanners license ollama/ollama:0.6.2

# Methode 3: Scancode-Toolkit (tiefgehend, auch Dateien im Code)
pip install scancode-toolkit
scancode --license --json-pp license-report.json /path/to/source
```

### 2.3 Lizenz-Transparenz-Tabelle (Template)

| Komponente | Version | Lizenz | Kommerziell? | LICENSE-Link | Geprueft am |
|---|---|---|---|---|---|
| [Name] | [Version] | [SPDX-ID] | [Ja/Nein] | [Link zu LICENSE im Repo] | [Datum] |

**Fuer diesen PoC:**

| Komponente | Version | Lizenz | Kommerziell? | LICENSE-Link | Geprueft am |
|---|---|---|---|---|---|
| Ollama | 0.6.2 | MIT | Ja | [GitHub](https://github.com/ollama/ollama/blob/main/LICENSE) | 2026-03-18 |
| Qwen 2.5 Coder | 7B | Apache 2.0 | Ja | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct/blob/main/LICENSE) | 2026-03-18 |
| Cline | aktuell | Apache 2.0 | Ja | [GitHub](https://github.com/cline/cline/blob/main/LICENSE) | 2026-03-18 |
| Aider | aktuell | Apache 2.0 | Ja | [GitHub](https://github.com/Aider-AI/aider/blob/main/LICENSE.md) | 2026-03-18 |
| nomic-embed-text | aktuell | Apache 2.0 | Ja | [HuggingFace](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5) | 2026-03-18 |

> **Hinweis:** Fuer HuggingFace-Modelle muss die Lizenz in der Model Card
> UND in der LICENSE-Datei uebereinstimmen. Bei Abweichungen gilt die
> restriktivere Lizenz.

---

## 3. Dimension 2: Sicherheits-Scan

### 3.1 Container-Schwachstellen (Trivy)

Trivy ist ein Open-Source-Scanner (Apache 2.0) fuer Container, Dateisysteme
und Code-Repositories. Er prueft gegen die NVD (National Vulnerability Database).

```bash
# Installation
brew install trivy

# Basis-Scan: Alle Schwachstellen
trivy image ollama/ollama:0.6.2

# Nur kritische und hohe Schwachstellen
trivy image --severity CRITICAL,HIGH ollama/ollama:0.6.2

# Ausfuehrlicher Report als Tabelle
trivy image --format table ollama/ollama:0.6.2 > trivy-report.txt

# JSON-Report fuer automatische Verarbeitung
trivy image --format json ollama/ollama:0.6.2 > trivy-report.json
```

### 3.2 Ergebnis-Template

| Schweregrad | Anzahl | Behebbar? | Akzeptabel? |
|---|---|---|---|
| CRITICAL | [X] | [Ja/Nein] | [Ja/Nein -- Begruendung] |
| HIGH | [X] | [Ja/Nein] | [Ja/Nein -- Begruendung] |
| MEDIUM | [X] | [Ja/Nein] | [Ja/Nein] |
| LOW | [X] | [Ja/Nein] | [Ja/Nein] |

### 3.3 Quellcode-Sicherheit (Statische Analyse)

Fuer tiefere Pruefung des Quellcodes:

```bash
# Go-Projekte (Ollama ist in Go geschrieben)
# gosec: Findet Sicherheitsprobleme in Go-Code
go install github.com/securego/gosec/v2/cmd/gosec@latest
git clone https://github.com/ollama/ollama.git
cd ollama && gosec ./...

# Python-Projekte (Aider ist in Python geschrieben)
pip install bandit
git clone https://github.com/Aider-AI/aider.git
cd aider && bandit -r aider/ -f json -o bandit-report.json

# Dependency-Check (bekannte CVEs in Abhaengigkeiten)
# Go:
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Python:
pip install pip-audit
pip-audit
```

### 3.4 OSV-Scanner (Google Open Source Vulnerabilities)

```bash
# Installation
brew install osv-scanner

# Scan eines Repositories
osv-scanner --recursive /path/to/repo

# Scan einer SBOM-Datei
osv-scanner --sbom sbom-ollama.json
```

---

## 4. Dimension 3: Community-Vertrauen

### 4.1 GitHub-Metriken (Stand 2026-03-18)

| Komponente | Stars | Forks | Offene Issues | Letzte Aktivitaet | Lizenz |
|---|---|---|---|---|---|
| Ollama | 165.400+ | 15.000+ | 2.677 | 2026-03-18 (heute) | MIT |
| Cline | 59.100+ | 5.983 | 803 | 2026-03-18 (heute) | Apache 2.0 |
| Aider | 42.100+ | 4.043 | 1.441 | 2026-03-17 (gestern) | Apache 2.0 |
| Qwen 2.5 Coder | 16.000+ | 1.140 | 117 | 2026-02-03 | Apache 2.0 |

### 4.2 Bewertungskriterien

| Kriterium | Gut | Risiko | Ollama | Cline | Aider | Qwen |
|---|---|---|---|---|---|---|
| Stars | > 10.000 | < 1.000 | 165k | 59k | 42k | 16k |
| Letzte Aktivitaet | < 7 Tage | > 90 Tage | Heute | Heute | Gestern | 6 Wochen |
| Forks/Stars Ratio | > 5% | < 1% | 9% | 10% | 10% | 7% |
| Offene Issues Ratio | < 5% | > 20% | 1.6% | 1.4% | 3.4% | 0.7% |
| SECURITY.md vorhanden | Ja | Nein | Ja | Ja | Ja | Ja |
| CONTRIBUTING.md | Ja | Nein | Ja | Ja | Ja | Ja |

> **Bewertung:** Alle vier Komponenten zeigen Zeichen eines gesunden,
> aktiv gepflegten Open-Source-Projekts mit starker Community.

### 4.3 OpenSSF Scorecard

Der OpenSSF Scorecard bewertet Projekte auf einer Skala von 0-10 anhand von:
- Code-Review-Praktiken
- Branch-Protection
- CI/CD-Tests
- Signierte Releases
- Dependency-Updates
- Vulnerability-Disclosure

```bash
# Installation
brew install scorecard

# Scorecard fuer Ollama abrufen
scorecard --repo=github.com/ollama/ollama

# Oder online pruefen (kein Install noetig):
# https://scorecard.dev/viewer/?uri=github.com/ollama/ollama
```

**Ergebnis-Template:**

| Komponente | Gesamt-Score | Code-Review | Maintained | Vulnerabilities | Branch-Protection |
|---|---|---|---|---|---|
| Ollama | [X]/10 | [X]/10 | [X]/10 | [X]/10 | [X]/10 |
| Cline | [X]/10 | [X]/10 | [X]/10 | [X]/10 | [X]/10 |
| Aider | [X]/10 | [X]/10 | [X]/10 | [X]/10 | [X]/10 |

> **Hinweis:** Die Scores muessen lokal abgerufen werden, da die
> Scorecard-API Authentifizierung erfordert. Befehl oben verwenden.

---

## 5. Dimension 4: Datenschutz-Nachweis

Fuer die vollstaendige Anleitung siehe [data-privacy-proof.md](data-privacy-proof.md).

### Kurzfassung fuer den Audit

| Methode | Befehl | Erwartetes Ergebnis |
|---|---|---|
| Netzwerk-Snapshot | `sudo lsof -i -n -P \| grep ollama` | Nur `127.0.0.1:11434` |
| Firewall-Blockade | `sudo pfctl -f block-rules -e` | Setup funktioniert ohne Internet |
| DNS-Analyse | `sudo tcpdump -i any port 53` | Keine DNS-Anfragen von Ollama |
| Quellcode-Audit | `grep -r "telemetry" ollama/` | Keine Treffer |

---

## 6. Dimension 5: SBOM (Software Bill of Materials)

### 6.1 Was ist eine SBOM?

Eine SBOM ist ein maschinenlesbares Inventar aller Software-Komponenten,
die in einem Produkt enthalten sind. Sie ist vergleichbar mit einer
Zutatenliste auf Lebensmitteln.

**Standards:**
- **CycloneDX** (OWASP) -- empfohlen fuer Container/Applikationen
- **SPDX** (ISO/IEC 5962) -- empfohlen fuer Lizenz-Compliance

**Warum relevant fuer die SI:**
- BaFin/DORA erfordern zunehmend Software-Transparenz
- Schnelle Reaktion bei neuen CVEs ("Ist Komponente X betroffen?")
- Nachweis fuer Audits: "Was genau laeuft in der Umgebung?"

### 6.2 SBOM generieren mit Trivy

```bash
# CycloneDX-Format (empfohlen fuer Schwachstellen-Tracking)
trivy image --format cyclonedx \
  ollama/ollama:0.6.2 > sbom-ollama-cyclonedx.json

# SPDX-Format (empfohlen fuer Lizenz-Compliance)
trivy image --format spdx-json \
  ollama/ollama:0.6.2 > sbom-ollama-spdx.json

# CycloneDX mit Schwachstellen-Informationen
trivy image --format cyclonedx --scanners vuln \
  ollama/ollama:0.6.2 > sbom-ollama-with-vulns.json
```

### 6.3 SBOM generieren mit Syft (Alternative)

```bash
# Installation
brew install syft

# CycloneDX-Format
syft ollama/ollama:0.6.2 -o cyclonedx-json > sbom-syft-cyclonedx.json

# SPDX-Format
syft ollama/ollama:0.6.2 -o spdx-json > sbom-syft-spdx.json

# Tabellen-Ausgabe (menschenlesbar)
syft ollama/ollama:0.6.2 -o table
```

### 6.4 SBOM validieren und analysieren

```bash
# SBOM auf bekannte Schwachstellen pruefen
# (nutzt die generierte SBOM als Input)
trivy sbom sbom-ollama-cyclonedx.json

# Oder mit OSV-Scanner
osv-scanner --sbom sbom-ollama-cyclonedx.json

# Statistik: Wie viele Komponenten sind enthalten?
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

### 6.5 SBOM-Ergebnis-Template

| Metrik | Wert |
|---|---|
| Gesamt-Komponenten | [X] |
| Davon mit bekannter Lizenz | [X] |
| Davon mit Schwachstellen | [X] |
| CRITICAL CVEs | [X] |
| Format | CycloneDX / SPDX |
| Generiert am | [Datum] |
| Tool | Trivy [Version] / Syft [Version] |

---

## 7. Audit-Zusammenfassung (Template)

### Komponente: [Name]

| Dimension | Ergebnis | Status |
|---|---|---|
| **Lizenz** | [SPDX-ID], kommerziell nutzbar | BESTANDEN / NICHT BESTANDEN |
| **Sicherheit (Trivy)** | [X] CRITICAL, [X] HIGH | BESTANDEN / NICHT BESTANDEN |
| **Community** | [X]k Stars, aktiv gepflegt | BESTANDEN / NICHT BESTANDEN |
| **Datenschutz** | Nur localhost-Kommunikation | BESTANDEN / NICHT BESTANDEN |
| **SBOM** | [X] Komponenten dokumentiert | BESTANDEN / NICHT BESTANDEN |

**Gesamtbewertung:** FREIGABE / FREIGABE MIT AUFLAGEN / NICHT FREIGEGEBEN

---

## 8. Wiederverwendbare Audit-Checkliste

Diese Checkliste kann fuer jede zukuenftige OSS-Evaluierung in der SI
verwendet werden:

```
Lizenz-Compliance:
[ ] LICENSE-Datei im Repository geprueft
[ ] Lizenz ist Apache 2.0, MIT oder BSD (kein Copyleft)
[ ] Lizenz erlaubt kommerzielle Nutzung
[ ] Lizenz erlaubt Redistribution (relevant fuer Docker)
[ ] Lizenzmanagement informiert (E-Mail an dv-Anforderungen)

Sicherheits-Scan:
[ ] Trivy-Scan durchgefuehrt (Container oder Repository)
[ ] Keine unbehobenen CRITICAL-Schwachstellen
[ ] HIGH-Schwachstellen dokumentiert und bewertet
[ ] Statische Analyse (gosec/bandit) bei Bedarf

Community-Vertrauen:
[ ] > 1.000 GitHub Stars
[ ] Letzte Aktivitaet < 90 Tage
[ ] SECURITY.md vorhanden
[ ] Keine bekannten unbehandelten Sicherheitsvorfaelle
[ ] OpenSSF Scorecard >= 5/10 (falls verfuegbar)

Datenschutz:
[ ] Netzwerk-Analyse: nur localhost-Verbindungen
[ ] Keine Telemetrie im Quellcode
[ ] Funktioniert offline (Firewall-Test)

SBOM:
[ ] CycloneDX oder SPDX generiert
[ ] Keine unbekannten Lizenzen in Abhaengigkeiten
[ ] SBOM archiviert mit Release-Artefakten

Governance:
[ ] OSS-Workflow im Softwareausbauprozess gestartet
[ ] KI-Governance informiert (bei LLM-Komponenten)
[ ] Dokumentation auf Wiki-Seite (analog HuggingFace-Prozess)
```

---

## 9. Werkzeug-Uebersicht

| Werkzeug | Zweck | Lizenz | Installation |
|---|---|---|---|
| **Trivy** | CVE-Scan, License-Scan, SBOM | Apache 2.0 | `brew install trivy` |
| **Syft** | SBOM-Generierung | Apache 2.0 | `brew install syft` |
| **OSV-Scanner** | Schwachstellen-DB (Google) | Apache 2.0 | `brew install osv-scanner` |
| **Scorecard** | OpenSSF Projekt-Bewertung | Apache 2.0 | `brew install scorecard` |
| **Scancode-toolkit** | Tiefe Lizenz-Erkennung | Apache 2.0 | `pip install scancode-toolkit` |
| **gosec** | Go-Quellcode-Sicherheit | Apache 2.0 | `go install github.com/securego/gosec/...` |
| **bandit** | Python-Quellcode-Sicherheit | Apache 2.0 | `pip install bandit` |
| **pip-audit** | Python-Dependency-CVEs | Apache 2.0 | `pip install pip-audit` |
| **govulncheck** | Go-Dependency-CVEs | BSD | `go install golang.org/x/vuln/cmd/govulncheck` |

> **Alle Werkzeuge sind Open Source (Apache 2.0 oder BSD) und laufen lokal.**
> Kein Cloud-Dienst erforderlich.

---

## 10. Referenzen

- [OpenSSF Scorecard](https://scorecard.dev) -- Projekt-Sicherheitsbewertung
- [Trivy Dokumentation](https://trivy.dev/docs/latest/) -- Scanner-Dokumentation
- [CycloneDX Spezifikation](https://cyclonedx.org/) -- SBOM-Standard
- [SPDX Spezifikation](https://spdx.dev/) -- Lizenz-Dokumentations-Standard
- [OpenChain (ISO 5230)](https://www.openchainproject.org/) -- OSS-Compliance-Standard
- [CISA SBOM](https://www.cisa.gov/sbom) -- US-Regierungs-Empfehlungen zu SBOMs
- [DORA (EU)](https://www.digital-operational-resilience-act.com/) -- EU-Regulierung fuer Finanzsektor
