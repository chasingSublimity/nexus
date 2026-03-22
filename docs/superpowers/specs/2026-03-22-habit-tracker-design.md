# Habit Tracker — Design Spec
**Date:** 2026-03-22
**Status:** Approved

---

## Overview

A macOS-native habit tracker with a maximalist cyberpunk aesthetic. Built with an AppKit shell hosting SwiftUI views, local SwiftData persistence, and a visual effect layer designed for eventual Metal shader migration. Combines a menu bar quick-log panel with a full-window dashboard called the **NEXUS**.

---

## Architecture

```
HabitTrackerApp (NSApplicationDelegate)
├── AppShell (AppKit)
│   ├── MenuBarController       → NSStatusItem + popover panel
│   └── MainWindowController    → NSWindow (frameless, custom chrome)
│       └── NSHostingView<RootView>  → SwiftUI tree lives here
│
├── Data Layer
│   ├── HabitStore              → SwiftData ModelContainer
│   └── NotificationScheduler  → UNUserNotificationCenter wrapper
│
├── Gamification Engine
│   ├── XPCalculator
│   ├── LevelSystem
│   └── AchievementEngine
│
└── Visual Layer  ← Metal-ready seam
    ├── EffectRenderer (protocol)
    ├── SwiftUIEffectRenderer   → current impl (Canvas + TimelineView)
    └── MetalEffectRenderer     → future impl, same protocol
```

### Key architectural decisions

- **AppKit shell** owns the app skeleton — `NSStatusItem` for the menu bar, frameless `NSWindow` for NEXUS. AppKit is used for window chrome control; SwiftUI handles all content views via `NSHostingView`.
- **MenuBarController** presents an `NSPopover` hosting a SwiftUI view. The popover opens on `NSStatusItem` click and dismisses on click-outside.
- **Metal-ready seam**: all visual effects (scan lines, bloom, glitch, glow) are produced through an `EffectRenderer` protocol. Today's implementation uses SwiftUI `Canvas` + `TimelineView`. `MetalEffectRenderer` can slot in at the injection point without touching app logic.
- **SwiftData** for local-only persistence. No sync, no network dependency.

### EffectRenderer Protocol

```swift
protocol EffectRenderer {
    associatedtype GlowModifier: ViewModifier

    /// Renders a full-screen overlay effect (scan lines, vignette, noise) into the given rect.
    /// `phase` is a 0–1 normalized time value driven by TimelineView for animation.
    @ViewBuilder func overlay(in rect: CGRect, phase: Double) -> some View

    /// Returns a modifier that applies a neon glow to the receiver.
    /// `color` is one of the neon palette colors; `intensity` is 0–1.
    func glowModifier(color: Color, intensity: Double) -> GlowModifier

    /// Triggers a glitch animation sequence by toggling `isGlitching` true, animating,
    /// then resetting to false after `duration` seconds.
    /// Callers bind a `@State var isGlitching: Bool` and pass it here.
    func triggerGlitch(duration: Double, isGlitching: Binding<Bool>)
}
```

The `associatedtype GlowModifier: ViewModifier` pattern preserves type safety. `SwiftUIEffectRenderer` implements these using `.shadow` chains, `Canvas` drawing, and state-driven animations. `MetalEffectRenderer` will implement the same protocol using `MTKView`-backed rendering — the injection site in `RootView` is the only change required.

---

## Data Model

```swift
Habit
├── id: UUID
├── name: String
├── type: HabitType            // .boolean | .quantified
├── unit: String?              // "miles", "glasses", "minutes"
├── targetValue: Double?       // for quantified habits
├── difficulty: Difficulty     // .easy | .medium | .hard
├── notificationTime: DateComponents?  // hour + minute only; nil = no reminder
├── isArchived: Bool           // soft delete; archived habits are hidden but logs are preserved
├── color: String              // hex, maps to neon palette
├── icon: String               // SF Symbol name
├── sortOrder: Int
└── logs: [HabitLog]

HabitLog
├── id: UUID
├── date: Date                 // normalized to midnight (one log per habit per day)
├── completed: Bool            // for .boolean habits
├── value: Double?             // for .quantified habits
└── habit: Habit

UserProfile                    // singleton — one record per app install
├── xp: Int
├── level: Int
├── totalHabitsCompleted: Int  // AchievementEngine is the sole writer; always incremented atomically with the log write
└── achievements: [Achievement]

Achievement
├── id: UUID
├── key: String                // e.g. "streak_7", "level_10", "night_owl"
├── unlockedAt: Date
└── profile: UserProfile
```

