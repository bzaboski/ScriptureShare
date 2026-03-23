# CLAUDE.md — Scripture Share Project Brain

> **This file is the single source of truth for Claude Code.** Read it fully before starting any task.

---

## Project Overview

Scripture Share is an **iMessage extension** that lets users search for and share Bible verses directly in text conversations. It ships with the full **King James Version (KJV)** bundled locally as a SQLite database. Future translations (ESV, NLT) will be added once licensing is secured.

- **Developer:** Bill Zaboski / Z-Team Apps (zteamapps.com)
- **Bundle ID (host app):** `com.bzaboski.scriptureshare`
- **Bundle ID (iMessage extension):** `com.bzaboski.scriptureshare.messages`
- **App Group:** `group.com.bzaboski.scriptureshare`
- **Minimum iOS:** 17.0
- **Pricing:** Free (no IAP, no ads)
- **Repo:** `https://github.com/bzaboski/ScriptureShare.git`

---

## Architecture

### Two Targets
| Target | Purpose |
|--------|---------|
| `ScriptureShare` | Host app — home screen icon, onboarding, settings |
| `ScriptureShareMessages` | iMessage extension — runs inside Messages.app |

Both targets share code via a `Shared/` group (models, services, database layer).

### Tech Stack
- **UI:** SwiftUI
- **Data:** SwiftData (user preferences, recents) + SQLite (Bible text via bundled `kjv.sqlite`)
- **Search:** SQLite FTS5 for full-text keyword search across 31,000+ verses
- **Architecture:** MVVM
- **No network required:** KJV POC is fully offline

### App Group Sharing
The host app and iMessage extension share data via the App Group container `group.com.bzaboski.scriptureshare`. This includes:
- SwiftData store (user settings, recent verses)
- Access to the bundled SQLite database

---

## Database Schema

The bundled `kjv.sqlite` (~4.5 MB) contains:

```
books (id, name, testament, abbreviation)
chapters (id, book_id, number)
verses (id, chapter_id, number, text)
verses_fts (FTS5 virtual table on verses.text)
```

The database is **read-only** and bundled in shared resources accessible to both targets.

---

## Project Structure (Target State)

```
ScriptureShare/
├── ScriptureShare/                    # Host app target
│   ├── ScriptureShareApp.swift        # App entry point
│   ├── Views/
│   │   ├── OnboardingView.swift       # First-launch walkthrough
│   │   └── SettingsView.swift         # Translation prefs, clear recents
│   └── Assets.xcassets
├── ScriptureShareMessages/            # iMessage extension target
│   ├── MessagesViewController.swift   # MSMessagesAppViewController
│   ├── Views/
│   │   ├── BrowseView.swift           # Book → Chapter → Verse
│   │   ├── DirectEntryView.swift      # Type a reference
│   │   ├── SearchView.swift           # Keyword search
│   │   ├── VersePreviewCard.swift     # Preview before sharing
│   │   └── RecentsView.swift          # Recently shared
│   └── Assets.xcassets
├── Shared/                            # Shared between both targets
│   ├── Models/
│   │   ├── Book.swift
│   │   ├── Verse.swift
│   │   ├── VerseReference.swift
│   │   └── UserSettings.swift         # SwiftData model
│   ├── Services/
│   │   ├── BibleDatabase.swift        # SQLite access layer
│   │   ├── VerseParser.swift          # Reference string parser
│   │   └── SearchService.swift        # FTS5 search
│   └── Resources/
│       └── kjv.sqlite                 # Bundled KJV database
├── ScriptureShare.xcodeproj
└── CLAUDE.md                          # This file
```

---

## Feature Cards (SS-01 through SS-09)

See `scripture_share_feature_cards.docx` for full acceptance criteria and Claude Code prompts.

### Card Status Tracker

