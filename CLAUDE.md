# Scoop — Project Conventions

Scoop is a SwiftUI iOS app (iOS 17+, with iOS 26 glass/material paths) backed by Firebase.
This file is the contract for all code changes — human or AI. When code and this document
disagree, either fix the code or update the document in the same PR. Never let them drift silently.

## Build & verify

```
xcodebuild -project Scoop.xcodeproj -scheme "Scoop" -configuration Debug -destination 'generic/platform=iOS Simulator' -quiet build
```

- The scheme is `Scoop`; the *target* is `Scoop Test`. Always pass the scheme, not the target.
- Judge success by exit code 0 and zero `error:` lines (`-quiet` suppresses the banner).

## Xcode project rules

- The app target uses **explicit file references**. A new `.swift` file on disk is NOT in the
  build until it is added in Xcode. Prefer appending to an existing related file; if a new file
  is required, it must be registered in `Scoop.xcodeproj` (do this in Xcode, not by hand-editing
  pbxproj while Xcode is open).
- Invariant: **every file on disk is part of the app**. No scratch files, no `Old*`/`*Test` copies,
  no commented-out file bodies — delete instead; git history is the archive.

## Layer map

```
App/        Composition root: ScoopApp, RootView, AppContainer, AppRouter
AppState/   AppDependencies (owns concrete services), Session, DefaultsManager, protocols
Data/       Services (Firebase wrappers) → Repositories (domain operations) → Loaders, Models
Features/   One folder per user-facing feature: ViewModel + UIState + Views
Shared/     Reusable components, modifiers, design tokens, static data
```

**Boundary rule: nothing in `Features/` or `Shared/` imports Firebase.** Firestore types
(`FieldValue`, `Firestore.Encoder`, query types) stay behind the repository protocols in
`AppState/DataProtocols.swift`. Business rules that touch persistence (e.g. cancellation
penalties) live in a repo method, written as one atomic batch — never as sequential writes
from a ViewModel.

## Feature template

```
Features/<Name>/
  <Name>ViewModel.swift      // @MainActor @Observable final class <Name>ViewModel
                             // + @Observable final class <Name>UIState in the same file
  Views/
    <Name>Container.swift    // the screen root; owns navigation, sheets, task lifecycles
    ...component views
```

- **ViewModel** holds data and async operations; depends only on protocols from
  `DataProtocols.swift` plus `Session`. Constructor injection, label `session:` (never `s:`).
  The parent constructs the ViewModel and passes it in (`@State var vm:` in the container) —
  child screens receive a built VM, not a bag of raw dependencies.
- **UIState** (`<Name>UIState`, no `New`/`Old` prefixes) holds ephemeral view state: selections,
  sheet/popup flags, cached UI measurements. Created by the container itself (`@State private var ui`).
- **Container views** are organized as: a small `body`, then `private` computed vars / funcs
  grouped in `extension <Name>Container { }` blocks with a one-line comment per group.
  `Features/Events/Views/EventsContainer.swift` is the reference example.
- Feature-local models live inside the feature (e.g. `Messages/Chat/Models/`); models shared
  across features live in `Data/Models/`.

## Errors, logging, placeholders

- User-initiated writes: ViewModel methods `throw`; the container catches and routes the failure
  to `InAppNotificationCenter`. `try?` is allowed only for genuinely optional reads
  (image prefetch, cache warm-up) — never for actions the user explicitly triggered.
- No `print()`. Use `os.Logger` (one static logger per subsystem) or delete the statement.
- No placeholder actions (`{ print("hello") }`) on shipping UI — wire it or mark it with a
  compile-visible `// TODO:`.

## Design tokens

