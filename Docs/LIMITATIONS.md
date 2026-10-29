# Limitations (as of 29 Oct 2026)

Plain list of what this work-in-progress build does not do, or has not been tested on.

## Content
- Only **5 species** are seeded (target was about 25). Only **2** are verified against sources we actually read; 3 show an "Unverified" tag with blank fields. NT Government fact sheets returned 403, so green tree ant and cathedral termite are waiting for text to be pasted in by hand.
- Habitat, best season and family/order are blank wherever we couldn't confirm them.
- No Aboriginal knowledge is included. The placeholder says it will be added with community guidance.
- Imagery is original silhouettes only. No species photos.

## Identification
- Identification is **self-reported**. A photo isn't proven to show the chosen species, or even an insect.
- The Vision "Suggestion" uses Apple's general photo classifier. It has labels for ant, bee, butterfly, moth, dragonfly, ladybug and generic "insect" only. It cannot suggest beetles, grasshoppers, termites, wasps or flies, and it can be wrong. It has not been tested on real insect photos.
- Tier 2 (a purpose-built Core ML insect model) is **not built**. It would need a licensed, labelled NT insect dataset and would run on-device through the same `VisionHintService` seam.

## Anti-cheat
- Photo time comes from EXIF and can be edited. A photo with no readable time earns nothing; one more than 5 minutes in the future counts as unknown.
- The duplicate check (dHash, Hamming distance 6 or less) only compares against this phone's own history. Someone can still photograph a screen or a printed picture.
- Face detection uses Apple's Vision face detector. It can miss small, blurred or partly hidden faces. If the check itself fails the photo is refused.
- Location for library photos uses the photo's embedded position if there is one, otherwise the phone's current position, which may differ from where an older photo was taken.

## Social
- There is no server. Ranks show **sample players** plus you. Friends and classmates need a backend, accounts and moderation, which are not built.
- Weekly challenges are the same on every phone (seeded by ISO week) but progress isn't shared. Challenges award no bonus points yet.

## Testing
- 59 TrailCore unit tests pass. The app target has no unit or UI tests yet.
- Run in the iOS Simulator (iPhone 17, iOS 27.0 runtime) only. **Not run:** a real iPhone, signing and provisioning, the camera, haptics, VoiceOver on a device, Reduce Motion, Vision on a real iPhone (label list was dumped on macOS), an actual face photo, and the PhotosPicker UI by tapping.
- The "To identify" shelf can't yet be re-identified later.
- A `usesCPUOnly` deprecation warning appears in simulator builds only.
