# ✂️ Shard Document — self-contained distilled version

> Distilled from `bmad-shard-doc/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Goal
Split a large markdown file into multiple small, organized files, by **level-2 section (default)** using `npx @kayvan/markdown-tree-parser`.

## Principles
Execute EVERY step in the EXACT order; HALT immediately on any halt-condition.

## Execution
### Step 1 — Get Source Document
- Ask for the source path if not provided. Verify the file exists, is readable, and is valid markdown (`.md`).
- Not found or not markdown → HALT with an error message.

### Step 2 — Get Destination Folder
- Default: same location as the source, folder named after the source without `.md` (e.g. `/path/architecture.md` → `/path/architecture/`).
- Ask the user (`[y]` to use the default: `[suggested-path]`, or enter a new path).
- Verify the folder exists/can be created + has write permission. Permission denied → HALT.

### Step 3 — Execute Sharding
- Tell the user sharding is starting.
- Run: `npx @kayvan/markdown-tree-parser explode [source-document] [destination-folder]`
- Capture output & errors. Command fails → HALT and display the error.

### Step 4 — Verify Output
- Check the destination folder has the sharded files; verify `index.md` was created; count the files. No files at all → HALT.

### Step 5 — Report Completion
Report: source path/name, destination folder, number of section files created, confirmation that `index.md` was created, and any tool warnings/output.

### Step 6 — Handle Original Document
> **Critical:** keeping both the original and the shards defeats the purpose of sharding and causes confusion.

Ask the user what to do with the original `[source-name]`:
- **`[d]` Delete** (recommended — shards can always be reassembled): delete the original file, confirm "Original document deleted: [path]". (Reassemble by concatenating the section files in order.)
- **`[m]` Move to archive:** default `/path/archive/architecture.md`; ask `[y]` to use the default or a custom path; create the archive folder if it doesn't exist; move; confirm "Original document moved to: [archive-path]".
- **`[k]` Keep** (NOT recommended): warn — easy to load the wrong version, updating one side won't reflect the other, duplication wastes space; suggest considering delete/archive; confirm "Original document kept at: [path]".

## HALT
- HALT if the npx command fails or creates no output files.

*If you need to resume: keep a simple append-only markdown log.*