### Data decisions

- `HabitLog.date` is normalized to midnight so queries for "did user complete this habit today?" are simple equality checks.
- `Achievement.key` is a plain string rather than an enum so new achievements can be added without a SwiftData migration.
- `UserProfile` is a singleton row. XP and level are centralized here, not scattered across habit records.
- `Habit.isArchived` enables soft deletion. Archived habits are excluded from the NEXUS Habit Roster and menu bar panel, but their `HabitLog` records are preserved so the 365-day heatmap and achievement counts remain accurate.
- `Habit.notificationTime` stores only hour and minute as `DateComponents`. `NotificationScheduler` schedules a repeating `UNCalendarNotificationTrigger` — the date component is always ignored.
- `UserProfile.totalHabitsCompleted` is a stored counter for query performance. `AchievementEngine` is its sole writer and increments it atomically in the same SwiftData context save as the log write.

---

## Gamification Engine

### XP Formula

```swift
func calculate(for log: HabitLog, streak: Int, siblingsForDay: [HabitLog]) -> Int
```

```
base               = difficulty.xp            // easy=10, medium=25, hard=50
streak_bonus       = base × min(streak × 0.05, 1.0)
                   // streak multiplier caps at 1.0, so streak_bonus caps at base
                   // maximum total before ratio = base + base = 2× base
ratio_multiplier   = log.value / habit.targetValue     // quantified only, capped at 1.2
                   = 1.0 for boolean habits
perfect_day_bonus  = siblingsForDay.allCompleted ? 25 : 0

total = (base + streak_bonus) × ratio_multiplier + perfect_day_bonus
```

The streak cap means `(base + streak_bonus)` tops out at `2 × base` (e.g. hard habit = 100 XP max before ratio). The ratio multiplier can push this up to `2 × base × 1.2` for a quantified habit that exceeds its target.

### Level System

Level thresholds defined in `LevelSystem` as a static lookup using a quadratic curve (`threshold(n) = 100 × (n-1)²`):

| Level | XP Required (cumulative) |
|---|---|
| 1 | 0 |
| 2 | 100 |
| 3 | 400 |
| 4 | 900 |
| 5 | 1,600 |
| 10 | 8,100 |
| 20 | 36,100 |

No level cap — the formula extends indefinitely. Leveling up triggers an achievement check and a glitch animation in the NEXUS activity feed.

### Achievements

`AchievementEngine` evaluates unlock conditions after every log write. Conditions are keyed strings matched against rule functions. Examples:
- `streak_7` — any habit with a 7-day streak
- `streak_30` — any habit with a 30-day streak
- `level_10` — reach level 10
- `night_owl` — log a habit after 11pm on 5 separate days
- `centurion` — 100 total habit completions
- `perfect_week` — complete all habits every day for 7 consecutive days
- `comeback_kid` — reach a 2-day streak on any habit that had a gap of 7+ days since its last log

---

## UI Structure

### Menu Bar Panel

Quick-log interface. Appears as a popover from the `NSStatusItem` tray icon.

```
┌─────────────────────────────┐
│ [NEURAL//HABITS] ══ Day 47  │  ← session streak
│ ─────────────────────────── │
│ ◈ Meditate        [✓ DONE]  │
│ ◈ Run             [4.2 mi]  │
│ ◈ Read            [LOG]     │
│ ─────────────────────────── │
│ XP TODAY: +85  ▓▓▓▓▓░░ L12 │
│           [OPEN NEXUS]      │
└─────────────────────────────┘
```

### NEXUS (Main Window)

