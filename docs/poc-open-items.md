# PoC -- Offene Punkte und fehlende Informationen

> Checkliste der Informationen, die noch benoetigt werden, um das PoC
> und die Confluence-Seite zu vervollstaendigen.

## Muss (Confluence-Seite ist ohne diese unvollstaendig)

| # | Was fehlt | Wer | Status |
|---|---|---|---|
| 1 | **Benchmark-Ergebnisse:** Tokens/sec, RAM-Verbrauch, Time-to-First-Token auf M1 16 GB. Alle `[X]`-Platzhalter in `confluence-wiki.md` muessen mit echten Werten befuellt werden. | Selbst messen | [ ] |
| 2 | **Test-Scores:** Die 10 Aufgaben aus `testing-guide.md` durchfuehren und Scores (1-5) eintragen. Mindestens die 3 Demo-Aufgaben: Security Review, Unit Tests, Multi-File. | Selbst messen | [ ] |
| 3 | **Screenshots:** lsof-Ausgabe, Firewall-Test, Cline verbunden mit Ollama, Aider laeuft, Benchmark-Ausgabe. Confluence-Seite hat `[SCREENSHOT: ...]`-Markierungen. | Selbst erstellen | [ ] |

## Hoch (staerkt das Argument deutlich)

| # | Was fehlt | Wer | Status |
|---|---|---|---|
| 4 | **Trivy-Scan-Ergebnis** fuer `ollama/ollama:0.6.2`. Befehl: `trivy image ollama/ollama:0.6.2`. IT-Security wird danach fragen. | Selbst ausfuehren | [ ] |
| 5 | **GitHub Stars + letzte Aktivitaet** fuer Ollama, Qwen, Cline, Aider. Fuer die Community-Trust-Tabelle in der Confluence-Seite. | Claude abgerufen | [x] |
| 6 | **OpenSSF Scorecard** fuer Ollama. `scorecard --repo=github.com/ollama/ollama` (lokal ausfuehren, API erfordert Auth). | Selbst ausfuehren | [ ] |
| 7 | **Echtes Stueck Legacy-Code** (anonymisiert falls noetig). Fuer Demo 4 (Legacy-Code-Analyse). Ein Java-Service oder aehnliches, das dem lokalen Modell gefuettert werden kann. Dies ist die staerkste Demo (6 Unterstuetzer intern). | Selbst auswaehlen | [ ] |

## SI-intern (nur intern zu finden)

| # | Was fehlt | Wer | Status |
|---|---|---|---|
| 8 | **CoSI API Dev-Key Quota-Details.** Die Doku sagt 60 Req/Min -- gibt es ein monatliches Limit? Nuetzlich fuer die Vergleichstabelle. | CDC / CoSI-Team | [ ] |
| 9 | **OSS-Workflow Link/Template.** Das genaue JIRA-Formular oder die Prozess-Seite fuer die Einreichung von Qwen-Modellen ueber den OSS-Pfad. Referenz: `0.5 Softwareausbau OSS` (noch nicht in Richtlinie aufgenommen). | Softwarebeschaffung | [ ] |
| 10 | **Ziel-Confluence-Space.** In welchem Space soll die Seite publiziert werden? Team-Space, Cloud Board, Coding Assistant Thema? Bestimmt die Sichtbarkeit. | Selbst entscheiden | [ ] |
| 11 | **Spezifische Bedenken von Michael und Oliver.** Liegt der Fokus auf Kosten, Qualitaet, Sicherheit oder Governance? Davon abhaengig wird die Confluence-Seite gewichtet. | Direkt nachfragen | [ ] |
| 12 | **Aktueller Gemini-CLI-Status in der SI.** Bereits im Einsatz? Pilotphase? Beeinflusst die Positionierung als "Ergaenzung". | Intern klaeren | [ ] |

## Nice to have

| # | Was fehlt | Wer | Status |
|---|---|---|---|
| 13 | **Docker-Desktop-Lizenzstatus in der SI.** Ist Docker Desktop freigegeben/verfuegbar? Falls nicht, ist der Docker-Pfad blockiert und die native Installation wird wichtiger. | IT / Softwarebeschaffung | [ ] |
| 14 | **Exakter Qwen-Model-Tag zum Pinnen.** Z.B. `qwen2.5-coder:7b-instruct-q4_K_M` statt nur `qwen2.5-coder:7b`. Fuer praezises Version-Pinning in `versions.lock`. | Selbst testen | [ ] |
| 15 | **Vorhandenes SI-Confluence-Template.** Falls es ein Standard-Layout fuer PoC-Ergebnisse gibt, kann `confluence-wiki.md` angepasst werden. | Intern suchen | [ ] |

## Naechste Schritte

1. Items 1-3 selbst erledigen (Tag 1-2 des Demo-Guide)
2. Items 5-6 kann Claude abrufen -- einfach darum bitten
3. Items 8-12 intern klaeren, bevor die Confluence-Seite finalisiert wird
4. Items 4, 7, 13-15 bei Gelegenheit erledigen
