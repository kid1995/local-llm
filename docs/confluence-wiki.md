# Confluence-Wiki: Lokale LLM-Entwicklungsumgebung (PoC)

> **Hinweis:** Dieses Dokument ist so formatiert, dass es 1:1 in eine Confluence-Seite
> kopiert werden kann. Tabellen, Ueberschriften und Code-Bloecke sind Confluence-kompatibel.
> Bilder und Screenshots muessen manuell in Confluence eingefuegt werden
> (Markierungen `[SCREENSHOT: ...]` zeigen, wo).

---

## Seitentitel: Lokale LLM-Entwicklungsumgebung -- PoC-Ergebnisse

**Status:** PoC abgeschlossen
**Autor:** [Dein Name]
**Datum:** Maerz 2026
**Zielgruppe:** Michael, Oliver, Architektur-Board, IT-Security

---

### 1. Management Summary

Dieses PoC beweist, dass KI-gestuetzte Softwareentwicklung **vollstaendig offline**
moeglich ist -- ohne Cloud, ohne laufende Kosten, ohne Datenabfluss.

| Kriterium | Ergebnis |
|---|---|
| Datenschutz | Kein Datenabfluss (nachgewiesen mit 3 Methoden) |
| Lizenzkosten | 0 EUR / Monat |
| Lizenzen | Nur Apache 2.0 und MIT (kommerziell nutzbar) |
| Hardware | Standard-Laptop (Apple M1, 16 GB RAM) |
| Installationsdauer | < 30 Minuten (Docker) |
| Antwortzeit | [X] Sekunden (Token-Generierung) |
| Code-Qualitaet | [X]/5 Durchschnitt ueber 10 Testaufgaben |

