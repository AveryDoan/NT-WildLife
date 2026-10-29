# TrailField: project context for Claude Code sessions

Read this first. Update the **Status** section at the end of every milestone.

## What this is
"TrailField" (working name): an iPhone app (SwiftUI, iOS 17+, SwiftData, MapKit, PhotosUI, Vision) where people in the Northern Territory photograph insects, work out what they are, learn about NT nature, collect them in a personal field guide and compete with friends. CDU IT Code Fair entry (judged on innovation, functionality, usability, scalability).

- Work-in-progress submission: **Fri 30 Oct 2026, end of day, Darwin time (UTC+9:30)**. The user submits it via a link, not Claude.
- Demo day: **Thu 5 Nov 2026**.
- Priority is a thin, working vertical slice: pick an insect, get points, see a field guide entry and a map pin. Polish second.

## Layout
- `TrailCore/` Swift package. Pure logic only (no SwiftData/UIKit/Vision). `cd TrailCore && swift test`.
- `TrailField/TrailField.xcodeproj` the app. File-system-synchronised group: new files under `TrailField/TrailField/` are picked up automatically.
- `Docs/DATA_SOURCES.md` species verification log. `Docs/LIMITATIONS.md`, `Docs/DEMO_SCRIPT.md`.
- Seed data: `TrailCore/Sources/TrailCore/Resources/species.json`.

## Commands
Command Line Tools is the selected developer dir on this Mac, so use:
```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd TrailCore && swift test
cd TrailField && xcodebuild build -project TrailField.xcodeproj -scheme TrailField \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
(The user can run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` to fix it globally.)

Simulator debugging (DEBUG builds only, via launch arguments, no tapping needed):
`xcrun simctl launch <udid> com.avery.trailfield -hasOnboarded YES -nickname Quokka -demoMode YES -initialTab guide|map|ranks|capture -debugPhoto /path.jpg -debugPick magnetic-termite|order:Lepidoptera|notSure -debugSave YES`
(`simctl privacy <udid> grant location com.avery.trailfield` and `simctl location <udid> set -12.4634,130.8456` for map pins.)

## Decisions (keep unless the user says otherwise)
- Architecture: logic in TrailCore; the app maps SwiftData `@Model` (`Sighting`) to TrailCore value types (`SightingRecord`, `ChallengeSighting`). Swift 5 language mode in both.
- Xcode project made by the user. They choose the signing team. **Never ask for or accept Apple ID passwords or credentials.**
- Bundle ID `com.avery.trailfield` (read from the project; the old simulator-only `com.lequynhnhudoanpersonalteam.TrailField` was unified on 29 Oct). Never use a cdu.edu.au identifier.
- Deployment target iOS 17.0, iPhone only, iOS/iOS Simulator only.
- No third-party dependencies or bundled fonts without asking. New York serif (`design: .serif`) for headings, SF for body.
- dHash: TrailCore takes 9x8 greyscale `[UInt8]`; the app downsizes with CoreGraphics (`ImageHasher`). Duplicate = Hamming distance <= 6.
- Tier 0 identification: manual pick from the seeded list grouped by browsing group, plus order-level answers and "Not sure". Tier 1: Vision `VNClassifyImageRequest` as a **hint only**, labelled "Suggestion" with a confidence bar. Only labels that really exist are mapped (dumped 29 Oct 2026: ant, bee, butterfly, dragonfly, insect, ladybug, moth; plus spider as a safety warning). Tier 2 (Core ML insect model): document only, do not build.
- Single data source: demo sightings (`isDemo`) live in the same store and count in scoring/streaks while demo mode is on. Turning demo mode off deletes them.
- Leaderboard: `LeaderboardService` protocol in TrailCore; `LocalLeaderboardService` with clearly labelled sample players. A real backend would replace the one line in `RanksView`.

## Scoring rules (implemented in TrailCore, tested)
Base: order 5, family 10, genus 15, species 20. Find-difficulty bonus (in-game rating, **not** a conservation status): easy 0, medium +5, hard +15. First time finding a species +10 (species in the guide in any outcome counts as found). Streak bonus per scoring sighting: min(2 x streakDays, 10). One scoring sighting per taxon per day. "Not sure" = 0 and goes to the To identify shelf. Duplicate photo (dHash) = guide only. Photo with no readable capture time, or older than 72 h = guide only (no points or challenge credit). EXIF `DateTimeOriginal` via CGImageSource (+ `OffsetTimeOriginal`, else phone zone); a time more than 5 minutes in the future = unknown. Camera shots use the current time. Faces (Vision) are refused and never saved. Keep the "self-reported" label.

