# SI-Governance-Kontext fuer lokale LLMs

> Wie sich der lokale LLM-Ansatz in die bestehenden SI-Prozesse einordnet
> und welche Governance-Anforderungen er umgeht bzw. erfuellt.

## Softwareausbauprozess -- Einordnung

Jede neue Software-Loesung bei der SI muss durch den Softwareausbauprozess
und die beteiligten Governance-Funktionen freigegeben werden.

### Beteiligte Stellen

| Stelle | Rolle | Relevanz fuer lokales LLM |
|---|---|---|
| Softwarebeschaffung | Operative Betreuung, Quality Gate | Nicht noetig (keine Beschaffung, OSS) |
| Lizenzmanagement | Pruefung Nutzungs-/Lizenzbedingungen | Einfach: nur Apache 2.0 / MIT |
| EAM / EAM Board | Technischer Architekturcheck | Minimal: rein lokale Architektur |
| Informationssicherheit | Risikopruefung | Positiv: kein Datenabfluss moeglich |
| Datenschutz | Pruefung datenschutzrechtlicher Risiken | Positiv: keine externen Daten |
| Cloud Board | Pruefung Cloud-Loesungen | Nicht relevant (keine Cloud) |
| KI-Governance | Einhaltung KI-Regulatorien | Zu klaeren (auch fuer lokale Modelle) |

### Bekannte Rahmenbedingungen

Die SI hat folgende Bedingungen fuer neue Loesungen definiert:

| Bedingung | Cloud-Loesung | Lokales LLM |
|---|---|---|
| Europaeische Server | Muss geprueft werden | Entfaellt (laeuft auf dem Geraet) |
| Keine Daten zum Training | Vertragliche Absicherung noetig | Entfaellt (kein externes Modell) |
| Offizieller Einkauf | Ja | Nein (OSS, kostenlos) |
| Betriebsverantwortung geklaert | Ja | Eigenverantwortung Entwickler |

**Vorteil des lokalen Ansatzes:** Der groesste Teil des Softwareausbauprozesses
entfaellt, da keine Beschaffung, keine Cloud-Dienste und keine externen
Datenverarbeitung involviert sind. Der OSS-Workflow ist der relevante Pfad.

## Vergleich der Zugangswege zu KI-Modellen

Es gibt aktuell drei Wege, KI-Modelle in der SI zu nutzen:

### Weg 1: CoSI API (zentrale Bereitstellung)

Die CoSI API ist ein interner Proxy auf Vertex AI im GCP Model Garden.

- **Modelle:** Gemini Flash, Gemini Pro (weitere folgen)
- **Zugang:** API-Key ueber JIRA-Ticket, 12-Monate-Gueltigkeit
- **Produkte:** Dev-Key (einzelne Entwickler) und Application-Key (Applikationen)
- **Limits:** 60 Requests/Minute pro Key
- **Vorteil:** Offiziell freigegeben, zentral verwaltet
- **Nachteil:** Abhaengig von Internet/VPN, API-Kosten, Key-Rotation

### Weg 2: Vertex AI direkt (Cloud)

Direkte Nutzung von Vertex AI ueber GCP.

- **Modelle:** Gemini, Anthropic (Claude), Mistral
- **Status Anthropic:** Informationssicherheit FREIGEGEBEN, Datenschutz FREIGEGEBEN MIT AUFLAGEN
- **Auflagen:** EU-Endpoints, VPC Service Controls, CMEK, kein Logging, DLP-Filter
- **Nachteil:** Einkaufsfreigabe fuer Anthropic fehlt noch, komplexe Auflagen

### Weg 3: Lokales LLM (dieser PoC)

Vollstaendig lokale Ausfuehrung auf dem Entwickler-Geraet.

- **Modelle:** Qwen 2.5 Coder (Apache 2.0)
- **Zugang:** Kein Key, keine Freigabe, keine Abhaengigkeit
- **Vorteil:** Sofort verfuegbar, 0 Kosten, maximaler Datenschutz
- **Nachteil:** Geringere Modellqualitaet als Frontier-Modelle

### Zusammenfassung

```
                    Qualitaet    Datenschutz    Kosten    Verfuegbarkeit
CoSI API            Hoch         Mittel*        Gering    Sofort (Dev-Key)
Vertex AI direkt    Sehr hoch    Mittel*        Mittel    Eingeschraenkt**
Lokales LLM         Mittel       Maximal        Keine     Sofort
```