| Card | Feature | Status | Branch |
|------|---------|--------|--------|
| SS-01 | Project Scaffold + KJV Database Bundle | ✅ Done | feat/SS-01-project-scaffold |
| SS-02 | Verse Lookup Layer + Reference Parser | ✅ Done | feat/SS-02-verse-lookup-reference-parser |
| SS-03 | Browse Mode UI (Book → Chapter → Verse) | ✅ Done | feat/SS-03-browse-mode-ui |
| SS-04 | Direct Entry Mode + Autocomplete | Not Started | — |
| SS-05 | Translation Selector + User Default | Not Started | — |
| SS-06 | Message Composition + iMessage Insert | Not Started | — |
| SS-07 | Recents List | Not Started | — |
| SS-08 | Keyword Search (FTS5) | Not Started | — |
| SS-09 | Host App (Onboarding + Settings) | Not Started | — |

### Execution Order (Respects Dependencies)

```
SS-01  →  SS-02  →  SS-03  ─┐
                    SS-04  ─┤→  SS-05  →  SS-06  →  SS-07  →  SS-09
          SS-08 (can run in parallel after SS-01) ──────────────┘
```

---

## Git Workflow

### Branch Naming
```
feat/SS-XX-short-description
```

### Commit Format
```
feat(SS-XX): description       # New feature for card XX
fix(SS-XX): description        # Bug fix for card XX
refactor(SS-XX): description   # Code improvement, no behavior change
docs: description              # Documentation updates
```

### Per-Card Flow
1. `git checkout main && git pull`
2. `git checkout -b feat/SS-XX-short-description`
3. Build the feature (one card per prompt — do NOT combine cards)
4. Test per acceptance criteria
5. `git add . && git commit -m "feat(SS-XX): description"`
6. `git push -u origin feat/SS-XX-short-description`
7. `git checkout main && git merge feat/SS-XX-short-description && git push`

---

## iMessage Extension Notes

- iMessage extensions run inside Messages.app, not standalone
- Two presentation modes: **compact** (keyboard height) and **expanded** (full screen)
- Browse/search UI should target expanded mode
- The extension uses `MSMessagesAppViewController` as its root
- Sharing inserts **plain text** into the conversation (not rich message bubbles)
- Testing: In Xcode, select `ScriptureShareMessages` scheme → run on iPhone simulator → Xcode asks which app to launch → select **Messages** → open a conversation → tap app drawer → find Scripture Share

### Verse Output Format
```
"For God so loved the world, that he gave his only begotten Son,
that whosoever believeth in him should not perish, but have everlasting life."
— John 3:16 (KJV)
```

---

## Design Principles

1. **Speed first** — Verse lookup must feel instant. Local SQLite, no network dependency.
2. **One-tap sharing** — Minimize taps from finding a verse to inserting it.
3. **Respect the text** — Clean, readable typography. Bible text is the hero.
4. **Offline-capable** — KJV POC works entirely offline.

---

## Key Technical Decisions

- **SwiftUI for all UI** — consistent with Majestic Math patterns
- **SQLite (not Core Data) for Bible text** — read-only, bundled, FTS5 support
- **SwiftData for user preferences** — recents, translation selection
- **No Supabase** — this app is fully local/offline for POC
- **Plain text sharing first** — rich message bubbles deferred to post-v1
- **Parser supports abbreviations generously** — 'Gen', 'Ge', 'Gn' all map to Genesis, case-insensitive

---

## Reference Documents

| Document | Contents |
|----------|----------|
| `scripture_share_prd.docx` | Full product requirements (vision, UX flows, architecture, data model, roadmap) |
| `scripture_share_feature_cards.docx` | All 9 feature cards with acceptance criteria and Claude Code prompts |
| `Scripture_Share_README.md` | Setup instructions, dev workflow, testing guide |
| `kjv.sqlite` | Pre-built KJV database with FTS5 (~4.5 MB) |
| `build_kjv_database.py` | Script that built the SQLite DB from source data |
| `populate_from_json.py` | Alternate population script from JSON source |

---

## Reminders for Claude Code

- **One feature per prompt.** Do not combine multiple cards.
- **Test on the iMessage extension target**, not just the host app.
- **App Group is critical** — both targets must share the container for SwiftData and SQLite access.
- **The KJV database is read-only** — do not attempt to write to it at runtime.
- **FTS5 is already set up** in the bundled database — use `verses_fts` for keyword search.
- **Abbreviation map should be generous** — support multiple abbreviations per book.
- **Verse ranges use inline superscript numbers** — e.g., `¹⁶ For God so loved... ¹⁷ For God sent not...`
