# ESV Translation Enhancement — Scripture Share

## Licensing Summary

**Publisher:** Crossway (Good News Publishers)
**API:** api.esv.org (free for non-commercial use)
**Key Limits:**
- Up to 500 verses without written permission
- Verses may not exceed 50% of any book or 50% of the total work
- Non-commercial use: free with API key
- Commercial use (app charges money or shows ads): requires formal license from Crossway
- Crossway licenses to organizations, not individuals — Z-Team Apps LLC (if formed) or similar entity needed
- Must include full copyright attribution
- ESV text may not be translated into other languages
- Must align with Crossway's statement of faith

**Required Attribution:**
"Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), © 2001 by Crossway, a publishing ministry of Good News Publishers. ESV Text Edition: 2025. Used by permission. All rights reserved."

**Action Items Before Development:**
- [ ] Determine if Scripture Share will be free (non-commercial API use OK) or paid (formal license required)
- [ ] If commercial: submit licensing request via Crossway's online form
- [ ] Register for ESV API key at api.esv.org
- [ ] Confirm Z-Team Apps meets Crossway's statement of faith requirements

---

## ESV-01: ESV Database Bundle

### Summary
Create an ESV SQLite database (or equivalent) for offline access to ESV text within Scripture Share, similar to the existing KJV database.

### Requirements
- Build ESV database with same schema as existing KJV SQLite database (book, chapter, verse, text)
- Include FTS5 full-text search index for fast verse lookup
- Respect the 500-verse local storage limit unless formal license is obtained
- If unlicensed: use ESV API for real-time verse retrieval instead of bundled database
- If licensed: bundle full ESV text with FTS5 search
- Include proper attribution table/metadata in the database

### Acceptance Criteria
- [ ] ESV text is accessible within the app (API or local DB depending on license status)
- [ ] FTS5 search works for ESV verses
- [ ] Attribution is stored and displayed correctly
- [ ] Database schema matches KJV structure for consistency

### Technical Notes
- ESV API endpoint: https://api.esv.org/v3/passage/text/
- API key stored in Config.swift (gitignored), same pattern as Supabase credentials
- If using API approach, implement caching layer to minimize API calls (5,000/day limit, 60/minute)
- Consider a hybrid: API for search/browse, cache recently viewed verses locally (within 500-verse limit)

---

## ESV-02: Translation Switcher UI

### Summary
Add a translation selector to Scripture Share that allows users to switch between KJV and ESV (and future translations) when browsing or sharing verses.

### Requirements
- Add a translation picker (segmented control or dropdown) to the verse browse/search screen
- Persist the user's preferred translation in UserDefaults
- When sharing a verse via iMessage, include the translation abbreviation (e.g., "John 3:16 — ESV")
- Search results should indicate which translation they're from
- If ESV is API-based (unlicensed), show a loading indicator while fetching
- If ESV is unavailable (no network + API-only mode), gracefully fall back to KJV with a note

### Acceptance Criteria
- [ ] User can switch between KJV and ESV
- [ ] Preferred translation persists across sessions
- [ ] Shared verses include translation label
- [ ] Offline fallback works gracefully
- [ ] UI is clean and doesn't clutter the browse experience

### Technical Notes
- Design the switcher to be extensible — NLT and other translations will be added later
- Use a `Translation` enum with cases for each supported translation
- The verse data layer should accept a translation parameter so all queries are translation-aware

---

## ESV-03: ESV-Specific Search and Display

### Summary
Handle ESV-specific formatting, footnotes, and display requirements that differ from KJV.

### Requirements
- ESV text includes section headings — display or hide based on user preference
- ESV has footnotes — display as expandable inline notes or bottom-of-screen annotations
- ESV uses modern punctuation and formatting — ensure text rendering handles this cleanly
- Red-letter editions: ESV marks words of Christ — support optional red-letter display
- Respect ESV's prohibition on altering the text — no paraphrasing, no word removal in display

### Acceptance Criteria
- [ ] ESV text displays with correct modern formatting
- [ ] Footnotes are accessible but non-intrusive
- [ ] Section headings can be toggled on/off
- [ ] Text is never altered from the API/database source
- [ ] Attribution appears on every screen displaying ESV text

### Technical Notes
- ESV API returns text in multiple formats (HTML, plain text, XML) — choose based on display needs
- The `include-footnotes`, `include-headings`, `include-short-copyright` API parameters control what's returned
- Store display preferences per-translation since KJV and ESV have different formatting options

---

## ESV-04: ESV Copyright Compliance Layer

### Summary
Ensure all ESV usage in the app meets Crossway's copyright and attribution requirements automatically.

### Requirements
- Display the full ESV copyright notice in the app's About/Settings screen
- Include abbreviated attribution "(ESV)" after every displayed ESV verse
- When sharing via iMessage, append the copyright notice to shared content
- Track verse count displayed per session to stay within limits (if unlicensed)
- If using API: respect rate limits (60/min, 1,000/hr, 5,000/day) with a request throttler
- Log API usage for monitoring

### Acceptance Criteria
- [ ] Full copyright notice is displayed in app settings
- [ ] Every ESV verse display includes "(ESV)" attribution
- [ ] Shared verses include proper attribution
- [ ] API rate limiter prevents throttling
- [ ] Usage tracking is in place for license compliance monitoring

### Technical Notes
- Build the compliance layer as a reusable service — it'll be needed for NLT and any future translations
- The rate limiter should queue requests and retry, not fail silently
- Consider a `TranslationComplianceService` protocol that each translation conforms to
