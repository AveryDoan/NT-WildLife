# TrailField

An iPhone app for people in the Northern Territory to photograph insects (from a safe distance), work out what they are, learn about NT nature, build a personal field guide and compete with friends. Working name. Made for the CDU IT Code Fair (work-in-progress build, October 2026).

**Look, don't touch.** TrailField never encourages catching, handling, baiting or collecting.

## What works today
- **Capture**: take a photo or pick one (it must be under 72 hours old to earn points). Photos with people are refused.
- **Identify**: pick from the seeded species (grouped), pick just the group, or say "Not sure". The phone's Vision recogniser can give a clearly labelled *Suggestion* with a confidence bar; you decide.
- **Points**: species 20, family 10, genus 15, group 5, plus bonuses for hard finds, first finds and streaks. Duplicate, old or undated photos save to your guide without points.
- **Field Guide**: specimen cards with catalogue numbers, progress rings, a "To identify" shelf.
- **Map**: your finds, rounded to about 1 km (rare species about 11 km).
- **Today / Ranks**: points, streak, weekly challenges, badges, leaderboard with clearly labelled sample players.
- **Privacy**: nickname only, everything on the phone, "Delete all my data".

## Honest status
Only 5 species are seeded and only 2 are fully verified; the rest show an "Unverified" tag. See [Docs/DATA_SOURCES.md](Docs/DATA_SOURCES.md) and [Docs/LIMITATIONS.md](Docs/LIMITATIONS.md).

## Structure
```
TrailCore/            pure Swift package: species model, scoring, dHash, freshness, streaks,
                      challenges, badges, location rounding, leaderboard (swift test)
TrailField/           Xcode project (SwiftUI, SwiftData, MapKit, PhotosUI, Vision)
Docs/                 data sources, limitations, demo script
CLAUDE.md             project context for AI coding sessions
```

## Build and test
Needs Xcode 17 or later (built with Xcode 27.1) and iOS 17+.
```
cd TrailCore && swift test
cd TrailField && xcodebuild build -project TrailField.xcodeproj -scheme TrailField \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
To run on a real iPhone, open the project in Xcode, choose your own signing team under Signing & Capabilities, and press Run. The simulator has no camera, so use "Choose from photos" there. Turn on **Demo mode** in Profile to see a populated guide and map.

## Scalability
Scoring, streaks, challenges and ranks live in a UI-free package, and the leaderboard sits behind a `LeaderboardService` protocol, so a real backend (accounts, moderation, server-side anti-cheat) can replace the local one without touching the screens. The species list is a data file, so adding verified species needs no code changes.
