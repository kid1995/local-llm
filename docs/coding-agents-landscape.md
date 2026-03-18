# Coding-Agents-Landschaft -- Vergleich und Einordnung

> Ueberblick ueber die verfuegbaren KI-Coding-Assistenten,
> ihre Verfuegbarkeit in der SI und die Rolle des lokalen Ansatzes.

## Vergleichstabelle

| Kriterium | Gemini CLI | Claude Code | MistralVibe | OpenCode | **Lokal (Ollama)** |
|---|---|---|---|---|---|
| **Open Source (CLI)** | Ja | Nein | Ja | Ja | Ja (alle Komponenten) |
| **Native Modelle** | Gemini | Sonnet, Opus | Devstral, Codestral | Beliebig | Qwen, Codestral, etc. |
| **Vertex AI (EU)?** | Bis Gemini 2.5 | Sonnet/Opus 4.6 | Codestral 2 | - | - |
| **SI-Freigabe?** | Ja | Nein (Einkauf fehlt) | Nein | - | OSS-Pfad moeglich |
| **Lokale Modelle?** | Via LiteLLM | Via Ollama | Ja | Ja | **Nativ** |
| **Kosten** | API-basiert | API-basiert | API-basiert | Keine | **Keine** |
| **Datenschutz** | Cloud (EU) | Cloud (EU) | Cloud | Cloud | **Maximal (lokal)** |
| **PoC-Grund** | Strategische Partnerschaft | Marktfuehrer | EU-Anbieter | Modellagnostisch | **Offline + kostenlos** |

## Zugangs-Architektur in der SI

```
+-------------------------------------------------------------------+
|                      SI-Infrastruktur                              |
|                                                                    |
|  Weg 1: CoSI API (zentral)                                        |
|  +----------+    VPN    +-----------+    GCP    +---------------+  |
|  | Entwickler| -------> | CoSI Proxy| -------> | Vertex AI     |  |
|  | (IDE)     |          | (intern)  |          | Gemini Flash  |  |
|  +----------+           +-----------+          +---------------+  |
|                                                                    |
|  Weg 2: Vertex AI direkt (Cloud)                                   |
|  +----------+    VPN    +-----------+    GCP    +---------------+  |
|  | Entwickler| -------> | GCP       | -------> | Vertex AI     |  |
|  | (IDE)     |          | Projekt   |          | Anthropic/etc |  |
|  +----------+           +-----------+          +---------------+  |
|                                                                    |
|  Weg 3: Lokal (dieser PoC)                                         |
|  +----------+  localhost  +----------+                              |
|  | Entwickler| ---------> | Ollama   |   KEIN NETZWERK             |
|  | (IDE)     | <--------- | (lokal)  |                              |
|  +----------+             +----------+                              |
+-------------------------------------------------------------------+
```

## Detailvergleich: CoSI API vs. Lokales LLM

| Dimension | CoSI API | Lokales LLM |
|---|---|---|
| **Setup** | API-Key per JIRA beantragen | `docker compose up` |
| **Wartezeit** | Key-Bearbeitung durch CDC | Sofort |
| **Modell** | Gemini Flash / Pro | Qwen 2.5 Coder 7B |
| **Qualitaet** | Hoch (Frontier) | Mittel (70% von Frontier) |
| **Kosten** | API-Kosten (gering) | 0 EUR |
| **Datenschutz** | Daten in GCP (EU) | Daten auf Geraet |
| **Offline** | Nein (VPN noetig) | Ja |
| **Quota** | 60 Req/Min | Unbegrenzt |
| **Key-Rotation** | Alle 12 Monate | Nicht noetig |
| **IDE-Integration** | Continue-Plugin | Cline / Aider |
| **Abhaengigkeit** | VPN, GCP, CDC | Keine |

## Verfuegbarkeitsstatus (Stand Maerz 2026)

### Sofort verfuegbar

- **CoSI API (Dev-Key):** Fuer einzelne Entwickler, Gemini Flash
- **Lokales LLM:** Keine Freigabe noetig, OSS

### In Klaerung

- **Gemini CLI:** Base URL konfigurierbar, API Key noch nicht
  (siehe GitHub Issue #1679)
- **Claude Code auf Vertex AI:** Informationssicherheit + Datenschutz
  freigegeben, aber Einkaufsfreigabe fehlt

### Wichtige Termine

- **Google Cloud Next (22.-24. April 2026):** Voraussichtlich GA und
  EU-Verfuegbarkeit neuer Modelle (Gemini 3.0/3.1)
- **CoSI API Key-Rotation:** Alle 12 Monate, aktuell manueller Prozess
  (CyberArk-Integration geplant)

## Vertex AI Anthropic -- Freigabestatus

| Pruefung | Status | Anmerkung |
|---|---|---|
| Informationssicherheit | FREIGABE | Unter Einhaltung der Richtlinie "Public Cloud Hyperscaler" |
| Datenschutz | FREIGABE MIT AUFLAGEN | Keine Datenspeicherung in 3rd-Party-Services |
| Einkauf | AUSSTEHEND | Noch nicht ausdefiniert (Info Jan Paul Assendorp) |
| KI-Governance | Laufend | Nur freigegebene Modelle via Organization Policy |

### Auflagen bei Nutzung (Auszug)

- EU-Endpoints zwingend (privater Zugriff via PSC)
- VPC Service Controls aktiviert
- Request/Response-Logging deaktiviert
- Cloud DLP Filter konfiguriert
- Kein Grounding mit Google Suche oder RAG
- Nur freigegebene Modelle (per Organization Policy)
- CMEK fuer Daten ab Schutzbedarf 2

**Fazit:** Die Cloud-basierten Optionen sind verfuegbar, aber mit erheblichen
Auflagen verbunden. Das lokale LLM umgeht alle diese Auflagen, da keine
Cloud-Infrastruktur involviert ist.

## Empfehlung: Parallele Strategie

```
Sofort (Maerz 2026):
├── Lokales LLM (PoC) -----> Offline-faehig, 0 Kosten, max. Datenschutz
└── CoSI API (Dev-Key) ----> Hoehere Qualitaet, offiziell freigegeben

Kurzfristig (April-Juni 2026):
├── Gemini CLI (nach Cloud Next) -> Wenn Custom-URL/Key geloest
└── Claude Code (nach Einkauf) ---> Wenn Beschaffung abgeschlossen

Empfehlung: NICHT gegeneinander ausspielen, sondern als Toolbox positionieren:
- Lokales LLM fuer datenschutzkritische Arbeit und Offline-Szenarien
- CoSI API / Gemini CLI fuer Aufgaben, die Frontier-Qualitaet erfordern
```
