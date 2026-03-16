# LanceDB + nomic-embed-text -- Deep Dive

> Lokale Vektor-Datenbank und Embedding-Modell | Lizenz: Apache 2.0 / MIT

## Ueberblick

Fuer fortgeschrittene Use Cases (Code-Suche, RAG, Codebase-Verstaendnis) bietet eine
lokale Vektor-Datenbank mit lokalem Embedding-Modell die Moeglichkeit, grosse Codebasen
semantisch zu durchsuchen -- vollstaendig offline.

| Komponente | Rolle | Lizenz |
|---|---|---|
| LanceDB | Eingebettete Vektor-Datenbank | Apache 2.0 |
| nomic-embed-text | Embedding-Modell | Apache 2.0 |

## LanceDB

### Was ist LanceDB?

LanceDB ist eine eingebettete (embedded) Vektor-Datenbank -- aehnlich wie SQLite, aber
fuer Vektoren. Sie laeuft direkt im Anwendungsprozess ohne separaten Server.

**Vorteile:**
- Kein Server noetig (embedded)
- Persistente Speicherung auf Festplatte
- Unterstuetzt Hybrid-Suche (Vektor + Volltext)
- Minimaler RAM-Verbrauch
- Python und TypeScript SDKs

### Installation

```bash
pip install lancedb
```

### Grundlegende Nutzung

```python
import lancedb
import requests

# Datenbank erstellen (persistiert auf Festplatte)
db = lancedb.connect("./code-vectors")

def get_embedding(text: str) -> list[float]:
    """Embedding via Ollama (lokal) generieren."""
    response = requests.post(
        "http://localhost:11434/api/embed",
        json={"model": "nomic-embed-text", "input": text}
    )
    return response.json()["embeddings"][0]

# Tabelle erstellen
data = [
    {
        "text": "def authenticate(user, password): ...",
        "file": "src/auth.py",
        "vector": get_embedding("def authenticate(user, password): ...")
    },
    {
        "text": "class UserRepository: ...",
        "file": "src/repos/user.py",
        "vector": get_embedding("class UserRepository: ...")
    }
]

table = db.create_table("code_chunks", data=data, mode="overwrite")

# Semantische Suche
query_vector = get_embedding("authentication logic")
results = table.search(query_vector).limit(5).to_pandas()
print(results[["text", "file", "_distance"]])
```

## nomic-embed-text

### Was ist nomic-embed-text?

Ein kompaktes, leistungsstarkes Embedding-Modell (137M Parameter), das Text in
768-dimensionale Vektoren umwandelt. Es laeuft ueber Ollama und benoetigt nur ~300 MB RAM.

### Installation ueber Ollama

```bash
# Modell herunterladen (~275 MB)
ollama pull nomic-embed-text

# Testen
curl http://localhost:11434/api/embed \
  -d '{"model": "nomic-embed-text", "input": "Hello world"}'
```

### Performance

| Metrik | Wert |
|---|---|
| Modellgroesse | ~275 MB |
| RAM-Verbrauch | ~300 MB |
| Dimensionen | 768 |
| Max Token-Laenge | 8192 |
| Geschwindigkeit | ~1000 Embeddings/Sekunde (M1) |

## Use Case: Codebase-Indexierung

### Architektur

```
+------------------+    Embeddings    +------------------+
|   Code-Dateien   | --------------> |   nomic-embed-    |
|   (.py, .java,   |  via Ollama     |   text (lokal)   |
|    .ts, etc.)    |                  +--------+---------+
+------------------+                           |
                                      768-dim Vektoren
                                               |
                                      +--------+---------+
                                      |   LanceDB        |
                                      |   (Vektor-DB)    |
                                      |   ./code-vectors |
                                      +--------+---------+
                                               |
                                      +--------+---------+
                                      |   Semantische    |
                                      |   Code-Suche     |
                                      +------------------+
```

### Beispiel: Codebase indexieren

```python
"""Einfaches Script zur Codebase-Indexierung."""
import os
from pathlib import Path

import lancedb
import requests


def get_embedding(text: str) -> list[float]:
    """Generiert Embedding via lokales Ollama."""
    response = requests.post(
        "http://localhost:11434/api/embed",
        json={"model": "nomic-embed-text", "input": text}
    )
    return response.json()["embeddings"][0]


def chunk_file(file_path: str, chunk_size: int = 50) -> list[dict]:
    """Teilt eine Datei in Chunks auf."""
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    chunks = []
    for i in range(0, len(lines), chunk_size):
        chunk_lines = lines[i:i + chunk_size]
        text = "".join(chunk_lines)
        if text.strip():
            chunks.append({
                "text": text,
                "file": file_path,
                "start_line": i + 1,
                "end_line": min(i + chunk_size, len(lines)),
            })
    return chunks


def index_codebase(root_dir: str, extensions: tuple = (".py", ".java", ".ts", ".js")):
    """Indexiert alle Code-Dateien in einem Verzeichnis."""
    db = lancedb.connect("./code-vectors")
    all_chunks = []

    for path in Path(root_dir).rglob("*"):
        if path.suffix in extensions and ".git" not in str(path):
            chunks = chunk_file(str(path))
            for chunk in chunks:
                chunk["vector"] = get_embedding(chunk["text"])
            all_chunks.extend(chunks)
            print(f"Indexed: {path} ({len(chunks)} chunks)")

    if all_chunks:
        db.create_table("code", data=all_chunks, mode="overwrite")
        print(f"\nTotal: {len(all_chunks)} chunks indexed")

    return db


def search_code(query: str, limit: int = 5):
    """Semantische Code-Suche."""
    db = lancedb.connect("./code-vectors")
    table = db.open_table("code")
    query_vector = get_embedding(query)
    results = table.search(query_vector).limit(limit).to_pandas()
    return results


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "index":
        index_codebase(sys.argv[2] if len(sys.argv) > 2 else ".")
    elif len(sys.argv) > 1 and sys.argv[1] == "search":
        query = " ".join(sys.argv[2:])
        results = search_code(query)
        for _, row in results.iterrows():
            print(f"\n--- {row['file']}:{row['start_line']}-{row['end_line']} ---")
            print(row["text"][:200])
```

## Wann wird das benoetigt?

Fuer den initialen PoC ist LanceDB **optional**. Es wird relevant, wenn:

1. **Grosse Codebasen** durchsucht werden sollen (>100 Dateien)
2. **RAG-Workflows** (Retrieval Augmented Generation) gewuenscht sind
3. **Code-Suche** ueber semantische Aehnlichkeit statt Keywords noetig ist

Cline und Aider funktionieren auch ohne LanceDB -- sie senden den relevanten Code-Kontext
direkt an das LLM.

## Datenschutz

- LanceDB laeuft eingebettet im Prozess (kein Netzwerk)
- nomic-embed-text laeuft ueber Ollama (nur localhost)
- Vektor-Daten werden lokal auf der Festplatte gespeichert
- Kein Cloud-Service involviert
