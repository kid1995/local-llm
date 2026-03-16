# Cline -- Deep Dive

> KI-Assistent als VS Code Extension | Lizenz: Apache 2.0

## Was ist Cline?

Cline ist eine Open-Source VS Code Extension, die KI-gestuetzte Softwareentwicklung
direkt in der IDE ermoeglicht. Mit 2,7 Millionen Nutzern und Einsatz bei Unternehmen
wie Samsung und SAP ist es eines der am weitesten verbreiteten Open-Source-KI-Tools
fuer Entwickler.

**Kernmerkmale:**
- Model-agnostisch -- funktioniert mit jedem LLM-Anbieter (Ollama, OpenAI, Anthropic, etc.)
- Vollstaendiger Dateizugriff und Terminal-Steuerung innerhalb VS Code
- Kann Dateien lesen, schreiben, erstellen und loeschen
- Kann Terminal-Befehle ausfuehren
- Quellcode vollstaendig oeffentlich einsehbar (Apache 2.0)
- Human-in-the-Loop: Jede Aktion erfordert Bestaetigung

**Wichtiger Unterschied zu Claude Code:** Cline laeuft als VS Code Extension, nicht als
eigenstaendiges Terminal-Tool. Eine CLI-Version existiert, ist aber noch im Preview-Stadium.

## Installation

### Voraussetzungen

- VS Code 1.80+ oder kompatible IDE (Cursor, VSCodium, Windsurf)
- Ollama (lokal installiert und laufend)

### Extension installieren

```bash
# Via Terminal
code --install-extension saoudrizwan.claude-dev

# Oder: In VS Code
# 1. Extensions Sidebar (Cmd+Shift+X)
# 2. Suche: "Cline"
# 3. Install
```

### Mit Ollama verbinden

1. **Cline oeffnen:** Cmd+Shift+P -> "Cline: Open in New Tab" (oder Sidebar-Icon)
2. **Settings oeffnen:** Zahnrad-Icon in der Cline-Leiste
3. **API Provider konfigurieren:**
   - Provider: **Ollama**
   - Base URL: `http://localhost:11434`
   - Model: `qwen2.5-coder:7b`
4. **Speichern und testen:** Eine einfache Nachricht senden

## Konfiguration

### Settings (settings.json)

Cline speichert seine Konfiguration in VS Code Settings:

```json
{
  "cline.apiProvider": "ollama",
  "cline.ollamaBaseUrl": "http://localhost:11434",
  "cline.ollamaModelId": "qwen2.5-coder:7b"
}
```

### Empfohlene Einstellungen fuer lokale Modelle

Im Cline Settings Panel:
- **Auto-approve:** Aus (Human-in-the-Loop beibehalten)
- **Max Tokens:** 4096 (spart RAM bei der Inferenz)
- **Custom Instructions:** Optional, z.B.:

```
Du bist ein erfahrener Softwareentwickler.
Antworte auf Deutsch, wenn ich Deutsch schreibe.
Code-Kommentare immer auf Englisch.
Bevorzuge einfache, lesbare Loesungen.
```

## Funktionsweise

### Wie Cline mit Ollama kommuniziert

```
+------------------+    HTTP POST     +------------------+
|   Cline          | --------------> |   Ollama          |
|   (VS Code)      |  localhost:11434 |   (Local Server)  |
|                  | <-------------- |                    |
|   - Dateien      |    JSON Stream   |   qwen2.5-coder   |
|   - Terminal     |                  |   (Inference)     |
|   - Kontext      |                  |                    |
+------------------+                  +------------------+
```

1. Cline sammelt Kontext (aktuelle Datei, Projekt-Struktur, vorherige Nachrichten)
2. Sendet Anfrage an Ollama (nur `localhost`)
3. Ollama fuehrt Inferenz lokal durch
4. Cline empfaengt Antwort und schlaegt Aktionen vor
5. Nutzer bestaetigt oder lehnt ab

### Datenschutz-Architektur

- **Keine Telemetrie:** Cline sendet keine Nutzungsdaten
- **Lokaler Storage:** Konversationen werden lokal in VS Code gespeichert
- **Kein Cloud-Fallback:** Wenn Ollama nicht erreichbar ist, gibt es keinen Fallback
- **Quellcode-Transparenz:** Jede Netzwerk-Kommunikation ist im Code nachvollziehbar

## Typische Workflows

### Code generieren

1. Datei oeffnen oder neues Projekt beschreiben
2. Prompt eingeben: "Create a REST API endpoint for user registration"
3. Cline generiert Code und schlaegt Datei-Aenderungen vor
4. Review und Bestaetigung

### Bestehenden Code refactoren

1. Datei oeffnen
2. "Refactor this function to use immutable patterns"
3. Cline analysiert die Datei und schlaegt Aenderungen vor

### Debugging

1. Fehlermeldung kopieren
2. "Fix this error: [Fehlermeldung]"
3. Cline analysiert den Code-Kontext und schlaegt Fix vor

### Code erklaeren

1. Code markieren oder Datei oeffnen
2. "Explain what this code does and identify potential issues"

## Einschraenkungen mit lokalen Modellen

- **Langsamere Antworten** als Cloud-APIs (abhaengig von Hardware)
- **Kleineres Context Window** als Frontier-Modelle
- **Geringere Code-Qualitaet** bei komplexen Aufgaben -- dies ist erwuenscht fuer den PoC
- **Kein Multi-File-Reasoning** auf dem Niveau von GPT-4 oder Claude

## Vergleich: Cline vs. Aider

| Merkmal | Cline | Aider |
|---|---|---|
| Interface | VS Code Extension | Terminal/CLI |
| Datei-Handling | Automatisch via IDE | Git-aware, automatische Commits |
| Staerke | Visuell, IDE-integriert | Schnell, Git-native |
| Lokale Modelle | Ja (Ollama) | Ja (Ollama) |
| Fuer wen | IDE-Nutzer | Terminal-Nutzer |

Siehe [aider.md](aider.md) fuer die Terminal-Alternative.

## Troubleshooting

### Cline verbindet sich nicht mit Ollama

```bash
# 1. Pruefen, ob Ollama laeuft
curl http://localhost:11434/api/tags

# 2. Pruefen, ob das Modell geladen ist
ollama list

# 3. In Cline: Settings -> Base URL muss "http://localhost:11434" sein
```

### Antworten sind sehr langsam

- Context Window reduzieren (Max Tokens: 2048)
- Kleineres Modell verwenden (`qwen2.5-coder:3b`)
- Andere Anwendungen schliessen (RAM freigeben)

### Cline zeigt keine Modelle an

```bash
# Ollama muss laufen, bevor Cline Modelle abrufen kann
ollama serve &
# Dann in Cline: Settings neu oeffnen oder VS Code neu starten
```

## Quellcode-Referenz

Repository: https://github.com/cline/cline

Relevante Dateien fuer Datenschutz-Audit:
- `src/api/providers/ollama.ts` -- Ollama API Integration
- `src/core/Cline.ts` -- Haupt-Logik
- `package.json` -- Keine Telemetrie-Abhaengigkeiten
