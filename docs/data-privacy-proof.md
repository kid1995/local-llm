# Nachweis: Kein Datenabfluss

> Dieses Dokument beschreibt, wie nachgewiesen werden kann, dass bei der Nutzung
> des lokalen LLM-Stacks keinerlei Daten das Geraet verlassen.

## Zusammenfassung

Das Setup besteht ausschliesslich aus Komponenten, die lokal kommunizieren:

```
+------------------------------------------------------------------+
|  Lokales Geraet (z.B. MacBook)                                   |
|                                                                   |
|  +------------+   localhost:11434   +------------------+          |
|  | Cline /    | -----------------> | Ollama           |          |
|  | Aider      | <----------------- | (LLM-Server)    |          |
|  +------------+                     +------------------+          |
|                                                                   |
|  Keine ausgehende Netzwerk-Verbindung                             |
+------------------------------------------------------------------+
```

Es gibt **architektonisch keinen Weg nach aussen** -- nicht nur konfigurativ, sondern
im Design der Komponenten.

## Methode 1: Netzwerk-Monitoring mit Little Snitch / Lulu

### Little Snitch (kommerziell, macOS)

Little Snitch ist eine Application-Level-Firewall, die jede ausgehende Verbindung
protokolliert und blockieren kann.

```
1. Little Snitch installieren (https://www.obdev.at/products/littlesnitch/)
2. Regel erstellen: Alle Verbindungen von "ollama" blockieren und protokollieren
3. Regel erstellen: Alle Verbindungen von "code" (VS Code) blockieren, AUSSER localhost
4. Normale Coding-Session durchfuehren
5. Netzwerk-Monitor pruefen: Keine ausgehenden Verbindungen
```

### Lulu (kostenlos, Open Source, macOS)

```bash
# Lulu installieren (https://objective-see.org/products/lulu.html)
# Oder via Homebrew:
brew install --cask lulu
```

Lulu zeigt eine Benachrichtigung bei jeder neuen ausgehenden Verbindung. Waehrend
einer Coding-Session mit Ollama + Cline/Aider sollten **keine** Benachrichtigungen
fuer diese Prozesse erscheinen.

## Methode 2: Netzwerk-Analyse mit nettop/netstat (bordmittel)

Keine zusaetzliche Software noetig -- macOS liefert alles mit.

### nettop (Live-Monitoring)

```bash
# Alle Netzwerk-Verbindungen live beobachten
# Filtere auf relevante Prozesse
sudo nettop -p $(pgrep ollama) -J bytes_in,bytes_out
```

### netstat (Snapshot)

```bash
# Alle Verbindungen von Ollama anzeigen
# Erwartung: NUR 127.0.0.1:11434 (localhost)
lsof -i -n -P | grep ollama
```

**Erwartete Ausgabe:**

```
ollama  12345  user  3u  IPv4  TCP 127.0.0.1:11434 (LISTEN)
```

Nur `127.0.0.1` -- keine externen IP-Adressen.

### Automatisierter Test

```bash
# Script: Netzwerk-Verbindungen waehrend einer Session protokollieren
# Siehe scripts/network-monitor.sh

# 1. Monitoring starten (in separatem Terminal)
./scripts/network-monitor.sh start

# 2. Coding-Session durchfuehren (Cline oder Aider nutzen)

# 3. Monitoring stoppen und Bericht anzeigen
./scripts/network-monitor.sh stop
```

## Methode 3: DNS-Analyse

Wenn kein DNS-Lookup stattfindet, kann keine Verbindung nach aussen aufgebaut werden.

```bash
# DNS-Anfragen live beobachten (erfordert sudo)
sudo tcpdump -i any port 53 -l 2>/dev/null | grep -v "localhost"

# In einem separaten Terminal: Coding-Session starten
# Erwartung: KEINE DNS-Anfragen von Ollama oder Aider
```

## Methode 4: Firewall-Blockade (haertester Test)

Den gesamten ausgehenden Netzwerkverkehr blockieren und pruefen, ob das Setup
weiterhin funktioniert.

### macOS pf Firewall