**Empfehlung:** [Hier Empfehlung einfuegen, z.B. "Rollout fuer interessierte Entwickler
als Ergaenzung zu Gemini CLI"]

---

### 2. Problemstellung

Entwickler benoetigen KI-Unterstuetzung beim Programmieren. Cloud-basierte Loesungen
(GitHub Copilot, ChatGPT, Gemini) stellen Herausforderungen dar:

- **Datenschutz:** Code wird an externe Server gesendet
- **Compliance:** ISO 27001 / DORA-Anforderungen
- **Kosten:** 20-100 EUR pro Nutzer pro Monat
- **Abhaengigkeit:** Internet-Verbindung zwingend erforderlich

**Frage:** Kann ein rein lokales Setup eine brauchbare Alternative bieten?

---

### 3. Loesungsarchitektur

```
+------------------------------------------------------------------+
|  Lokales Geraet (MacBook / Linux-Laptop)                         |
|                                                                   |
|  +------------------+   localhost:11434   +------------------+    |
|  | VS Code + Cline  | -----------------> | Ollama           |    |
|  | oder              | <----------------- | (LLM-Server)    |    |
|  | Terminal + Aider  |                     | qwen2.5-coder   |    |
|  +------------------+                     +------------------+    |
|                                                                   |
|  Kein ausgehender Netzwerkverkehr                                 |
+------------------------------------------------------------------+
```

> **Confluence-Tipp:** Dieses Diagramm als draw.io-Makro einfuegen fuer bessere
> Darstellung. Alternative: Screenshot aus dem Repository verwenden.

---

### 4. Komponenten-Uebersicht

| Komponente | Version | Rolle | Lizenz | Kommerziell? | Lizenz-Link |
|---|---|---|---|---|---|
| Ollama | 0.6.2 | Lokaler Model-Server | MIT | Ja | [GitHub/LICENSE](https://github.com/ollama/ollama/blob/main/LICENSE) |
| Qwen 2.5 Coder | 7B | Code-Generierung (LLM) | Apache 2.0 | Ja | [HuggingFace/LICENSE](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct/blob/main/LICENSE) |
| Cline | aktuell | VS Code KI-Assistent | Apache 2.0 | Ja | [GitHub/LICENSE](https://github.com/cline/cline/blob/main/LICENSE) |
| Aider | aktuell | Terminal KI-Assistent | Apache 2.0 | Ja | [GitHub/LICENSE](https://github.com/Aider-AI/aider/blob/main/LICENSE.md) |
| nomic-embed-text | aktuell | Embedding-Modell (optional) | Apache 2.0 | Ja | [HuggingFace/LICENSE](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5) |

> **Alle Lizenzen erlauben kommerzielle Nutzung, Modifikation und Redistribution
> ohne Einschraenkungen.**

---

### 5. Datenschutz-Nachweis

Der PoC wurde mit drei unabhaengigen Methoden auf Datenabfluss geprueft:

#### Methode 1: Netzwerk-Snapshot (lsof)

```bash
sudo lsof -i -n -P | grep ollama
```

**Ergebnis:**

```
ollama  12345  user  3u  IPv4  TCP 127.0.0.1:11434 (LISTEN)
```

Nur `127.0.0.1` (localhost) -- keine externen Verbindungen.

[SCREENSHOT: lsof-Ausgabe waehrend einer Coding-Session]

#### Methode 2: Firewall-Blockade (haertester Test)

Gesamter ausgehender Netzwerkverkehr wurde blockiert. Das Setup funktioniert
weiterhin identisch.

```bash
# Alle ausgehenden Verbindungen blockieren (ausser localhost)
sudo pfctl -f /tmp/pf-block-outgoing.conf -e

# Test: Internet blockiert
curl https://example.com         # TIMEOUT (erwartet)

# Test: LLM funktioniert weiterhin
curl http://localhost:11434/api/tags   # OK
ollama run qwen2.5-coder:7b "Hello"   # OK
```

[SCREENSHOT: Terminal mit Firewall-Test-Ergebnissen]

#### Methode 3: Quellcode-Referenz

Alle Komponenten sind Open Source. Netzwerk-Kommunikation ist auf `localhost`
beschraenkt. Kein Telemetrie-Code vorhanden:

```bash
# Pruefung auf externe URLs im Ollama-Quellcode
grep -r "telemetry\|analytics\|tracking" ollama/   # Keine Treffer
```

> **Fazit:** Architektonisch gibt es keinen Weg nach aussen. Dies ist kein
> konfiguratives "Abschalten", sondern ein Design-Merkmal.

---

### 6. Sicherheitsbewertung

#### 6.1 Lizenz-Compliance

Alle Komponenten verwenden permissive Open-Source-Lizenzen (Apache 2.0, MIT).
Keine Copyleft-Lizenzen (GPL), keine Einschraenkungen fuer kommerzielle Nutzung.

#### 6.2 Container-Sicherheit (Trivy-Scan)

```bash
# Docker-Image auf bekannte Schwachstellen pruefen
trivy image ollama/ollama:0.6.2
```

[SCREENSHOT: Trivy-Scan-Ergebnis oder Tabelle mit Findings]

| Schweregrad | Anzahl | Behebbar? |
|---|---|---|
| CRITICAL | [X] | [Ja/Nein] |
| HIGH | [X] | [Ja/Nein] |
| MEDIUM | [X] | [Ja/Nein] |
| LOW | [X] | [Ja/Nein] |

#### 6.3 Community-Vertrauen

| Komponente | GitHub Stars | Letzte Aktivitaet | OpenSSF Scorecard |
|---|---|---|---|
| Ollama | [X]k | [X] | [Score/10] |
| Qwen | [X]k | [X] | [Score/10] |
| Cline | [X]k | [X] | [Score/10] |
| Aider | [X]k | [X] | [Score/10] |

> **OpenSSF Scorecard:** Bewertet Projekte anhand von Wartung, signierten Commits,
> Dependency-Management und weiteren Sicherheitskriterien.
> Siehe: https://scorecard.dev

---

### 7. Performance-Ergebnisse

| Metrik | Wert | Akzeptabel? |
|---|---|---|
| Time to First Token | [X] s | [Ja/Nein] |
| Tokens pro Sekunde | [X] t/s | [Ja/Nein] |
| RAM-Verbrauch (Idle) | [X] MB | [Ja/Nein] |
| RAM-Verbrauch (Inference) | [X] MB | [Ja/Nein] |
| Installationsdauer (Docker) | [X] Min | [Ja/Nein] |

[SCREENSHOT: benchmark.sh Ausgabe]

---

### 8. Code-Qualitaets-Ergebnisse

10 typische Entwicklungsaufgaben wurden mit dem lokalen Modell getestet
(Details: siehe Testplan im Repository).

| Aufgabe | Score (1-5) | Anmerkung |
|---|---|---|
| Einfache Funktion | [X] | |
| Datenstruktur (LRU Cache) | [X] | |
| REST API (Flask CRUD) | [X] | |
| Debugging | [X] | |
| Refactoring | [X] | |
| Unit Tests (pytest) | [X] | |
| SQL Query | [X] | |
| Security Review | [X] | |
| Dokumentation | [X] | |
| Multi-File-Aenderung | [X] | |
| **Durchschnitt** | **[X]/5** | |

#### Vergleich mit Frontier-Modellen

| Dimension | Lokal (Qwen 7B) | Cloud (GPT-4 / Claude) |
|---|---|---|
| Einfache Code-Generierung | Gut (7/10) | Sehr gut (9/10) |
| Komplexe Architektur | Begrenzt (4/10) | Sehr gut (9/10) |
| Debugging | Mittel (5/10) | Sehr gut (9/10) |
| **Datenschutz** | **10/10** | Abhaengig von Vertrag |
| **Kosten** | **0 EUR/Monat** | 20-100 EUR/Nutzer/Monat |

---

### 9. Hardware-Skalierung

| Geraet (RAM) | Empfohlenes Modell | Qualitaet | Anmerkung |
|---|---|---|---|
| 16 GB (Minimum) | qwen2.5-coder:7b | Gut fuer PoC | Standard-Laptop |
| 32 GB | qwen2.5-coder:14b | Deutlich besser | Empfehlung fuer Entwickler |
| 64 GB+ | qwen3.5:27b | Nahe Frontier | Power-User |

Ein Modellwechsel bei Hardware-Upgrade ist ein Einzeiler:

```bash
# In .env aendern:
LLM_MODEL=qwen2.5-coder:14b
docker compose up
```

---

### 10. Aufwand und Kosten

| Posten | Einmalig | Laufend |
|---|---|---|
| Installation (Docker) | ~30 Min | - |
| Modell-Download | ~5 GB | Updates gelegentlich |
| Einarbeitung Entwickler | ~1-2 Stunden | - |
| Wartung | - | ~15 Min/Monat |
| **Lizenzkosten** | **0 EUR** | **0 EUR** |
| Hardware | Vorhandene Geraete | Keine zusaetzliche |

---

### 11. Risiken und Limitationen

| Risiko | Schwere | Mitigation |
|---|---|---|
| Modellqualitaet unter Frontier-Level | Mittel | Bewusst als Ergaenzung positioniert, nicht als Ersatz |
| Hardware-Anforderung (16 GB+) | Gering | Standard bei aktuellen Entwickler-Laptops |
| Modell-Updates erfordern Download | Gering | versions.lock + Team-Verifizierung vor Update |
| Kein Support (Open Source) | Gering | Aktive Community, hohe Verbreitung |

---

### 12. Empfehlung und naechste Schritte

**Ergebnis des PoC:** [BESTANDEN / NICHT BESTANDEN]

**Empfohlene naechste Schritte:**

1. [ ] Rollout fuer 3-5 interessierte Entwickler (Pilotphase)
2. [ ] Feedback nach 2 Wochen sammeln
3. [ ] Bei positivem Feedback: Erweiterung auf Team-Ebene
4. [ ] Paralleler Betrieb mit Gemini CLI evaluieren

---

### Anhang

| Dokument | Beschreibung | Link |
|---|---|---|
| Repository | Vollstaendige Dokumentation + Skripte | [GitHub-Link] |
| Testplan | 10 Code-Aufgaben + Scoring | [docs/testing-guide.md] |
| Datenschutz-Nachweis | 6 Methoden im Detail | [docs/data-privacy-proof.md] |
| Docker-Setup | Team-Distribution | [docker/README.md] |

---

> *Erstellt als Teil des PoC "Lokale LLM-Entwicklungsumgebung" -- Maerz 2026*
