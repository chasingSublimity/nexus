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
- **Metal-ready seam**: all visual effects (scan lines, bloom, glitch, glow) are produced through an `EffectRenderer` protocol. Today's implementation uses SwiftUI `Canvas` + `TimelineView`. `MetalEffectRenderer` can slot in at the injection point without touching app logic.
- **SwiftData** for local-only persistence. No sync, no network dependency.

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
├── notificationTime: Date?
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
├── totalHabitsCompleted: Int
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

---

## Gamification Engine

### XP Formula

```swift
func calculate(for log: HabitLog, streak: Int, siblingsForDay: [HabitLog]) -> Int
```

```
base               = difficulty.xp            // easy=10, medium=25, hard=50
streak_bonus       = base × min(streak × 0.05, 1.0)   // caps at 2× base
ratio_multiplier   = log.value / habit.targetValue     // quantified only, capped at 1.2
                   = 1.0 for boolean habits
perfect_day_bonus  = siblingsForDay.allCompleted ? 25 : 0

total = (base + streak_bonus) × ratio_multiplier + perfect_day_bonus
```

### Level System

Level thresholds defined in `LevelSystem` as a static lookup. Leveling up triggers an achievement check and a glitch animation in the NEXUS activity feed.

### Achievements

`AchievementEngine` evaluates unlock conditions after every log write. Conditions are keyed strings matched against rule functions. Examples:
- `streak_7` — any habit with a 7-day streak
- `streak_30` — any habit with a 30-day streak
- `level_10` — reach level 10
- `night_owl` — log a habit after 11pm on 5 separate days
- `centurion` — 100 total habit completions
- `perfect_week` — complete all habits every day for 7 consecutive days

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

Frameless `NSWindow` with full custom chrome. Three-column layout — all panels visible simultaneously.

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
- Typography: SF Mono throughout, uppercase-heavy, `//` as section separators
- Effects (via `SwiftUIEffectRenderer`, replaceable with Metal): scan line overlay, neon glow (`.shadow` chains), glitch animations on level-up/achievement unlock, `TimelineView`-driven pulsing on active streaks

---

## Notifications

Per-habit scheduled reminders via `UNUserNotificationCenter`. Each `Habit` stores an optional `notificationTime: Date`. `NotificationScheduler` owns all scheduling logic — it rebuilds the full notification schedule whenever habits are added, removed, or modified.

Permission is requested once at first launch. If denied, notifications silently do not fire — no error surfaces to the user.

---

## Error Handling

- **SwiftData init failure**: treated as fatal. Show an alert with an option to reset the local store.
- **Log write failure**: silent degradation. Surfaced as a glitch animation in the NEXUS activity feed — aesthetic and informative.
- **Notification permission denied**: silent degradation. Habits function normally without reminders.
- **XP calculation**: pure functions with no failure modes. All inputs are valid model objects.

---

## Testing Strategy

| Layer | Approach |
|---|---|
| `XPCalculator` | Unit tests — pure function, table-driven cases |
| `AchievementEngine` | Unit tests — given profile state, assert correct unlocks |
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