- Colors: only named tokens from `Shared/Design/Colors.swift`. Text levels: `.textPrimary`,
  `.textSecondary`, `.textTertiary` (glanceable labels/icons only — never sentences),
  `.textPlaceholder`, `.textAccent` (accent-hued *type* on light backgrounds). Surfaces & lines:
  `.appCanvas`, `.fillGray` (fills, disabled buttons), `.border` (hairlines, strokes, dividers).
  Status: `.successGreen` (confirmed/accepted states only), `.dangerRed`, `.warningYellow`.
  The brand accent lives in `Assets.xcassets/AccentColor` (drives system tinting) — use `.accent`
  for fills/controls and `.textAccent` when the accent appears as text.
  Raw `Color(red:green:blue:)` is allowed **only inside Colors.swift**, plus the map-category
  identity gradients in `MapCategory.swift`/`MapSearchView.swift` (data, not chrome). Need a
  new color? Add a token.
- Fonts: only `Shared/Design/ScoopFonts.swift` — `.font(.body(16, .medium))`,
  `.font(.title(26))`, and the `UIFont` variants. No `.font(.system(...))` in features.
- Corners: only `CornerRadius` tokens from `Shared/Design/GeneralParameters.swift` — the 4pt
  scale (`xs/sm/md/lg/xl`), role aliases (`image`, `smallImage`), and measured system stand-ins
  (`alert`, `menuPlatter`, …). Curvature is always continuous — it's the iOS 26 SDK default, so
  **never pass `style:`** (the one sanctioned `.circular` is a rounded rect standing in for a
  true circle, e.g. `matchedTransitionSource`). True pills are `Capsule()`, true circles
  `Circle()` — never a radius the frame clamps. A rounded view inset in a rounded parent uses
  `CornerRadius.concentric(in:inset:)`. Borders go through `Shared/Design/Strokes.swift`
  (`.stroke(CornerRadius.md)`, `.capsuleStroke()`, …) so stroke and fill can't drift apart.
- Shadows: only `Elevation` levels from `Shared/Design/Shadows.swift`, worn via the
  `.shadow(.card)` overload — the ramp is `card → image → button → softFloating →
  floating` (plus the `glass` role alias of `card` for pre-26 glass stand-ins).
  Light always falls from straight above (x is 0); each level is a
  tight contact layer plus a wide faint ambient layer. `tint:` colors only the ambient
  glow (tinted CTAs glow their own color — `.shadow(.button, tint: .accent)`).
  **A resting shadow is always full strength or absent**: `strength:` exists only to
  animate a shadow in and out (`strength: isSelected ? 1 : 0`) or for press states
  (`Elevation.pressedStrength`). A fractional literal at a call site means a level is
  missing — add one, deriving it with `Layer.halved` where it descends from another
  (`softFloating`). Raw `.shadow(color:radius:x:y:)` is allowed **only inside
  Shadows.swift**, plus the measured system-replication specs that interpolate geometry
  (menu platter bloom in `DropdownCustomMenu.swift`, `ProfileMorph.swift`).

## UI architecture invariants (hard-won — do not "simplify" away)

- Each tab container keeps **one stable `NavigationStack` + one `AppScrollView`**; the system
  title styling (large→inline collapse, SFProRounded via `scoopNavigationBarFonts`) depends on
  both staying alive across content swaps. Pagers nest *inside* the vertical scroll.
- Profiles present at the app root **above** the TabView (ProfileOverlayPresenter); never hide
  the tab bar for them. Chat hides the tab bar path-based on its container.
- Root-rendered profile views must append `.environment(morph)` (ProfileMorphState) or the
  zoom dismissal degrades.
- `CustomMenu` content/footer renders in a separate UIWindow: it must be its own `View` struct,
  or `@Environment(\.customMenuDismiss)` silently no-ops.

## Naming

- Screens end in `Container`; data classes in `ViewModel`; ephemeral state in `UIState`.
- No `Old`, `New`, `Test`, or typo'd names in live code (rename on sight: fix-forward with
  Xcode's Rename refactor).
- File header comments should say `Scoop` (legacy headers say `ScoopTest`; fix when touching a file).

## Standardization status

The codebase is converging on this document (see git history on branch work from July 2026).
Remaining known debt: dead-code sweep, DI label unification (`s:` → `session:`), Firebase
imports in `Features/Events/EventViewModel.swift`, hardcoded colors/fonts sweep, error-handling
sweep, first unit tests. When you fix an instance of debt in a file you're already touching,
do it; don't launch drive-by refactors of untouched files inside a feature PR.