Frameless `NSWindow` with full custom chrome. The three-column layout is always visible. The nav bar tabs (`[DASHBOARD] [HABITS] [ACHIEVEMENTS]`) switch only the **center panel** content — the left roster and right stats panels are always present.

```
┌──────────────────────────────────────────────────────┐
│ ◈ HABIT//OS  [DASHBOARD] [HABITS] [ACHIEVEMENTS]  ✕  │
├────────────┬─────────────────────────┬───────────────┤
│  HABIT     │   ACTIVITY MATRIX       │  AGENT STATS  │
│  ROSTER    │   (365-day heatmap)     │               │
│            │                         │  LVL 12       │
│  ▸ Meditate│  ░▒▓█ ░░▒▒▓▓██         │  XP: 2,847    │
│    ██████░ │                         │  ▓▓▓▓▓▓▓░░░   │
│  ▸ Run     │   TODAY'S FEED          │  ACHIEVEMENTS │
│    ████░░░ │  > streak +1 [47 days]  │  ◈ IRON WILL  │
│  ▸ Read    │  > xp gained [+85]      │  ◈ NIGHT OWL  │
│    ███░░░░ │  > level up incoming    │  ░ CENTURION  │
└────────────┴─────────────────────────┴───────────────┘
```

**NEXUS panels:**
- **Left — Habit Roster**: habit list with per-habit streak bars (block character progress indicators)
- **Center — Activity Matrix**: 365-day heatmap + live activity feed (terminal-style scrolling log of events)
- **Right — Agent Stats**: XP bar, level, achievement list (locked/unlocked states)

### Visual Language

- Palette: deep black/dark navy background, neon green (`#39FF14`), electric blue (`#00F5FF`), hot pink (`#FF006E`) accents
- Typography: Fira Code throughout, uppercase-heavy, `//` as section separators. Fira Code must be bundled in the app (not assumed to be installed on the user's system)
- Effects (via `SwiftUIEffectRenderer`, replaceable with Metal): scan line overlay, neon glow (`.shadow` chains), glitch animations on level-up/achievement unlock, `TimelineView`-driven pulsing on active streaks

---

## Notifications

Per-habit scheduled reminders via `UNUserNotificationCenter`. Each `Habit` stores an optional `notificationTime: DateComponents` (hour + minute only). `NotificationScheduler` schedules a repeating `UNCalendarNotificationTrigger` per habit — the trigger fires daily at the stored time. It rebuilds the full notification schedule whenever habits are added, removed, modified, or archived.

Permission is requested once at first launch. If denied, notifications silently do not fire — no error surfaces to the user.

---

## Error Handling

- **SwiftData init failure**: treated as fatal. Show an alert with an option to reset the local store.
- **Log write failure**: silent degradation. Surfaced as a glitch animation in the NEXUS activity feed if NEXUS is open; if NEXUS is closed, the animation is queued and plays on next open.
- **Notification permission denied**: silent degradation. Habits function normally without reminders.
- **XP calculation**: pure functions with no failure modes. All inputs are valid model objects.

---

## Testing Strategy

| Layer | Approach |
|---|---|
| `XPCalculator` | Unit tests — pure function, table-driven cases |
| `AchievementEngine` | Unit tests — given profile state, assert correct unlocks. Requires a mockable clock interface for time-dependent achievements (e.g. `night_owl`) |
| `HabitStore` | Integration tests against in-memory SwiftData container |
| `NotificationScheduler` | Unit tests with mock `UNUserNotificationCenter` |
| UI | Manual — custom AppKit/SwiftUI aesthetics don't lend themselves to snapshot tests |

---

## Future: Metal Migration

When ready to upgrade visual effects:
1. Implement `MetalEffectRenderer` conforming to `EffectRenderer` protocol
2. Replace injection point in app bootstrap — no other changes required
3. Candidates for Metal: scan line shader, bloom/glow post-processing, chromatic aberration, animated glitch distortion

The SwiftUI `Canvas`-based effects are designed as direct analogues to Metal shader passes, making the migration mechanical rather than architectural.