```bash
# WARNUNG: Blockiert ALLE ausgehenden Verbindungen!
# Nur in einer kontrollierten Testumgebung verwenden.

# 1. Firewall-Regel erstellen
cat > /tmp/pf-block-outgoing.conf << 'EOF'
# Alles blockieren ausser Loopback
block out all
pass out on lo0 all
pass in on lo0 all
EOF

# 2. Regel aktivieren
sudo pfctl -f /tmp/pf-block-outgoing.conf -e

# 3. Pruefen: Internet ist blockiert
curl https://example.com  # Sollte fehlschlagen (timeout)

# 4. Pruefen: Ollama funktioniert weiterhin
curl http://localhost:11434/api/tags  # Sollte funktionieren
ollama run qwen2.5-coder:7b "Hello"  # Sollte funktionieren

# 5. Cline oder Aider testen -- muss weiterhin funktionieren

# 6. Firewall-Regel deaktivieren
sudo pfctl -d
```

**Erwartetes Ergebnis:** Das gesamte Setup funktioniert ohne Internetzugang identisch.

### Docker-basierter Test (network=none)

```bash
# Container ohne Netzwerk starten
docker run --rm -it --network=none \
  -v $(pwd):/workspace \
  ollama-local:latest \
  ollama run qwen2.5-coder:7b "Write a hello world in Python"

# Wenn das funktioniert: Beweis, dass kein Netzwerk benoetigt wird
```

## Methode 5: Quellcode-Audit

Da alle Komponenten Open Source sind, kann der Quellcode direkt geprueft werden.

### Ollama

```bash
# Quellcode klonen
git clone https://github.com/ollama/ollama.git

# Relevante Dateien fuer Netzwerk-Kommunikation:
# server/routes.go -- HTTP-Server (bindet an localhost)
# Keine Telemetrie, keine Cloud-Calls
```

**Pruefen:**
- `grep -r "http" server/ | grep -v localhost | grep -v "127.0.0.1"` -- Gibt es
  externe URLs?
- `grep -r "telemetry\|analytics\|tracking" .` -- Gibt es Telemetrie?

### Cline

```bash
git clone https://github.com/cline/cline.git

# Netzwerk-Kommunikation ist auf API-Provider beschraenkt
# Bei Ollama: ausschliesslich localhost
grep -r "fetch\|axios\|http" src/api/providers/ollama.ts
```

### Aider

```bash
git clone https://github.com/paul-gauthier/aider.git

# LLM-Kommunikation laeuft ueber litellm
grep -r "api_base\|base_url" aider/llm.py
# Bei Ollama-Konfiguration: nur localhost
```

## Methode 6: Wireshark / tcpdump (Paket-Ebene)

Fuer den ultimativen Nachweis: Gesamten Netzwerkverkehr mitschneiden und analysieren.

```bash
# Paket-Capture starten (alle Interfaces ausser Loopback)
sudo tcpdump -i en0 -w /tmp/coding-session.pcap &
TCPDUMP_PID=$!

# === Coding-Session durchfuehren ===
# Cline oder Aider verwenden, Code generieren, etc.

# Capture stoppen
sudo kill $TCPDUMP_PID

# Analyse: Pakete von/zu Ollama-Prozess filtern
# In Wireshark: /tmp/coding-session.pcap oeffnen
# Filter: ip.addr != 127.0.0.1

# Erwartung: KEINE Pakete von Ollama, Cline oder Aider
```

## Zusammenfassung der Methoden

| Methode | Aufwand | Aussagekraft | Werkzeuge |
|---|---|---|---|
| Netzwerk-Monitor (nettop) | Gering | Mittel | macOS Bordmittel |
| DNS-Analyse (tcpdump) | Gering | Mittel | macOS Bordmittel |
| Little Snitch / Lulu | Mittel | Hoch | Drittanbieter-App |
| Firewall-Blockade (pf) | Mittel | Sehr hoch | macOS Bordmittel |
| Quellcode-Audit | Hoch | Hoechste | git |
| Wireshark/tcpdump | Hoch | Hoechste | Wireshark |

**Empfehlung fuer den PoC:**
1. **Schnelltest:** Firewall-Blockade (Methode 4) -- funktioniert das Setup offline?
2. **Dokumentation:** `lsof`/`netstat` Ausgabe (Methode 2) -- nur localhost Verbindungen
3. **Hintergrund:** Quellcode-Verweis (Methode 5) -- Open Source = verifizierbar
