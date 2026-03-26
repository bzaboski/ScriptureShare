# NLT Translation Enhancement — Scripture Share

## Licensing Summary

**Publisher:** Tyndale House Publishers
**API:** api.nlt.to (free anonymous use with limits, key-based for expanded use)
**Key Limits:**
- Up to 500 verses without written permission
- Verses may not exceed 25% of the total work
- May not quote a complete book of the Bible
- Non-commercial use (church bulletins, non-salable media): just include "(NLT)" after each quote
- Commercial use (app sold for money): requires written permission from Tyndale
- Commentary or Bible reference works for commercial sale: always require written permission
- Music usage: verses must be quoted verbatim, requires written permission
- Must include full copyright attribution

**Required Attribution:**
"Scripture quotations are taken from the Holy Bible, New Living Translation, copyright © 1996, 2004, 2015 by Tyndale House Foundation. Used by permission of Tyndale House Publishers, Carol Stream, Illinois 60188. All rights reserved."

**Action Items Before Development:**
- [ ] Determine if Scripture Share will be free or paid
- [ ] If commercial: submit Permissions Questionnaire at tyndale.com/permissions
- [ ] Register for NLT API key at api.nlt.to
- [ ] If app is free + no ads: confirm non-commercial usage terms are sufficient
- [ ] Email permissions@tyndale.com to clarify iMessage extension usage specifically

---

## NLT-01: NLT Database Bundle

### Summary
Create an NLT SQLite database (or equivalent) for offline access to NLT text within Scripture Share, similar to the existing KJV database.

### Requirements
- Build NLT database with same schema as existing KJV and ESV databases (book, chapter, verse, text)
- Include FTS5 full-text search index for fast verse lookup
- Respect the 500-verse / 25% limit unless formal permission is obtained
- If unpermissioned: use NLT API for real-time verse retrieval instead of bundled database
- If permissioned: bundle full NLT text with FTS5 search
- Include proper attribution table/metadata in the database
- NLT uses modern, accessible English — ideal for the primary audience of Scripture Share

### Acceptance Criteria
- [ ] NLT text is accessible within the app (API or local DB depending on permission status)
- [ ] FTS5 search works for NLT verses
- [ ] Attribution is stored and displayed correctly
- [ ] Database schema matches KJV/ESV structure for consistency

### Technical Notes
- NLT API endpoint: https://api.nlt.to/api/passages
- Anonymous API use has lower rate limits — key-based use recommended
- API returns text in HTML format — will need parsing/stripping for plain text display
- NLT's modern English makes it the most readable translation for casual sharing — consider making it the default if licensed

---

## NLT-02: Translation Switcher Integration

### Summary
Extend the translation switcher (built in ESV-02) to include NLT as a third translation option.

### Requirements
- Add NLT to the existing translation picker (KJV / ESV / NLT)
- NLT should display with its own attribution requirements (different from ESV)
- If NLT is the user's preferred translation, shared verses use NLT text and attribution
- Search across translations: optionally let users search all translations simultaneously and see results side-by-side
- Respect NLT's specific prohibition on altering text — no paraphrasing or word changes

### Acceptance Criteria
- [ ] User can switch between KJV, ESV, and NLT
- [ ] NLT-specific attribution appears correctly
- [ ] Cross-translation search works (if implemented)
- [ ] Shared verses use the correct translation and attribution
- [ ] Translation picker scales cleanly with three options

### Technical Notes
- The `Translation` enum from ESV-02 should already support adding new cases
- NLT's modern English will likely be the most popular choice — consider UX that nudges toward it while respecting the default
- Depends on ESV-02 (translation switcher must exist first)

---

## NLT-03: NLT-Specific Formatting and Display

### Summary
Handle NLT-specific formatting, study notes, and display requirements that differ from KJV and ESV.

### Requirements
- NLT uses paragraph-style formatting rather than verse-by-verse — support both display modes
- NLT includes section headings — display or hide based on user preference
- NLT's modern English includes contractions and contemporary phrasing — ensure text rendering handles all Unicode correctly
- Support NLT's poetic formatting (Psalms, Proverbs) with proper indentation
- Some NLT editions include study notes — if available via API, display as expandable annotations

### Acceptance Criteria
- [ ] NLT text displays with correct paragraph formatting
- [ ] Verse-by-verse and paragraph display modes are available
- [ ] Poetic text (Psalms, etc.) renders with proper indentation
- [ ] Section headings can be toggled on/off
- [ ] Text is never altered from the API/database source

### Technical Notes
- NLT API returns HTML — build a parser that extracts both paragraph structure and verse boundaries
- The paragraph vs. verse-by-verse toggle should be a per-translation setting since KJV traditionally uses verse-by-verse
- Poetry detection can key off book name (Psalms, Proverbs, Song of Solomon, Job, Lamentations)

---

## NLT-04: NLT Copyright Compliance Layer

### Summary
Ensure all NLT usage in the app meets Tyndale's copyright and attribution requirements automatically.

### Requirements
- Display the full NLT copyright notice in the app's About/Settings screen
- Include "(NLT)" after every displayed NLT verse
- When sharing via iMessage, append the appropriate copyright notice
- Track total NLT verses used across the app to stay within 500-verse / 25% limits (if unpermissioned)
- If approaching limits, warn and gracefully degrade (switch to KJV or prompt for different translation)
- Log usage for compliance monitoring

### Acceptance Criteria
- [ ] Full copyright notice displayed in app settings
- [ ] Every NLT verse display includes "(NLT)" attribution
- [ ] Shared verses include proper Tyndale attribution
- [ ] Verse usage tracking prevents exceeding limits
- [ ] Graceful degradation when limits are approached
- [ ] Usage logging is in place for compliance

### Technical Notes
- Extend the `TranslationComplianceService` protocol from ESV-04
- NLT's 25% rule is stricter than ESV's 50% — the compliance service needs per-translation threshold configuration
- The 500-verse limit is cumulative across the entire work (app), not per-session
- If the app bundles full NLT text (with permission), the verse limit doesn't apply — but the permission must be obtained first

---

## NLT-05: Verse Comparison View

### Summary
Add a side-by-side or stacked comparison view that shows the same verse in multiple translations simultaneously. This is especially valuable with NLT because its modern English alongside KJV's traditional language highlights meaning.

### Requirements
- User can select "Compare" mode from any verse
- Shows the same verse in all available translations (KJV, ESV, NLT) stacked vertically
- Each translation is labeled and attributed correctly
- User can share the comparison view via iMessage (all translations in one message)
- Comparison view works offline for locally-bundled translations, degrades gracefully for API-only translations

### Acceptance Criteria
- [ ] Compare mode shows verse in all available translations
- [ ] Each translation is properly labeled and attributed
- [ ] Comparison can be shared via iMessage
- [ ] Offline support works for bundled translations
- [ ] UI is clean and readable with 2-3 translations visible

### Technical Notes
- This is a high-value feature for Bible study — seeing the same verse in KJV, ESV, and NLT side by side is powerful
- Attribution in shared comparisons must include all relevant copyright notices
- Consider a "daily verse comparison" feature that shows the verse of the day in all translations
- This card can be implemented after NLT-02 (requires multi-translation support)