## Species data policy (non-negotiable)
Never invent facts, names or sources. If a field can't be verified, leave it empty and set `verified=false` (UI shows "Unverified"). Verify against ALA, CSIRO, NT Government, museums; log everything in `Docs/DATA_SOURCES.md`. No Aboriginal names, stories or bush-tucker claims unless properly sourced and permitted; placeholder is "Traditional knowledge: to be added with community guidance".

## Design tokens
Asset Catalog colours (light/dark): Paper #F3EEE3, Card #FCFAF5, Ink #1E2B24, Moss #2E5A44, Sage #DCE5D3, Ochre #C98A2B, Clay #B2502B, Water #D5E3E8, plus **OnOchre** (text on Ochre fills; added because Ink on dark-mode Ochre fails contrast). Views use `Color.tfPaper` etc., never literal colours. Contrast rules (WCAG, computed): body text Ink; Moss text OK on Paper/Card/Sage/Water; Clay only for icons, borders and bold text on Card; Ochre is a fill only; Paper on Moss fills, Card on Clay fills, OnOchre on Ochre fills. Components in `Design/Components.swift`; silhouettes (original shapes, one per group) in `Design/Silhouettes.swift`. Accessibility: Dynamic Type, VoiceOver labels, 44 pt targets, colour never the only signal, Reduce Motion respected (almost no animation used).

## Safety, ethics, privacy (non-negotiable)
Look, don't touch: never encourage catching, handling, baiting or collecting. Warn about stinging insects, snakes, spiders, crocodiles, water edges. No challenges near water, at night, needing collection, or in restricted areas (enforced by a test over challenge text). Everyone sees rounded locations only (2 decimals about 1 km; sensitive species 1 decimal about 11 km); the app never stores a precise position and strips EXIF/GPS from saved photos. Nickname only, no chat, no photos of people, everything on device, "Delete all my data" in Profile. Sample data is always labelled "Demo" or "Sample player".

## Working rules
Small commits with clear messages. Git author is `averydoan <harrymystogan@gmail.com>` (set repo-locally; do not touch global config). **No Co-Authored-By or "Generated with Claude" lines in commits or PRs** (the user asked for this on 29 Oct 2026, and their history was rewritten to remove them). No force unwraps, no hard-coded colours, no unlabelled sample data. After each milestone run `swift test` and `xcodebuild build` and report results exactly; mark anything not run (real iPhone, camera, haptics) as "not run". Ask the user at most 3 questions at a time, only when blocked.

## Status (update at each milestone)
Last updated: 29 Oct 2026.
- **M1 done.** App target, design system, seed loader, TrailCore scoring tests. 59 TrailCore tests pass.
- **M2 done (simulator).** Capture (PhotosPicker + camera code path), face check, Identify (Tier 0 + Tier 1), Result with points. Verified in the simulator with generated EXIF-dated photos via the DEBUG launch arguments. Not run: real camera, real photo library picker UI taps, Vision on a real insect photo, a photo containing a real face.
- **M3 done (simulator).** Field Guide, species detail, To identify shelf, Map with rounded circles, demo data.
- **M4 done (simulator).** Weekly challenges seeded by ISO week, streaks, 6 badges, local leaderboard. No challenge bonus points (completion is shown only).
- **M5 partly done.** App icon, dark mode checked, Dynamic Type checked at the largest size on Identify. Not done: full VoiceOver pass on a device, Reduce Motion audit.
- **M6 in progress.** README, DEMO_SCRIPT, LIMITATIONS written. 
- Not run anywhere: real iPhone, signing/provisioning, haptics (`sensoryFeedback` is wired), camera.
- Species data: only 5 seeded; 2 verified (magnetic termite, Leichhardt's grasshopper). Green tree ant and cathedral termite wait for the user to paste NT Government PDF text. Target ~25 species is **not met**.
- Known gaps: no app-level unit/UI test target; `usesCPUOnly` deprecation warning (simulator-only); "To identify" items can't be re-identified yet.
