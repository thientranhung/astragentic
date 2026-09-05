---
# Schema sample for the `pages` collection (rebuild spec §5).
# Real files live at src/content/pages/{vi,en}/{home,failures,evidence,adopt}.md
# Files starting with `_` are skipped by the loader.
title: "Một agent chạy ngon. Ba agent thì bắt đầu giẫm lên nhau."
description: "Một câu mô tả trang, dùng cho thẻ meta."
acts: # home only; failures/evidence/adopt omit this key
  - id: act-1
    eyebrow: "AST-016 · promoted 2026-07-11" # stays English in both locales
    headline: "Một agent chạy ngon. Ba agent thì bắt đầu giẫm lên nhau."
  - id: act-2
    eyebrow: "SEVEN STAGES"
    headline: "Mình cắt một ticket thành bảy chặng."
---

Everything before the first `##` is the page intro.

## act-1

Prose only. No component, no hand-typed AST id, no hand-typed number: write
{{meta.cited}} / {{meta.orphan}} / {{meta.total}} and the layout fills them in.

## act-2

On /loi the section ids are `## AST-131`, `## AST-097`, … On /bang-chung it is
`## orphan`. On /cai it is `## brownfield`.
