# Scripture Share — Autonomous Build Instructions

> **For Claude Code:** Read this file and CLAUDE.md before starting any session. This document governs autonomous feature card execution.

---

## Goal

Build Scripture Share to **App Store submission quality** by completing all 9 feature cards (SS-01 through SS-09) in order, one card per branch, without stopping between cards unless explicitly told to.

---

## Autonomous Execution Rules

1. **Keep going.** After completing a card, immediately start the next one in execution order. Do not stop to ask "should I continue?" — just continue.

2. **One card = one branch = one commit.** Branch from `main`, complete the card, commit, merge back to `main`, then start the next branch. Never combine two cards in one branch.

3. **Mark cards complete in CLAUDE.md** after each merge. Update the Card Status Tracker before starting the next card.

4. **Run tests before committing.** Every card that introduces logic must have passing unit tests. Do not commit a failing test suite.

5. **Build must succeed** (`xcodebuild` clean build for both targets) before marking a card done.

6. **Regenerate the project after changing project.yml.** Always run `xcodegen generate` from the project root after modifying `project.yml`.

7. **Do not combine SS-03 and SS-04** even though they are related — each gets its own branch and PR.

8. **App Store prep (post SS-09):**
   - Add app icons to both targets
   - Add `PrivacyInfo.xcprivacy` (no data collection)
   - Verify all acceptance criteria in the simulator (Messages.app target)
   - Document any open items for the developer

---

## Execution Order

```
SS-01 → SS-02 → SS-03 ─┐
                SS-04 ─┤→ SS-05 → SS-06 → SS-07 → SS-09
      SS-08 (after SS-01, can run between SS-07 and SS-09)
```

Practical sequence: **SS-01, SS-02, SS-03, SS-04, SS-05, SS-06, SS-07, SS-08, SS-09**

---

## Git Workflow (per card)

```bash
git checkout main && git pull
git checkout -b feat/SS-XX-short-description
# ... build the feature ...
xcodebuild -project ScriptureShare.xcodeproj \
  -scheme ScriptureShare \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
xcodebuild -project ScriptureShare.xcodeproj \
  -scheme ScriptureShareTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
git add <specific files>
git commit -m "feat(SS-XX): description"
git checkout main && git merge feat/SS-XX-short-description
# Update CLAUDE.md Card Status Tracker
git add CLAUDE.md && git commit -m "docs: mark SS-XX complete"
```

---

## Definition of Done (per card)

- [ ] All acceptance criteria from `scripture_share_feature_cards.docx` are met
- [ ] `xcodebuild` succeeds for both `ScriptureShare` and `ScriptureShareMessages` targets
- [ ] All unit tests pass
- [ ] CLAUDE.md Card Status Tracker updated to ✅ Done
- [ ] Committed and merged to `main`

---

## App Store Readiness Checklist (after SS-09)

- [ ] App icons: 1024×1024 for host app and extension
- [ ] Launch screen polished
- [ ] `PrivacyInfo.xcprivacy` present (no data collected)
- [ ] All 9 cards ✅ in CLAUDE.md
- [ ] Full simulator walkthrough: browse → select → share → verify in conversation
- [ ] Direct entry walkthrough: type reference → preview → share
- [ ] Keyword search walkthrough: type keywords → results → share
- [ ] Recents: share 3 verses → verify in recents → re-share from recents
- [ ] Translation badge visible (KJV)
- [ ] Host app onboarding runs on first launch
- [ ] Host app settings: translation picker, clear recents
- [ ] No crashes on any flow
- [ ] Bundle IDs and App Group match App Store Connect registration

---

*Developer: Bill Zaboski / Z-Team Apps*
*Bundle ID: com.bzaboski.scriptureshare*