\* Daten verlassen das Geraet, aber bleiben in EU/GCP
\** Anthropic: Einkaufsfreigabe ausstehend

## Coding-Agents-Landschaft

| Software | CLI Open Source? | Native Modelle | Auf Vertex AI (EU)? | Freigegeben? | Lokale Modelle | PoC-Grund |
|---|---|---|---|---|---|---|
| **Gemini CLI** | Ja | Gemini | Bis Gemini 2.5 | Ja | Via LiteLLM | Strategische Partnerschaft Google |
| **Claude Code** | Nein | Sonnet/Opus | Sonnet/Opus 4.6 | Nein (Einkauf fehlt) | Via Ollama | Marktfuehrer |
| **MistralVibe** | Ja | Devstral/Codestral | Codestral 2 | Nein | Ja | Europaeischer Anbieter |
| **OpenCode** | Ja | Beliebig | - | - | Ja (Models.dev) | Modellagnostisch |

**Wichtiger Termin:** Google Cloud Next (22.-24. April 2026) -- voraussichtlich
Klarheit ueber EU-Verfuegbarkeit neuer Modelle auf Vertex AI.

### Positionierung des lokalen Ansatzes

Der lokale LLM-Ansatz ist **komplementaer** zu allen drei anderen Optionen:

1. **Zu Gemini CLI:** Lokales Fallback bei Kosten/Quotas, frueherer Start moeglich
2. **Zu Claude Code:** Claude Code kann ueber Ollama auch lokal genutzt werden
   (allerdings ist Claude Code selbst nicht Open Source)
3. **Zu CoSI API:** Lokales LLM benoetigt keinen API-Key, kein VPN, keine Quota

## KI-Dokumentations-Anwendungsfaelle (Relevanz fuer PoC)

Aus der internen Ideensammlung (Patrick Eisenblaetter) sind folgende
Anwendungsfaelle fuer den lokalen PoC besonders relevant:

| # | Anwendungsfall | Unterstuetzer | Horizont | Lokal machbar? |
|---|---|---|---|---|
| 1 | Qualitaets-Check fuer Anforderungen | 5 | Kurzfristig | Ja (Prompt an lokales LLM) |
| 3 | Analyse & Doku von Legacy-Code | 6 | Kurzfristig | **Ja -- idealer PoC-Kandidat** |
| 4 | Autom. Erstellung von Code-Doku | 5 | Kurzfristig | **Ja -- idealer PoC-Kandidat** |
| 5 | Generierung von Release Notes | 2 | Kurzfristig | Ja (Git-Log als Input) |
| 6 | Living Documentation fuer Compliance | 2 | Langfristig | Teilweise (manueller Trigger) |

**Empfehlung:** Im PoC die Anwendungsfaelle 3 und 4 demonstrieren, da sie:
- Die meisten Unterstuetzer haben (6 bzw. 5 Personen)
- Kurzfristig umsetzbar sind
- Direkt mit lokalen Modellen funktionieren
- Das Problem der "Kopfmonopole" adressieren (hohe Sichtbarkeit)

## Hugging-Face-Governance als Vorbild

Die SI hat bereits einen Freigabeprozess fuer Hugging-Face-Modelle etabliert:

1. Einzelpruefung durch Lizenzmanagement pro Modell
2. Dokumentation auf Wiki-Seite inkl. Lizenz
3. Freigabe durch PO des Technologie-Streams

**Fuer lokale LLMs anwendbar:** Der gleiche Prozess kann fuer Qwen-Modelle
genutzt werden. Apache 2.0 ist bereits bei mehreren HF-Modellen freigegeben
(z.B. jina-embeddings-v2-base-de, sentence-transformers/sentence-t5-xl).

## Handlungsempfehlung fuer den PoC

1. **OSS-Workflow nutzen:** Qwen-Modelle ueber den OSS-Pfad im
   Softwareausbauprozess anmelden (Apache 2.0, analog zu HF-Modellen)
2. **KI-Governance informieren:** Auch lokale Modelle unterliegen KI-Regulatorien
3. **Komplementaer positionieren:** Nicht als Alternative zu CoSI/Gemini CLI,
   sondern als Ergaenzung (Offline, 0 Kosten, maximaler Datenschutz)
4. **Use Cases 3+4 demonstrieren:** Legacy-Code-Analyse und Code-Doku sind
   die ueberzeugendsten Demo-Szenarien fuer Stakeholder
