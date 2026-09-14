# 🔖 Index Docs (Paige) — self-contained distilled version

> Distilled from `bmad-index-docs/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Overview / posture
**Goal:** generate or update an `index.md` that references every doc in a target folder, so a reader (human or AI agent) can navigate the folder from one map.

## Execution
1. **Scan the directory** — list all files and subdirectories in the target location.
2. **Group content** — organize files by type, purpose, or subdirectory.
3. **Generate descriptions** — **read each file** to understand its actual purpose and write a brief **3–10 word** description based on content, not the filename.
4. **Create/update `index.md`** — write or update it with the organized listings.

## Output format
```markdown
# Directory Index

## Files

- **[filename.ext](./filename.ext)** - Brief description
- **[another-file.ext](./another-file.ext)** - Brief description

## Subdirectories

### subfolder/

- **[file1.ext](./subfolder/file1.ext)** - Brief description
- **[file2.ext](./subfolder/file2.ext)** - Brief description
```

## Rules / validation
- Use **relative paths starting with `./`**.
- Group similar files together; sort **alphabetically** within groups.
- **Read file contents** to write accurate descriptions — don't guess from filenames.
- Keep descriptions concise but informative (3–10 words).
- **Skip hidden files** (starting with `.`) unless specified.

## Halt conditions
- Halt if the target directory does not exist or is inaccessible.
- Halt if there are no write permissions to create `index.md`.
