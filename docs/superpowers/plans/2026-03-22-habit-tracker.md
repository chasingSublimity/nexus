# Habit Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build NEURAL//HABITS — a macOS-native habit tracker with maximalist cyberpunk aesthetic, menu bar quick-log panel, and full NEXUS dashboard window.

**Architecture:** AppKit shell (`NSApplicationDelegate`, `NSStatusItem`, frameless `NSWindow`) hosts SwiftUI content via `NSHostingView`. SwiftData for local persistence. All visual effects isolated behind an `EffectRenderer` protocol with a type-erasing `AnyEffectRenderer` wrapper for future Metal migration.

**Tech Stack:** Swift 5.9+, macOS 14+, AppKit, SwiftUI, SwiftData, UserNotifications framework, XCTest, Fira Code (bundled font).

---

## File Map

Every file that will be created, grouped by responsibility.

```
HabitTracker/
├── HabitTrackerApp.swift                   // @main, NSApplicationDelegate, bootstrap
├── AppKit/
│   ├── MenuBarController.swift             // NSStatusItem + NSPopover lifecycle
│   └── MainWindowController.swift          // Frameless NSWindow, show/hide NEXUS
├── Models/
│   ├── Habit.swift                         // @Model: all habit fields
│   ├── HabitLog.swift                      // @Model: per-day completion record
│   ├── UserProfile.swift                   // @Model singleton: xp, level, reduceMotion
│   └── Achievement.swift                   // @Model: unlocked achievement record
├── Store/
│   └── HabitStore.swift                    // ModelContainer wrapper, CRUD operations
├── Gamification/
│   ├── Clock.swift                         // Protocol for mockable time
│   ├── XPCalculator.swift                  // Pure XP formula function
│   ├── LevelSystem.swift                   // Quadratic threshold lookup
│   └── AchievementEngine.swift             // Rule evaluation, unlocks, Clock injection
├── Notifications/
│   └── NotificationScheduler.swift         // UNUserNotificationCenter wrapper
├── VisualLayer/
│   ├── EffectRenderer.swift                // Protocol + AnyEffectRenderer type eraser
│   └── SwiftUIEffectRenderer.swift         // Canvas/shadow/Timeline implementation
├── Views/
│   ├── Root/
│   │   └── RootView.swift                  // Environment injection, EffectRenderer host
│   ├── MenuBar/
│   │   └── MenuBarPanelView.swift          // Quick-log popover content
│   ├── NEXUS/
│   │   ├── NexusView.swift                 // Three-column layout + nav tab state
│   │   ├── HabitRosterView.swift           // Left: habit list with streak bars
│   │   ├── DashboardView.swift             // Center/default: heatmap + activity feed
│   │   ├── HabitsManagementView.swift      // Center/habits tab: add/edit/archive
│   │   ├── AchievementsView.swift          // Center/achievements tab: achievement grid
│   │   └── AgentStatsView.swift            // Right: XP bar, level, achievement count
│   └── Shared/
│       ├── CyberpunkStyle.swift            // Color palette, button styles, text styles
│       └── HabitRowView.swift              // Reusable row (used in menu bar + roster)
└── Resources/
    └── Fonts/
        ├── FiraCode-Regular.ttf
        ├── FiraCode-Medium.ttf
        ├── FiraCode-Bold.ttf
        └── FiraCode-Light.ttf

HabitTrackerTests/
├── XPCalculatorTests.swift
├── LevelSystemTests.swift
├── AchievementEngineTests.swift
├── HabitStoreTests.swift
└── NotificationSchedulerTests.swift
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: Xcode project (manual step — see below)
- Create: `HabitTracker/HabitTrackerApp.swift`
- Create: `HabitTracker/Resources/Fonts/` (add Fira Code .ttf files)

- [ ] **Step 1: Create Xcode project**

  In Xcode: File → New → Project → macOS → App
  - Product Name: `HabitTracker`
  - Bundle Identifier: `com.yourname.habittracker`
  - Interface: `SwiftUI` (we will add AppKit manually)
  - Language: `Swift`
  - Deployment Target: `macOS 14.0`
  - Uncheck "Include Tests" (we'll add the test target manually for clarity)

  Then: File → New → Target → macOS → Unit Testing Bundle
  - Product Name: `HabitTrackerTests`

- [ ] **Step 2: Add UserNotifications capability**

  In the project editor, select the HabitTracker target → Signing & Capabilities → + Capability → `App Sandbox` (should already be present) → also add `User Notifications`.

- [ ] **Step 3: Download and bundle Fira Code**

  Download Fira Code from https://github.com/tonsky/FiraCode/releases (grab the latest release zip, extract the TTF folder).

  Drag these four files into `HabitTracker/Resources/Fonts/`:
  - `FiraCode-Regular.ttf`
  - `FiraCode-Medium.ttf`
  - `FiraCode-Bold.ttf`
  - `FiraCode-Light.ttf`

  In Xcode, select each .ttf file and ensure "Target Membership: HabitTracker" is checked.

  In `Info.plist`, add the key `Fonts provided by application` (array) with these four values:
  ```
  FiraCode-Regular.ttf
  FiraCode-Medium.ttf
  FiraCode-Bold.ttf
  FiraCode-Light.ttf
  ```

- [ ] **Step 4: Replace generated entry point**

  Delete the generated `ContentView.swift` and `HabitTrackerApp.swift`. Create `HabitTracker/HabitTrackerApp.swift`:

  ```swift
  import AppKit
  import SwiftUI

  @main
  struct HabitTrackerEntryPoint {
      static func main() {
          let app = NSApplication.shared
          let delegate = AppDelegate()
          app.delegate = delegate
          app.run()
      }
  }

  final class AppDelegate: NSObject, NSApplicationDelegate {
      private var menuBarController: MenuBarController?
      private var mainWindowController: MainWindowController?

      func applicationDidFinishLaunching(_ notification: Notification) {
          menuBarController = MenuBarController()
          mainWindowController = MainWindowController()
          menuBarController?.onOpenNexus = { [weak self] in
              self?.mainWindowController?.showWindow(nil)
          }
      }

      func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
          if !hasVisibleWindows {
              mainWindowController?.showWindow(nil)
          }
          return true
      }
  }
  ```

- [ ] **Step 5: Initialize git and commit**

  ```bash
  git add -A
  git commit -m "feat: initial Xcode project setup with Fira Code bundled"
  ```

---

## Task 2: Shared Types + Color Palette

**Files:**
- Create: `HabitTracker/Views/Shared/CyberpunkStyle.swift`

- [ ] **Step 1: Write CyberpunkStyle.swift**

  ```swift
  import SwiftUI

  // MARK: - Palette
  extension Color {
      static let neonGreen  = Color(hex: "#39FF14")
      static let neonBlue   = Color(hex: "#00F5FF")
      static let neonPink   = Color(hex: "#FF006E")
      static let voidBlack  = Color(hex: "#0A0A0F")
      static let darkNavy   = Color(hex: "#0D0D1A")
      static let dimGray    = Color(hex: "#1A1A2E")

      init(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          Scanner(string: hex).scanHexInt64(&int)
          let r = Double((int >> 16) & 0xFF) / 255
          let g = Double((int >> 8) & 0xFF) / 255
          let b = Double(int & 0xFF) / 255
          self.init(red: r, green: g, blue: b)
      }
  }

  // MARK: - Typography
  extension Font {
      static func firaCode(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
          switch weight {
          case .bold:   return .custom("FiraCode-Bold", size: size)
          case .medium: return .custom("FiraCode-Medium", size: size)
          case .light:  return .custom("FiraCode-Light", size: size)
          default:      return .custom("FiraCode-Regular", size: size)
          }
      }
  }

  // MARK: - Shared Enums (used in models and UI)
  enum HabitType: String, Codable {
      case boolean
      case quantified
  }

  enum Difficulty: String, Codable, CaseIterable {
      case easy, medium, hard

      var xp: Int {
          switch self {
          case .easy:   return 10
          case .medium: return 25
          case .hard:   return 50
          }
      }

      var label: String { rawValue.uppercased() }
  }

  enum NexusTab: String, CaseIterable {
      case dashboard    = "DASHBOARD"
      case habits       = "HABITS"
      case achievements = "ACHIEVEMENTS"
  }
  ```

- [ ] **Step 2: Build to verify no compile errors**

  In Xcode: Cmd+B. Expected: Build Succeeded with no errors.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/Shared/CyberpunkStyle.swift
  git commit -m "feat: add shared types, color palette, and Fira Code helpers"
  ```

---

## Task 3: Data Models

**Files:**
- Create: `HabitTracker/Models/Habit.swift`
- Create: `HabitTracker/Models/HabitLog.swift`
- Create: `HabitTracker/Models/UserProfile.swift`
- Create: `HabitTracker/Models/Achievement.swift`

- [ ] **Step 1: Create Habit.swift**

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class Habit {
      var id: UUID
      var name: String
      var type: HabitType
      var unit: String?
      var targetValue: Double?
      var difficulty: Difficulty
      var notificationHour: Int?    // DateComponents.hour
      var notificationMinute: Int?  // DateComponents.minute
      var color: String             // hex string
      var icon: String              // SF Symbol name
      var sortOrder: Int
      var isArchived: Bool

      @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
      var logs: [HabitLog] = []

      init(
          name: String,
          type: HabitType = .boolean,
          difficulty: Difficulty = .medium,
          color: String = "#39FF14",
          icon: String = "circle.fill",
          sortOrder: Int = 0
      ) {
          self.id = UUID()
          self.name = name
          self.type = type
          self.difficulty = difficulty
          self.color = color
          self.icon = icon
          self.sortOrder = sortOrder
          self.isArchived = false
      }

      var notificationTime: DateComponents? {
          guard let hour = notificationHour, let minute = notificationMinute else { return nil }
          var components = DateComponents()
          components.hour = hour
          components.minute = minute
          return components
      }
  }
  ```

- [ ] **Step 2: Create HabitLog.swift**

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class HabitLog {
      var id: UUID
      var date: Date           // normalized to midnight — used for "did user log today?" queries
      var loggedAt: Date       // raw timestamp — used for time-of-day features (night_owl achievement)
      var completed: Bool
      var value: Double?
      var habit: Habit?

      init(habit: Habit, date: Date, completed: Bool = true, value: Double? = nil) {
          self.id = UUID()
          self.date = Calendar.current.startOfDay(for: date)
          self.loggedAt = date   // preserve raw timestamp
          self.completed = completed
          self.value = value
          self.habit = habit
      }
  }
  ```

- [ ] **Step 3: Create UserProfile.swift**

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class UserProfile {
      var xp: Int
      var level: Int
      var totalHabitsCompleted: Int  // sole writer: AchievementEngine
      var reduceMotion: Bool

      @Relationship(deleteRule: .cascade, inverse: \Achievement.profile)
      var achievements: [Achievement] = []

      init() {
          self.xp = 0
          self.level = 1
          self.totalHabitsCompleted = 0
          self.reduceMotion = false
      }
  }
  ```

- [ ] **Step 4: Create Achievement.swift**

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class Achievement {
      var id: UUID
      var key: String        // e.g. "streak_7", "comeback_kid"
      var unlockedAt: Date
      var profile: UserProfile?

      init(key: String, unlockedAt: Date = Date()) {
          self.id = UUID()
          self.key = key
          self.unlockedAt = unlockedAt
      }
  }
  ```

- [ ] **Step 5: Build to verify models compile**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 6: Commit**

  ```bash
  git add HabitTracker/Models/
  git commit -m "feat: add SwiftData models (Habit, HabitLog, UserProfile, Achievement)"
  ```

---

## Task 4: HabitStore

**Files:**
- Create: `HabitTracker/Store/HabitStore.swift`
- Create: `HabitTrackerTests/HabitStoreTests.swift`

- [ ] **Step 1: Write failing test**

  ```swift
  // HabitTrackerTests/HabitStoreTests.swift
  import XCTest
  import SwiftData
  @testable import HabitTracker

  final class HabitStoreTests: XCTestCase {
      var store: HabitStore!

      override func setUp() async throws {
          store = try HabitStore(inMemory: true)
      }

      func test_addHabit_persistsAndReturns() throws {
          let habit = try store.addHabit(name: "Meditate", type: .boolean, difficulty: .medium)
          let habits = try store.fetchActiveHabits()
          XCTAssertEqual(habits.count, 1)
          XCTAssertEqual(habits[0].name, "Meditate")
          XCTAssertFalse(habits[0].isArchived)
      }

      func test_logHabit_createsHabitLog() throws {
          let habit = try store.addHabit(name: "Run", type: .quantified, difficulty: .hard)
          let log = try store.logHabit(habit, date: Date(), value: 5.0)
          XCTAssertEqual(log.value, 5.0)
          XCTAssertEqual(log.habit?.id, habit.id)
      }

      func test_archiveHabit_excludesFromActiveList() throws {
          let habit = try store.addHabit(name: "Read", type: .boolean, difficulty: .easy)
          try store.archiveHabit(habit)
          let active = try store.fetchActiveHabits()
          XCTAssertTrue(active.isEmpty)
      }

      func test_fetchOrCreateProfile_returnsSingleton() throws {
          let p1 = try store.fetchOrCreateProfile()
          let p2 = try store.fetchOrCreateProfile()
          XCTAssertEqual(p1.persistentModelID, p2.persistentModelID)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  In Xcode: Cmd+U. Expected: 4 failures — `HabitStore` not defined.

- [ ] **Step 3: Implement HabitStore.swift**

  ```swift
  import Foundation
  import SwiftData

  final class HabitStore {
      let container: ModelContainer
      private var context: ModelContext { container.mainContext }

      init(inMemory: Bool = false) throws {
          let schema = Schema([Habit.self, HabitLog.self, UserProfile.self, Achievement.self])
          let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
          container = try ModelContainer(for: schema, configurations: [config])
      }

      // MARK: - Habits

      func addHabit(
          name: String,
          type: HabitType = .boolean,
          difficulty: Difficulty = .medium,
          color: String = "#39FF14",
          icon: String = "circle.fill"
      ) throws -> Habit {
          let habits = try fetchActiveHabits()
          let habit = Habit(
              name: name,
              type: type,
              difficulty: difficulty,
              color: color,
              icon: icon,
              sortOrder: habits.count
          )
          context.insert(habit)
          try context.save()
          return habit
      }

      func fetchActiveHabits() throws -> [Habit] {
          let descriptor = FetchDescriptor<Habit>(
              predicate: #Predicate { !$0.isArchived },
              sortBy: [SortDescriptor(\.sortOrder)]
          )
          return try context.fetch(descriptor)
      }

      func archiveHabit(_ habit: Habit) throws {
          habit.isArchived = true
          try context.save()
      }

      // MARK: - Logs

      func logHabit(_ habit: Habit, date: Date, completed: Bool = true, value: Double? = nil) throws -> HabitLog {
          let normalized = Calendar.current.startOfDay(for: date)
          // Remove existing log for this day if present
          let existing = habit.logs.first { $0.date == normalized }
          if let existing { context.delete(existing) }

          let log = HabitLog(habit: habit, date: normalized, completed: completed, value: value)
          context.insert(log)
          try context.save()
          return log
      }

      func fetchLogs(for habit: Habit, in range: ClosedRange<Date>) throws -> [HabitLog] {
          let start = Calendar.current.startOfDay(for: range.lowerBound)
          let end = Calendar.current.startOfDay(for: range.upperBound)
          let habitID = habit.persistentModelID
          let descriptor = FetchDescriptor<HabitLog>(
              predicate: #Predicate { log in
                  log.habit?.persistentModelID == habitID && log.date >= start && log.date <= end
              },
              sortBy: [SortDescriptor(\.date)]
          )
          return try context.fetch(descriptor)
      }

      // MARK: - Profile

      func fetchOrCreateProfile() throws -> UserProfile {
          let descriptor = FetchDescriptor<UserProfile>()
          let existing = try context.fetch(descriptor)
          if let profile = existing.first { return profile }
          let profile = UserProfile()
          context.insert(profile)
          try context.save()
          return profile
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  Cmd+U. Expected: 4 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/Store/HabitStore.swift HabitTrackerTests/HabitStoreTests.swift
  git commit -m "feat: add HabitStore with SwiftData CRUD and in-memory test support"
  ```

---

## Task 5: XPCalculator

**Files:**
- Create: `HabitTracker/Gamification/XPCalculator.swift`
- Create: `HabitTrackerTests/XPCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

  ```swift
  // HabitTrackerTests/XPCalculatorTests.swift
  import XCTest
  @testable import HabitTracker

  final class XPCalculatorTests: XCTestCase {

      // Helper: makes a boolean HabitLog with a mocked habit difficulty
      private func makeLog(difficulty: Difficulty, completed: Bool = true, value: Double? = nil, targetValue: Double? = nil) -> (HabitLog, Habit) {
          let habit = Habit(name: "Test", type: value != nil ? .quantified : .boolean, difficulty: difficulty)
          if let target = targetValue { habit.targetValue = target }
          let log = HabitLog(habit: habit, date: Date(), completed: completed, value: value)
          return (log, habit)
      }

      func test_easyBoolean_noStreak_noPerfectDay() {
          let (log, _) = makeLog(difficulty: .easy)
          let result = XPCalculator.calculate(for: log, streak: 1, siblingsCompleted: false)
          // base=10, streak_bonus=10*min(1*0.05,1.0)=0.5→0, ratio=1.0, perfect=0 → 10
          XCTAssertEqual(result, 10)
      }

      func test_hardBoolean_streak20_perfectDay() {
          let (log, _) = makeLog(difficulty: .hard)
          let result = XPCalculator.calculate(for: log, streak: 20, siblingsCompleted: true)
          // base=50, streak_bonus=50*min(20*0.05,1.0)=50*1.0=50, ratio=1.0, perfect=25
          // total = (50+50)*1.0 + 25 = 125
          XCTAssertEqual(result, 125)
      }

      func test_mediumQuantified_atTarget() {
          let (log, _) = makeLog(difficulty: .medium, value: 5.0, targetValue: 5.0)
          let result = XPCalculator.calculate(for: log, streak: 1, siblingsCompleted: false)
          // base=25, streak_bonus≈1, ratio=1.0 → 26
          XCTAssertEqual(result, 26)
      }

      func test_mediumQuantified_overTarget_capsAt1_2() {
          let (log, _) = makeLog(difficulty: .medium, value: 10.0, targetValue: 5.0)
          let result = XPCalculator.calculate(for: log, streak: 0, siblingsCompleted: false)
          // base=25, streak_bonus=0, ratio=min(2.0,1.2)=1.2 → 25*1.2=30
          XCTAssertEqual(result, 30)
      }

      func test_streakCap_doesNotExceed2xBase() {
          let (log, _) = makeLog(difficulty: .hard)
          let highStreak = XPCalculator.calculate(for: log, streak: 100, siblingsCompleted: false)
          let cappedStreak = XPCalculator.calculate(for: log, streak: 20, siblingsCompleted: false)
          // Both should hit the cap: (50+50)*1.0 = 100
          XCTAssertEqual(highStreak, 100)
          XCTAssertEqual(cappedStreak, 100)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  Cmd+U. Expected: compile error — `XPCalculator` not defined.

- [ ] **Step 3: Implement XPCalculator.swift**

  ```swift
  import Foundation

  enum XPCalculator {
      /// Calculates XP awarded for a single habit log.
      /// - Parameters:
      ///   - log: The completed HabitLog.
      ///   - streak: Consecutive days this habit has been completed (including today).
      ///   - siblingsCompleted: True if all other active habits were also completed today.
      static func calculate(for log: HabitLog, streak: Int, siblingsCompleted: Bool) -> Int {
          guard let habit = log.habit else { return 0 }

          let base = Double(habit.difficulty.xp)
          let streakMultiplier = min(Double(streak) * 0.05, 1.0)
          let streakBonus = base * streakMultiplier

          let ratioMultiplier: Double
          if habit.type == .quantified,
             let value = log.value,
             let target = habit.targetValue,
             target > 0 {
              ratioMultiplier = min(value / target, 1.2)
          } else {
              ratioMultiplier = 1.0
          }

          let perfectDayBonus: Double = siblingsCompleted ? 25 : 0
          let total = (base + streakBonus) * ratioMultiplier + perfectDayBonus
          return Int(total.rounded())
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  Cmd+U. Expected: 5 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/Gamification/XPCalculator.swift HabitTrackerTests/XPCalculatorTests.swift
  git commit -m "feat: add XPCalculator with formula and table-driven tests"
  ```

---

## Task 6: LevelSystem

**Files:**
- Create: `HabitTracker/Gamification/LevelSystem.swift`
- Create: `HabitTrackerTests/LevelSystemTests.swift`

- [ ] **Step 1: Write failing tests**

  ```swift
  // HabitTrackerTests/LevelSystemTests.swift
  import XCTest
  @testable import HabitTracker

  final class LevelSystemTests: XCTestCase {

      func test_level1_startsAt0XP() {
          XCTAssertEqual(LevelSystem.threshold(for: 1), 0)
      }

      func test_level2_requires100XP() {
          XCTAssertEqual(LevelSystem.threshold(for: 2), 100)
      }

      func test_level10_requires8100XP() {
          XCTAssertEqual(LevelSystem.threshold(for: 10), 8100)
      }

      func test_levelForXP_correctlyDeterminesLevel() {
          XCTAssertEqual(LevelSystem.level(for: 0), 1)
          XCTAssertEqual(LevelSystem.level(for: 99), 1)
          XCTAssertEqual(LevelSystem.level(for: 100), 2)
          XCTAssertEqual(LevelSystem.level(for: 399), 2)
          XCTAssertEqual(LevelSystem.level(for: 400), 3)
          XCTAssertEqual(LevelSystem.level(for: 8100), 10)
      }

      func test_xpToNextLevel_isCorrect() {
          // At level 1 with 50 XP, need 50 more to reach level 2 threshold of 100
          XCTAssertEqual(LevelSystem.xpToNextLevel(currentXP: 50), 50)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  Cmd+U. Expected: compile error — `LevelSystem` not defined.

- [ ] **Step 3: Implement LevelSystem.swift**

  ```swift
  import Foundation

  enum LevelSystem {
      /// XP required to reach level n. Formula: 100 × (n-1)²
      static func threshold(for level: Int) -> Int {
          guard level >= 1 else { return 0 }
          let n = level - 1
          return 100 * n * n
      }

      /// Determines the current level for a given total XP.
      static func level(for xp: Int) -> Int {
          var level = 1
          while threshold(for: level + 1) <= xp {
              level += 1
          }
          return level
      }

      /// XP needed to reach the next level from the current total.
      static func xpToNextLevel(currentXP: Int) -> Int {
          let current = level(for: currentXP)
          return threshold(for: current + 1) - currentXP
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  Cmd+U. Expected: 5 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/Gamification/LevelSystem.swift HabitTrackerTests/LevelSystemTests.swift
  git commit -m "feat: add LevelSystem with quadratic threshold formula"
  ```

---

## Task 7: Clock Protocol + AchievementEngine

**Files:**
- Create: `HabitTracker/Gamification/Clock.swift`
- Create: `HabitTracker/Gamification/AchievementEngine.swift`
- Create: `HabitTrackerTests/AchievementEngineTests.swift`

- [ ] **Step 1: Create Clock.swift**

  ```swift
  import Foundation

  protocol Clock {
      var now: Date { get }
  }

  struct SystemClock: Clock {
      var now: Date { Date() }
  }

  struct MockClock: Clock {
      var now: Date
      init(_ date: Date) { self.now = date }
  }
  ```

- [ ] **Step 2: Write failing tests**

  ```swift
  // HabitTrackerTests/AchievementEngineTests.swift
  import XCTest
  @testable import HabitTracker

  final class AchievementEngineTests: XCTestCase {

      private func makeEngine(clock: Clock = SystemClock()) -> AchievementEngine {
          AchievementEngine(clock: clock)
      }

      // Helper: simulate n consecutive days of logs
      private func consecutiveLogs(habit: Habit, days: Int, endingOn date: Date) -> [HabitLog] {
          (0..<days).map { offset in
              let d = Calendar.current.date(byAdding: .day, value: -(days - 1 - offset), to: date)!
              return HabitLog(habit: habit, date: d, completed: true)
          }
      }

      func test_streak7_unlocks() {
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let today = Date()
          let logs = consecutiveLogs(habit: habit, days: 7, endingOn: today)

          let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
          XCTAssertTrue(unlocked.contains("streak_7"))
      }

      func test_streak7_doesNotUnlock_with6Days() {
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let today = Date()
          let logs = consecutiveLogs(habit: habit, days: 6, endingOn: today)

          let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
          XCTAssertFalse(unlocked.contains("streak_7"))
      }

      func test_comebackKid_unlocks_after7DayGap() {
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let today = Calendar.current.startOfDay(for: Date())
          let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
          // Last log before gap was 10 days ago
          let oldLog = HabitLog(habit: habit, date: Calendar.current.date(byAdding: .day, value: -10, to: today)!, completed: true)
          let yesterdayLog = HabitLog(habit: habit, date: yesterday, completed: true)
          let todayLog = HabitLog(habit: habit, date: today, completed: true)

          let unlocked = engine.evaluate(habit: habit, allLogs: [oldLog, yesterdayLog, todayLog], profile: profile, today: today)
          XCTAssertTrue(unlocked.contains("comeback_kid"))
      }

      func test_comebackKid_doesNotUnlock_withSmallGap() {
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let today = Calendar.current.startOfDay(for: Date())
          let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
          let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

          let logs = [twoDaysAgo, yesterday, today].map { HabitLog(habit: habit, date: $0, completed: true) }
          let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
          XCTAssertFalse(unlocked.contains("comeback_kid"))
      }

      func test_nightOwl_unlocks_after5LateNights() {
          let calendar = Calendar.current
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let today = Date()

          // Build 5 log timestamps at 23:30 on different days.
          // HabitLog.init stores the raw date as loggedAt; nightOwlCount reads loggedAt.
          var lateNightDates: [Date] = []
          for i in 0..<5 {
              var components = calendar.dateComponents([.year, .month, .day], from: today)
              components.day! -= i
              components.hour = 23
              components.minute = 30
              lateNightDates.append(calendar.date(from: components)!)
          }

          let logs = lateNightDates.map { HabitLog(habit: habit, date: $0, completed: true) }
          let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
          XCTAssertTrue(unlocked.contains("night_owl"))
      }

      func test_alreadyUnlocked_notReturnedAgain() {
          let engine = makeEngine()
          let habit = Habit(name: "Test", difficulty: .easy)
          let profile = UserProfile()
          let existingAchievement = Achievement(key: "streak_7")
          profile.achievements = [existingAchievement]
          let today = Date()
          let logs = consecutiveLogs(habit: habit, days: 7, endingOn: today)

          let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
          XCTAssertFalse(unlocked.contains("streak_7"))
      }
  }
  ```

- [ ] **Step 3: Run tests to verify they fail**

  Cmd+U. Expected: compile error — `AchievementEngine` not defined.

- [ ] **Step 4: Implement AchievementEngine.swift**

  ```swift
  import Foundation

  final class AchievementEngine {
      private let clock: Clock

      init(clock: Clock = SystemClock()) {
          self.clock = clock
      }

      /// Evaluates which new achievements should unlock after a log write.
      /// Returns keys of newly-unlocked achievements (not already in profile).
      func evaluate(habit: Habit, allLogs: [HabitLog], profile: UserProfile, today: Date) -> [String] {
          let alreadyUnlocked = Set(profile.achievements.map(\.key))
          var newKeys: [String] = []

          func check(_ key: String, condition: () -> Bool) {
              if !alreadyUnlocked.contains(key) && condition() {
                  newKeys.append(key)
              }
          }

          let streak = currentStreak(in: allLogs, asOf: today)

          check("streak_7")     { streak >= 7 }
          check("streak_30")    { streak >= 30 }
          check("comeback_kid") { isComebackKid(logs: allLogs, today: today) }
          check("night_owl")    { nightOwlCount(logs: allLogs) >= 5 }
          check("centurion")    { profile.totalHabitsCompleted >= 100 }
          check("perfect_week") { isPerfectWeek(allHabitLogs: allLogs, today: today) }

          // level achievements use current profile state
          check("level_10") { profile.level >= 10 }

          return newKeys
      }

      // MARK: - Private helpers

      private func currentStreak(in logs: [HabitLog], asOf today: Date) -> Int {
          let calendar = Calendar.current
          let todayNorm = calendar.startOfDay(for: today)
          let completedDays = Set(logs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })

          var streak = 0
          var day = todayNorm
          while completedDays.contains(day) {
              streak += 1
              day = calendar.date(byAdding: .day, value: -1, to: day)!
          }
          return streak
      }

      private func isComebackKid(logs: [HabitLog], today: Date) -> Bool {
          let calendar = Calendar.current
          let todayNorm = calendar.startOfDay(for: today)
          let yesterdayNorm = calendar.date(byAdding: .day, value: -1, to: todayNorm)!

          let completedDays = Set(logs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })

          // Must have completed today and yesterday (2-day streak)
          guard completedDays.contains(todayNorm), completedDays.contains(yesterdayNorm) else { return false }
          // Must NOT have completed the day before yesterday (streak is exactly starting)
          let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: todayNorm)!
          guard !completedDays.contains(twoDaysAgo) else { return false }
          // Gap before the streak must be 7+ days
          let sortedDays = completedDays.sorted()
          guard let lastBeforeGap = sortedDays.last(where: { $0 < yesterdayNorm }) else { return false }
          let gap = calendar.dateComponents([.day], from: lastBeforeGap, to: yesterdayNorm).day ?? 0
          return gap >= 7
      }

      private func nightOwlCount(logs: [HabitLog]) -> Int {
          // night_owl: use loggedAt (raw timestamp) not date (normalized to midnight)
          logs.filter { log in
              let hour = Calendar.current.component(.hour, from: log.loggedAt)
              return hour >= 23
          }.count
      }

      /// perfect_week: all provided logs show completed = true for each of the last 7 days.
      /// NOTE: AchievementEngine.evaluate receives only a single habit's logs.
      /// perfect_week is evaluated by GamificationCoordinator which passes all habits' combined logs.
      private func isPerfectWeek(allHabitLogs: [HabitLog], today: Date) -> Bool {
          let calendar = Calendar.current
          let last7Days = (0..<7).map { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: today))! }
          let completedDays = Set(allHabitLogs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })
          return last7Days.allSatisfy { completedDays.contains($0) }
      }
  }
  ```

- [ ] **Step 5: Run tests to verify they pass**

  Cmd+U. Expected: 5 tests pass.

- [ ] **Step 6: Commit**

  ```bash
  git add HabitTracker/Gamification/ HabitTrackerTests/AchievementEngineTests.swift
  git commit -m "feat: add Clock protocol and AchievementEngine with all achievement rules"
  ```

---

## Task 8: NotificationScheduler

**Files:**
- Create: `HabitTracker/Notifications/NotificationScheduler.swift`
- Create: `HabitTrackerTests/NotificationSchedulerTests.swift`

- [ ] **Step 1: Write failing tests**

  ```swift
  // HabitTrackerTests/NotificationSchedulerTests.swift
  import XCTest
  import UserNotifications
  @testable import HabitTracker

  final class NotificationSchedulerTests: XCTestCase {

      func test_scheduleHabits_requestsCorrectNotificationCount() async throws {
          let center = MockNotificationCenter()
          let scheduler = NotificationScheduler(center: center)

          let habit1 = Habit(name: "Meditate", difficulty: .easy)
          habit1.notificationHour = 8
          habit1.notificationMinute = 0

          let habit2 = Habit(name: "Run", difficulty: .hard)
          habit2.notificationHour = 18
          habit2.notificationMinute = 30

          let habit3 = Habit(name: "Read", difficulty: .medium)
          // no notification time set

          try await scheduler.rebuild(for: [habit1, habit2, habit3])

          XCTAssertEqual(center.pendingRequests.count, 2)
      }

      func test_rebuild_removesOldNotificationsFirst() async throws {
          let center = MockNotificationCenter()
          let scheduler = NotificationScheduler(center: center)

          let habit = Habit(name: "Meditate", difficulty: .easy)
          habit.notificationHour = 8
          habit.notificationMinute = 0

          try await scheduler.rebuild(for: [habit])
          try await scheduler.rebuild(for: [habit])

          // Should still only have 1, not 2 (old ones removed before re-adding)
          XCTAssertEqual(center.pendingRequests.count, 1)
      }
  }

  // MARK: - Mock
  final class MockNotificationCenter: UserNotificationCenter {
      var pendingRequests: [UNNotificationRequest] = []
      var removeAllCalled = false

      func add(_ request: UNNotificationRequest) async throws {
          pendingRequests.append(request)
      }

      func removeAllPendingNotificationRequests() {
          removeAllCalled = true
          pendingRequests.removeAll()
      }

      func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  Cmd+U. Expected: compile error.

- [ ] **Step 3: Implement NotificationScheduler.swift**

  ```swift
  import Foundation
  import UserNotifications

  // Protocol for testability
  protocol UserNotificationCenter {
      func add(_ request: UNNotificationRequest) async throws
      func removeAllPendingNotificationRequests()
      func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
  }

  extension UNUserNotificationCenter: UserNotificationCenter {}

  final class NotificationScheduler {
      private let center: UserNotificationCenter

      init(center: UserNotificationCenter = UNUserNotificationCenter.current()) {
          self.center = center
      }

      func requestPermission() async {
          _ = try? await center.requestAuthorization(options: [.alert, .sound])
      }

      /// Removes all existing habit notifications and schedules fresh ones.
      func rebuild(for habits: [Habit]) async throws {
          center.removeAllPendingNotificationRequests()

          for habit in habits where !habit.isArchived {
              guard let hour = habit.notificationHour,
                    let minute = habit.notificationMinute else { continue }

              var dateComponents = DateComponents()
              dateComponents.hour = hour
              dateComponents.minute = minute

              let content = UNMutableNotificationContent()
              content.title = "NEURAL//HABITS"
              content.body = "TIME TO LOG: \(habit.name.uppercased())"
              content.sound = .default

              let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
              let request = UNNotificationRequest(
                  identifier: "habit-\(habit.id.uuidString)",
                  content: content,
                  trigger: trigger
              )
              try await center.add(request)
          }
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  Cmd+U. Expected: 2 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/Notifications/NotificationScheduler.swift HabitTrackerTests/NotificationSchedulerTests.swift
  git commit -m "feat: add NotificationScheduler with UNCalendarNotificationTrigger and mock"
  ```

---

## Task 9: EffectRenderer Protocol + AnyEffectRenderer

**Files:**
- Create: `HabitTracker/VisualLayer/EffectRenderer.swift`

- [ ] **Step 1: Create EffectRenderer.swift**

  ```swift
  import SwiftUI
  import AppKit

  // MARK: - Protocol

  protocol EffectRenderer {
      associatedtype GlowModifier: ViewModifier

      /// False when in-app reduceMotion is enabled OR system Reduce Motion is on.
      var isMotionEnabled: Bool { get }

      /// Full-screen overlay (scan lines, noise). Returns EmptyView when motion disabled.
      @ViewBuilder func overlay(in rect: CGRect, phase: Double) -> some View

      /// Neon glow modifier. Returns a static border modifier when motion disabled.
      func glowModifier(color: Color, intensity: Double) -> GlowModifier

      /// Triggers a glitch animation by toggling `isGlitching`. No-ops when motion disabled.
      func triggerGlitch(duration: Double, isGlitching: Binding<Bool>)
  }

  // MARK: - Type Eraser

  /// Wraps any EffectRenderer for use as a concrete type in environment/injection.
  final class AnyEffectRenderer: ObservableObject {
      private let _isMotionEnabled: () -> Bool
      private let _overlay: (CGRect, Double) -> AnyView
      private let _glowModifier: (Color, Double) -> AnyViewModifier
      private let _triggerGlitch: (Double, Binding<Bool>) -> Void

      init<R: EffectRenderer>(_ renderer: R) {
          _isMotionEnabled = { renderer.isMotionEnabled }
          _overlay = { rect, phase in AnyView(renderer.overlay(in: rect, phase: phase)) }
          _glowModifier = { color, intensity in AnyViewModifier(renderer.glowModifier(color: color, intensity: intensity)) }
          _triggerGlitch = { duration, binding in renderer.triggerGlitch(duration: duration, isGlitching: binding) }
      }

      var isMotionEnabled: Bool { _isMotionEnabled() }

      func overlay(in rect: CGRect, phase: Double) -> AnyView {
          _overlay(rect, phase)
      }

      func glowModifier(color: Color, intensity: Double) -> AnyViewModifier {
          _glowModifier(color, intensity)
      }

      func triggerGlitch(duration: Double, isGlitching: Binding<Bool>) {
          _triggerGlitch(duration, isGlitching)
      }
  }

  // MARK: - AnyViewModifier helper

  struct AnyViewModifier: ViewModifier {
      private let _body: (Content) -> AnyView
      init<M: ViewModifier>(_ modifier: M) {
          _body = { AnyView($0.modifier(modifier)) }
      }
      func body(content: Content) -> some View {
          _body(content)
      }
  }
  ```

- [ ] **Step 2: Build to verify it compiles**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/VisualLayer/EffectRenderer.swift
  git commit -m "feat: add EffectRenderer protocol and AnyEffectRenderer type eraser"
  ```

---

## Task 10: SwiftUIEffectRenderer

**Files:**
- Create: `HabitTracker/VisualLayer/SwiftUIEffectRenderer.swift`

- [ ] **Step 1: Create SwiftUIEffectRenderer.swift**

  ```swift
  import SwiftUI
  import AppKit

  final class SwiftUIEffectRenderer: EffectRenderer {

      private let userReduceMotion: () -> Bool

      init(userReduceMotion: @escaping () -> Bool = { false }) {
          self.userReduceMotion = userReduceMotion
      }

      var isMotionEnabled: Bool {
          !userReduceMotion() && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      }

      // MARK: - Overlay (scan lines)

      @ViewBuilder
      func overlay(in rect: CGRect, phase: Double) -> some View {
          if isMotionEnabled {
              Canvas { context, size in
                  let lineSpacing: CGFloat = 4
                  var y: CGFloat = 0
                  while y < size.height {
                      let alpha = 0.03 + 0.02 * sin(y / 20 + phase * .pi * 2)
                      context.fill(
                          Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                          with: .color(.black.opacity(alpha))
                      )
                      y += lineSpacing
                  }
              }
              .allowsHitTesting(false)
          }
      }

      // MARK: - Glow Modifier

      struct NeonGlowModifier: ViewModifier {
          let color: Color
          let intensity: Double
          let motionEnabled: Bool

          func body(content: Content) -> some View {
              if motionEnabled {
                  content
                      .shadow(color: color.opacity(0.8 * intensity), radius: 4)
                      .shadow(color: color.opacity(0.5 * intensity), radius: 8)
                      .shadow(color: color.opacity(0.3 * intensity), radius: 16)
              } else {
                  content
                      .overlay(
                          RoundedRectangle(cornerRadius: 2)
                              .stroke(color.opacity(0.6), lineWidth: 1)
                      )
              }
          }
      }

      func glowModifier(color: Color, intensity: Double) -> NeonGlowModifier {
          NeonGlowModifier(color: color, intensity: intensity, motionEnabled: isMotionEnabled)
      }

      // MARK: - Glitch

      func triggerGlitch(duration: Double, isGlitching: Binding<Bool>) {
          guard isMotionEnabled else { return }
          withAnimation(.easeIn(duration: 0.05)) {
              isGlitching.wrappedValue = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
              withAnimation(.easeOut(duration: 0.1)) {
                  isGlitching.wrappedValue = false
              }
          }
      }
  }
  ```

- [ ] **Step 2: Build to verify it compiles**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/VisualLayer/SwiftUIEffectRenderer.swift
  git commit -m "feat: add SwiftUIEffectRenderer with scan lines, glow, and glitch"
  ```

---

## Task 11: AppKit Shell

**Files:**
- Create: `HabitTracker/AppKit/MenuBarController.swift`
- Create: `HabitTracker/AppKit/MainWindowController.swift`
- Modify: `HabitTracker/HabitTrackerApp.swift`

- [ ] **Step 1: Create MenuBarController.swift**

  ```swift
  import AppKit
  import SwiftUI

  final class MenuBarController {
      private var statusItem: NSStatusItem?
      private var popover: NSPopover?

      var onOpenNexus: (() -> Void)?
      // Injected by AppDelegate after store and coordinator are built
      var store: HabitStore?
      var coordinator: GamificationCoordinator?

      init() {
          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          statusItem?.button?.title = "◈"
          statusItem?.button?.font = NSFont(name: "FiraCode-Regular", size: 14)
          statusItem?.button?.action = #selector(togglePopover)
          statusItem?.button?.target = self
      }

      @objc private func togglePopover() {
          if let popover, popover.isShown {
              popover.performClose(nil)
          } else {
              showPopover()
          }
      }

      private func showPopover() {
          guard let store, let coordinator else { return }
          let popover = NSPopover()
          popover.contentSize = NSSize(width: 280, height: 320)
          popover.behavior = .transient
          // Inject modelContainer and coordinator so MenuBarPanelView can read/write habits
          popover.contentViewController = NSHostingController(
              rootView: MenuBarPanelView(onOpenNexus: { [weak self] in
                  popover.performClose(nil)
                  self?.onOpenNexus?()
              })
              .modelContainer(store.container)
              .environmentObject(coordinator)
          )
          self.popover = popover

          if let button = statusItem?.button {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
          }
      }
  }
  ```

- [ ] **Step 2: Create MainWindowController.swift**

  ```swift
  import AppKit
  import SwiftUI

  final class MainWindowController: NSWindowController {
      convenience init() {
          let window = NSWindow(
              contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
              styleMask: [.borderless, .resizable, .miniaturizable],
              backing: .buffered,
              defer: false
          )
          window.title = "NEXUS"
          window.titlebarAppearsTransparent = true
          window.isMovableByWindowBackground = true
          window.backgroundColor = NSColor(Color.voidBlack)
          window.minSize = NSSize(width: 700, height: 480)
          window.center()
          self.init(window: window)
      }

      override func showWindow(_ sender: Any?) {
          super.showWindow(sender)
          window?.makeKeyAndOrderFront(sender)
          NSApp.activate(ignoringOtherApps: true)
      }
  }
  ```

- [ ] **Step 3: Wire up RootView in AppDelegate**

  Update `HabitTrackerApp.swift` `applicationDidFinishLaunching` to set the window's content view (placeholder until RootView is built in Task 13):

  ```swift
  func applicationDidFinishLaunching(_ notification: Notification) {
      let store = try! HabitStore()
      let renderer = SwiftUIEffectRenderer(userReduceMotion: {
          (try? store.fetchOrCreateProfile())?.reduceMotion ?? false
      })
      let anyRenderer = AnyEffectRenderer(renderer)

      menuBarController = MenuBarController()
      mainWindowController = MainWindowController()

      mainWindowController?.window?.contentView = NSHostingView(
          rootView: Text("NEXUS LOADING...")
              .font(.firaCode(16))
              .foregroundColor(.neonGreen)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(Color.voidBlack)
      )

      menuBarController?.store = store
      menuBarController?.coordinator = coordinator
      menuBarController?.onOpenNexus = { [weak self] in
          self?.mainWindowController?.showWindow(nil)
      }
  }
  ```

- [ ] **Step 4: Build and run to verify menu bar icon appears**

  Cmd+R. Expected: app launches, `◈` appears in menu bar, clicking it shows a placeholder popover.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/AppKit/ HabitTracker/HabitTrackerApp.swift
  git commit -m "feat: add AppKit shell — menu bar icon, popover, frameless NEXUS window"
  ```

---

## Task 12: HabitRowView (Shared Component)

**Files:**
- Create: `HabitTracker/Views/Shared/HabitRowView.swift`

This reusable row appears in both the menu bar panel and the NEXUS roster.

- [ ] **Step 1: Create HabitRowView.swift**

  ```swift
  import SwiftUI

  struct HabitRowView: View {
      let habit: Habit
      let log: HabitLog?     // today's log, nil if not yet completed
      let onToggle: () -> Void
      let onValueSet: (Double) -> Void

      @State private var quantifiedInput: String = ""

      var body: some View {
          HStack(spacing: 8) {
              // Status indicator
              Circle()
                  .fill(log?.completed == true ? Color(hex: habit.color) : Color.dimGray)
                  .frame(width: 8, height: 8)
                  .shadow(color: Color(hex: habit.color).opacity(log?.completed == true ? 0.8 : 0), radius: 6)

              Text("◈ \(habit.name.uppercased())")
                  .font(.firaCode(12, weight: .medium))
                  .foregroundColor(log?.completed == true ? Color(hex: habit.color) : .white.opacity(0.7))

              Spacer()

              if habit.type == .quantified {
                  if log?.completed == true {
                      Text("\(log?.value ?? 0, specifier: "%.1f") \(habit.unit ?? "")")
                          .font(.firaCode(11))
                          .foregroundColor(Color(hex: habit.color))
                  } else {
                      TextField("0.0", text: $quantifiedInput)
                          .font(.firaCode(11))
                          .foregroundColor(.neonBlue)
                          .frame(width: 50)
                          .multilineTextAlignment(.trailing)
                          .onSubmit {
                              if let val = Double(quantifiedInput) {
                                  onValueSet(val)
                              }
                          }
                      Text(habit.unit ?? "").font(.firaCode(11)).foregroundColor(.white.opacity(0.4))
                  }
              } else {
                  Button(action: onToggle) {
                      Text(log?.completed == true ? "[✓ DONE]" : "[LOG]")
                          .font(.firaCode(11, weight: .bold))
                          .foregroundColor(log?.completed == true ? Color(hex: habit.color) : .neonGreen)
                  }
                  .buttonStyle(.plain)
              }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
      }
  }
  ```

- [ ] **Step 2: Build to verify no errors**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/Shared/HabitRowView.swift
  git commit -m "feat: add reusable HabitRowView for menu bar and NEXUS roster"
  ```

---

## Task 13: Menu Bar Panel

**Files:**
- Create: `HabitTracker/Views/MenuBar/MenuBarPanelView.swift`

- [ ] **Step 1: Create MenuBarPanelView.swift**

  ```swift
  import SwiftUI

  struct MenuBarPanelView: View {
      let onOpenNexus: () -> Void
      @Environment(\.modelContext) private var modelContext

      // In a real implementation, inject HabitStore via environment
      // For now, wire to store passed from AppDelegate
      var body: some View {
          VStack(spacing: 0) {
              // Header
              HStack {
                  Text("[NEURAL//HABITS]")
                      .font(.firaCode(11, weight: .bold))
                      .foregroundColor(.neonGreen)
                  Spacer()
                  Text("DAY ––")
                      .font(.firaCode(10))
                      .foregroundColor(.neonBlue)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color.dimGray)

              Divider().background(Color.neonGreen.opacity(0.3))

              // Habit list placeholder — replaced by real data in Task 16
              VStack(spacing: 0) {
                  Text("NO HABITS LOADED")
                      .font(.firaCode(11))
                      .foregroundColor(.white.opacity(0.3))
                      .padding()
              }

              Divider().background(Color.neonGreen.opacity(0.3))

              // Footer
              HStack {
                  Text("XP TODAY: +0")
                      .font(.firaCode(10))
                      .foregroundColor(.neonBlue)
                  Spacer()
                  Button(action: onOpenNexus) {
                      Text("[OPEN NEXUS]")
                          .font(.firaCode(10, weight: .bold))
                          .foregroundColor(.neonGreen)
                  }
                  .buttonStyle(.plain)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color.dimGray)
          }
          .background(Color.voidBlack)
          .frame(width: 280)
      }
  }
  ```

- [ ] **Step 2: Wire into MenuBarController**

  The `MenuBarController.showPopover()` already instantiates `MenuBarPanelView`. Build and run.

- [ ] **Step 3: Run and verify menu bar popover shows panel**

  Cmd+R. Click the `◈` in the menu bar. Expected: dark panel appears with header "[NEURAL//HABITS]" and "[OPEN NEXUS]" button.

- [ ] **Step 4: Commit**

  ```bash
  git add HabitTracker/Views/MenuBar/MenuBarPanelView.swift
  git commit -m "feat: add MenuBarPanelView with cyberpunk chrome"
  ```

---

## Task 14: NEXUS Shell + Navigation

**Files:**
- Create: `HabitTracker/Views/Root/RootView.swift`
- Create: `HabitTracker/Views/NEXUS/NexusView.swift`

- [ ] **Step 1: Create RootView.swift**

  ```swift
  import SwiftUI

  struct RootView: View {
      let renderer: AnyEffectRenderer

      var body: some View {
          NexusView(renderer: renderer)
              .environmentObject(renderer)
      }
  }
  ```

- [ ] **Step 2: Create NexusView.swift**

  ```swift
  import SwiftUI

  struct NexusView: View {
      let renderer: AnyEffectRenderer
      @State private var activeTab: NexusTab = .dashboard
      @State private var isGlitching = false

      var body: some View {
          ZStack {
              Color.voidBlack.ignoresSafeArea()

              VStack(spacing: 0) {
                  // Title bar
                  titleBar

                  Divider().background(Color.neonGreen.opacity(0.4))

                  // Three-column layout
                  HStack(spacing: 0) {
                      // Left: Habit Roster (fixed width)
                      HabitRosterView()
                          .frame(width: 200)

                      Divider().background(Color.neonGreen.opacity(0.2))

                      // Center: tab-switched content
                      centerPanel
                          .frame(maxWidth: .infinity)

                      Divider().background(Color.neonGreen.opacity(0.2))

                      // Right: Agent Stats (fixed width)
                      AgentStatsView()
                          .frame(width: 180)
                  }
              }

              // Scan line overlay
              if renderer.isMotionEnabled {
                  GeometryReader { geo in
                      TimelineView(.animation) { timeline in
                          let phase = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 4) / 4
                          renderer.overlay(in: geo.frame(in: .local), phase: phase)
                      }
                  }
                  .ignoresSafeArea()
                  .allowsHitTesting(false)
              }
          }
          .offset(x: isGlitching ? CGFloat.random(in: -3...3) : 0)
      }

      private var titleBar: some View {
          HStack(spacing: 0) {
              Text("◈ HABIT//OS")
                  .font(.firaCode(13, weight: .bold))
                  .foregroundColor(.neonGreen)
                  .padding(.leading, 16)

              Spacer()

              // Nav tabs
              HStack(spacing: 0) {
                  ForEach(NexusTab.allCases, id: \.self) { tab in
                      Button(action: { activeTab = tab }) {
                          Text("[\(tab.rawValue)]")
                              .font(.firaCode(11, weight: activeTab == tab ? .bold : .regular))
                              .foregroundColor(activeTab == tab ? .neonGreen : .white.opacity(0.4))
                              .padding(.horizontal, 12)
                              .padding(.vertical, 8)
                      }
                      .buttonStyle(.plain)
                  }
              }

              Spacer()

              Button(action: { NSApp.terminate(nil) }) {
                  Text("✕")
                      .font(.firaCode(12))
                      .foregroundColor(.neonPink.opacity(0.6))
              }
              .buttonStyle(.plain)
              .padding(.trailing, 16)
          }
          .frame(height: 40)
          .background(Color.darkNavy)
      }

      @ViewBuilder
      private var centerPanel: some View {
          switch activeTab {
          case .dashboard:    DashboardView()
          case .habits:       HabitsManagementView()
          case .achievements: AchievementsView()
          }
      }
  }
  ```

- [ ] **Step 3: Add stub views to allow compilation**

  Add empty stubs in their respective files so the project builds. Create these files with just a `Text("TODO")` body — they'll be filled in subsequent tasks:
  - `HabitTracker/Views/NEXUS/HabitRosterView.swift` (stub)
  - `HabitTracker/Views/NEXUS/AgentStatsView.swift` (stub)
  - `HabitTracker/Views/NEXUS/DashboardView.swift` (stub)
  - `HabitTracker/Views/NEXUS/HabitsManagementView.swift` (stub)
  - `HabitTracker/Views/NEXUS/AchievementsView.swift` (stub)

- [ ] **Step 4: Wire RootView into AppDelegate**

  Replace the placeholder `Text("NEXUS LOADING...")` in `applicationDidFinishLaunching` with:
  ```swift
  mainWindowController?.window?.contentView = NSHostingView(
      rootView: RootView(renderer: anyRenderer)
  )
  ```

- [ ] **Step 5: Build and run, verify NEXUS window structure**

  Cmd+R. Click `[OPEN NEXUS]` in the menu bar. Expected: dark frameless window with `◈ HABIT//OS` title bar, three nav tabs, and stub content in columns.

- [ ] **Step 6: Commit**

  ```bash
  git add HabitTracker/Views/
  git commit -m "feat: add NEXUS shell with three-column layout and nav tabs"
  ```

---

## Task 15: Habit Roster View

**Files:**
- Modify: `HabitTracker/Views/NEXUS/HabitRosterView.swift`

- [ ] **Step 1: Implement HabitRosterView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct HabitRosterView: View {
      @Query(filter: #Predicate<Habit> { !$0.isArchived },
             sort: \Habit.sortOrder) private var habits: [Habit]

      var body: some View {
          ScrollView {
              VStack(spacing: 0) {
                  sectionHeader("HABIT ROSTER")

                  if habits.isEmpty {
                      Text("NO HABITS\nLOADED")
                          .font(.firaCode(11))
                          .foregroundColor(.white.opacity(0.3))
                          .multilineTextAlignment(.center)
                          .padding()
                  } else {
                      ForEach(habits) { habit in
                          habitRow(habit)
                          Divider().background(Color.white.opacity(0.05))
                      }
                  }
              }
          }
          .background(Color.darkNavy)
      }

      private func habitRow(_ habit: Habit) -> some View {
          let todayLog = habit.logs.first {
              Calendar.current.isDateInToday($0.date)
          }
          return VStack(alignment: .leading, spacing: 4) {
              HStack(spacing: 6) {
                  Circle()
                      .fill(Color(hex: habit.color).opacity(todayLog?.completed == true ? 1 : 0.2))
                      .frame(width: 6, height: 6)
                  Text("▸ \(habit.name.uppercased())")
                      .font(.firaCode(11, weight: .medium))
                      .foregroundColor(todayLog?.completed == true ? Color(hex: habit.color) : .white.opacity(0.8))
                      .lineLimit(1)
              }
              // Streak bar using block characters
              streakBar(for: habit)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
      }

      private func streakBar(for habit: Habit) -> some View {
          let streak = currentStreak(for: habit)
          let maxDisplay = 7
          let filled = min(streak, maxDisplay)
          let blocks = String(repeating: "█", count: filled) + String(repeating: "░", count: maxDisplay - filled)
          return Text(blocks + " \(streak)d")
              .font(.firaCode(9))
              .foregroundColor(Color(hex: habit.color).opacity(0.6))
      }

      private func currentStreak(for habit: Habit) -> Int {
          var streak = 0
          var day = Calendar.current.startOfDay(for: Date())
          let completedDays = Set(habit.logs.filter { $0.completed }.map {
              Calendar.current.startOfDay(for: $0.date)
          })
          while completedDays.contains(day) {
              streak += 1
              day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
          }
          return streak
      }

      private func sectionHeader(_ text: String) -> some View {
          HStack {
              Text(text)
                  .font(.firaCode(10, weight: .bold))
                  .foregroundColor(.neonGreen.opacity(0.6))
              Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.voidBlack)
      }
  }
  ```

- [ ] **Step 2: Build and verify**

  Cmd+B. Add a test habit in the simulator or directly via HabitStore to see the roster populate.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/HabitRosterView.swift
  git commit -m "feat: implement HabitRosterView with streak bars"
  ```

---

## Task 16: Dashboard View (Heatmap + Activity Feed)

**Files:**
- Modify: `HabitTracker/Views/NEXUS/DashboardView.swift`

- [ ] **Step 1: Implement DashboardView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct DashboardView: View {
      @Query private var habits: [Habit]
      @State private var activityFeed: [String] = [
          "> SYSTEM INITIALIZED",
          "> AWAITING INPUT...",
      ]

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                  sectionHeader("ACTIVITY MATRIX // 365-DAY")
                  heatmap
                      .padding(.horizontal, 12)
                      .padding(.bottom, 16)

                  Divider().background(Color.neonGreen.opacity(0.15))

                  sectionHeader("TODAY'S FEED")
                  activityFeedView
              }
          }
          .background(Color.darkNavy)
      }

      private var heatmap: some View {
          let calendar = Calendar.current
          let today = calendar.startOfDay(for: Date())
          let days = (0..<365).map { offset -> Date in
              calendar.date(byAdding: .day, value: -(364 - offset), to: today)!
          }
          let allLogs = habits.flatMap(\.logs)
          let logsByDay = Dictionary(grouping: allLogs) { calendar.startOfDay(for: $0.date) }

          return LazyVGrid(columns: Array(repeating: GridItem(.fixed(10), spacing: 2), count: 52), spacing: 2) {
              ForEach(days, id: \.self) { day in
                  let count = logsByDay[day]?.filter(\.completed).count ?? 0
                  Rectangle()
                      .fill(heatmapColor(count: count))
                      .frame(width: 10, height: 10)
                      .help(formatDate(day))
              }
          }
      }

      private func heatmapColor(count: Int) -> Color {
          switch count {
          case 0:        return Color.dimGray
          case 1:        return Color.neonGreen.opacity(0.3)
          case 2:        return Color.neonGreen.opacity(0.6)
          default:       return Color.neonGreen
          }
      }

      private var activityFeedView: some View {
          VStack(alignment: .leading, spacing: 2) {
              ForEach(activityFeed.suffix(20).reversed(), id: \.self) { line in
                  Text(line)
                      .font(.firaCode(10))
                      .foregroundColor(.neonGreen.opacity(0.8))
                      .padding(.horizontal, 12)
                      .padding(.vertical, 1)
              }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      private func formatDate(_ date: Date) -> String {
          let formatter = DateFormatter()
          formatter.dateStyle = .short
          return formatter.string(from: date)
      }

      private func sectionHeader(_ text: String) -> some View {
          HStack {
              Text(text)
                  .font(.firaCode(10, weight: .bold))
                  .foregroundColor(.neonGreen.opacity(0.6))
              Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.voidBlack)
      }
  }
  ```

- [ ] **Step 2: Build and run, verify heatmap renders**

  Cmd+R. Open NEXUS. Expected: 365-day grid in the dashboard center panel, activity feed below it.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/DashboardView.swift
  git commit -m "feat: implement DashboardView with 365-day heatmap and activity feed"
  ```

---

## Task 17: Habits Management View

**Files:**
- Modify: `HabitTracker/Views/NEXUS/HabitsManagementView.swift`

- [ ] **Step 1: Implement HabitsManagementView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct HabitsManagementView: View {
      @Environment(\.modelContext) private var modelContext
      @Query(filter: #Predicate<Habit> { !$0.isArchived },
             sort: \Habit.sortOrder) private var habits: [Habit]
      @State private var showingAddSheet = false
      @State private var newHabitName = ""
      @State private var newHabitType: HabitType = .boolean
      @State private var newHabitDifficulty: Difficulty = .medium
      @State private var newHabitUnit = ""

      var body: some View {
          VStack(spacing: 0) {
              // Add habit bar
              HStack {
                  TextField("NEW HABIT NAME", text: $newHabitName)
                      .font(.firaCode(11))
                      .foregroundColor(.neonGreen)
                      .textFieldStyle(.plain)

                  Picker("", selection: $newHabitType) {
                      Text("BOOL").tag(HabitType.boolean)
                      Text("QTY").tag(HabitType.quantified)
                  }
                  .labelsHidden()
                  .frame(width: 70)

                  Picker("", selection: $newHabitDifficulty) {
                      ForEach(Difficulty.allCases, id: \.self) { d in
                          Text(d.label).tag(d)
                      }
                  }
                  .labelsHidden()
                  .frame(width: 70)

                  Button(action: addHabit) {
                      Text("[+ ADD]")
                          .font(.firaCode(11, weight: .bold))
                          .foregroundColor(.neonGreen)
                  }
                  .buttonStyle(.plain)
                  .disabled(newHabitName.trimmingCharacters(in: .whitespaces).isEmpty)
              }
              .padding(12)
              .background(Color.voidBlack)

              Divider().background(Color.neonGreen.opacity(0.2))

              // Habit list
              List {
                  ForEach(habits) { habit in
                      HStack {
                          Image(systemName: habit.icon)
                              .foregroundColor(Color(hex: habit.color))
                          Text(habit.name.uppercased())
                              .font(.firaCode(12))
                              .foregroundColor(.white)
                          Spacer()
                          Text(habit.difficulty.label)
                              .font(.firaCode(9))
                              .foregroundColor(.neonBlue.opacity(0.6))
                          Button(action: { archiveHabit(habit) }) {
                              Text("[ARCHIVE]")
                                  .font(.firaCode(9))
                                  .foregroundColor(.neonPink.opacity(0.5))
                          }
                          .buttonStyle(.plain)
                      }
                      .listRowBackground(Color.darkNavy)
                  }
              }
              .scrollContentBackground(.hidden)
              .background(Color.darkNavy)
          }
      }

      private func addHabit() {
          let name = newHabitName.trimmingCharacters(in: .whitespaces)
          guard !name.isEmpty else { return }
          let habit = Habit(
              name: name,
              type: newHabitType,
              difficulty: newHabitDifficulty,
              sortOrder: habits.count
          )
          if newHabitType == .quantified && !newHabitUnit.isEmpty {
              habit.unit = newHabitUnit
          }
          modelContext.insert(habit)
          try? modelContext.save()
          newHabitName = ""
          newHabitUnit = ""
      }

      private func archiveHabit(_ habit: Habit) {
          habit.isArchived = true
          try? modelContext.save()
      }
  }
  ```

- [ ] **Step 2: Build and verify, add a test habit via the UI**

  Cmd+R. Switch to [HABITS] tab in NEXUS. Add a habit. Verify it appears in the list and in the left roster.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/HabitsManagementView.swift
  git commit -m "feat: implement HabitsManagementView with add and archive"
  ```

---

## Task 18: Agent Stats View

**Files:**
- Modify: `HabitTracker/Views/NEXUS/AgentStatsView.swift`

- [ ] **Step 1: Implement AgentStatsView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct AgentStatsView: View {
      @Query private var profiles: [UserProfile]

      private var profile: UserProfile? { profiles.first }

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                  sectionHeader("AGENT STATS")

                  if let profile {
                      statsContent(profile)
                  } else {
                      Text("LOADING...")
                          .font(.firaCode(10))
                          .foregroundColor(.white.opacity(0.3))
                          .padding()
                  }
              }
          }
          .background(Color.darkNavy)
      }

      private func statsContent(_ profile: UserProfile) -> some View {
          VStack(alignment: .leading, spacing: 12) {
              // Level
              VStack(alignment: .leading, spacing: 4) {
                  Text("LVL \(profile.level)")
                      .font(.firaCode(20, weight: .bold))
                      .foregroundColor(.neonGreen)
                  Text("XP: \(profile.xp)")
                      .font(.firaCode(11))
                      .foregroundColor(.neonBlue)
                  // XP bar
                  xpBar(profile)
              }
              .padding(.horizontal, 12)

              Divider().background(Color.neonGreen.opacity(0.15))

              // Achievements
              sectionHeader("ACHIEVEMENTS")
              achievementsList(profile)
          }
          .padding(.vertical, 8)
      }

      private func xpBar(_ profile: UserProfile) -> some View {
          let xpToNext = LevelSystem.xpToNextLevel(currentXP: profile.xp)
          let xpThisLevel = profile.xp - LevelSystem.threshold(for: profile.level)
          let xpForLevel = LevelSystem.threshold(for: profile.level + 1) - LevelSystem.threshold(for: profile.level)
          let progress = xpForLevel > 0 ? Double(xpThisLevel) / Double(xpForLevel) : 0

          let total = 14
          let filled = Int(Double(total) * progress)
          let bar = String(repeating: "▓", count: filled) + String(repeating: "░", count: total - filled)

          return VStack(alignment: .leading, spacing: 2) {
              Text(bar)
                  .font(.firaCode(10))
                  .foregroundColor(.neonGreen)
              Text("\(xpToNext) XP TO NEXT LEVEL")
                  .font(.firaCode(9))
                  .foregroundColor(.white.opacity(0.4))
          }
      }

      private func achievementsList(_ profile: UserProfile) -> some View {
          let allKeys = ["streak_7", "streak_30", "level_10", "night_owl", "centurion", "perfect_week", "comeback_kid"]
          let unlockedKeys = Set(profile.achievements.map(\.key))

          return VStack(alignment: .leading, spacing: 6) {
              ForEach(allKeys, id: \.self) { key in
                  let unlocked = unlockedKeys.contains(key)
                  HStack(spacing: 6) {
                      Text(unlocked ? "◈" : "░")
                          .font(.firaCode(11))
                          .foregroundColor(unlocked ? .neonGreen : .white.opacity(0.2))
                      Text(key.uppercased().replacingOccurrences(of: "_", with: " "))
                          .font(.firaCode(10))
                          .foregroundColor(unlocked ? .white : .white.opacity(0.2))
                  }
              }
          }
          .padding(.horizontal, 12)
      }

      private func sectionHeader(_ text: String) -> some View {
          HStack {
              Text(text)
                  .font(.firaCode(10, weight: .bold))
                  .foregroundColor(.neonGreen.opacity(0.6))
              Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.voidBlack)
      }
  }
  ```

- [ ] **Step 2: Build and verify**

  Cmd+R. Open NEXUS. Expected: right column shows level, XP bar, and achievement list.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/AgentStatsView.swift
  git commit -m "feat: implement AgentStatsView with XP bar and achievement list"
  ```

---

## Task 19: Achievements View

**Files:**
- Modify: `HabitTracker/Views/NEXUS/AchievementsView.swift`

- [ ] **Step 1: Implement AchievementsView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct AchievementsView: View {
      @Query private var profiles: [UserProfile]
      private var profile: UserProfile? { profiles.first }

      private let allAchievements: [(key: String, description: String)] = [
          ("streak_7",      "7 CONSECUTIVE DAYS ON ANY HABIT"),
          ("streak_30",     "30 CONSECUTIVE DAYS ON ANY HABIT"),
          ("level_10",      "REACH LEVEL 10"),
          ("night_owl",     "LOG A HABIT AFTER 23:00 ON 5 NIGHTS"),
          ("centurion",     "100 TOTAL HABIT COMPLETIONS"),
          ("perfect_week",  "ALL HABITS COMPLETE EVERY DAY FOR 7 DAYS"),
          ("comeback_kid",  "2-DAY STREAK AFTER 7+ DAYS ABSENCE"),
      ]

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                  sectionHeader("ACHIEVEMENTS")

                  LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                      ForEach(allAchievements, id: \.key) { achievement in
                          achievementCard(achievement, profile: profile)
                      }
                  }
                  .padding(12)
              }
          }
          .background(Color.darkNavy)
      }

      private func achievementCard(_ achievement: (key: String, description: String), profile: UserProfile?) -> some View {
          let unlocked = profile?.achievements.contains { $0.key == achievement.key } == true
          let unlockedDate = profile?.achievements.first { $0.key == achievement.key }?.unlockedAt

          return VStack(alignment: .leading, spacing: 6) {
              HStack {
                  Text(unlocked ? "◈" : "░")
                      .font(.firaCode(18, weight: .bold))
                      .foregroundColor(unlocked ? .neonGreen : .white.opacity(0.15))
                  Spacer()
                  if unlocked {
                      Text("UNLOCKED")
                          .font(.firaCode(8))
                          .foregroundColor(.neonGreen.opacity(0.6))
                  }
              }

              Text(achievement.key.uppercased().replacingOccurrences(of: "_", with: " "))
                  .font(.firaCode(12, weight: .bold))
                  .foregroundColor(unlocked ? .white : .white.opacity(0.2))

              Text(achievement.description)
                  .font(.firaCode(9))
                  .foregroundColor(unlocked ? .white.opacity(0.5) : .white.opacity(0.1))
                  .lineLimit(2)

              if let date = unlockedDate {
                  Text(date, style: .date)
                      .font(.firaCode(8))
                      .foregroundColor(.neonBlue.opacity(0.5))
              }
          }
          .padding(12)
          .background(unlocked ? Color.dimGray : Color.voidBlack)
          .overlay(
              RoundedRectangle(cornerRadius: 2)
                  .stroke(unlocked ? Color.neonGreen.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
          )
      }

      private func sectionHeader(_ text: String) -> some View {
          HStack {
              Text(text)
                  .font(.firaCode(10, weight: .bold))
                  .foregroundColor(.neonGreen.opacity(0.6))
              Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.voidBlack)
      }
  }
  ```

- [ ] **Step 2: Build and verify**

  Cmd+R. Switch to [ACHIEVEMENTS] tab. Expected: grid of achievement cards, locked ones dimmed.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/AchievementsView.swift
  git commit -m "feat: implement AchievementsView with locked/unlocked card grid"
  ```

---

## Task 20: Wire Gamification (Log → XP → Level → Achievements)

**Files:**
- Create: `HabitTracker/Gamification/GamificationCoordinator.swift`
- Modify: `HabitTracker/HabitTrackerApp.swift` (inject coordinator into environment)

This task connects the log action to the full XP → level-up → achievement pipeline.

- [ ] **Step 1: Create GamificationCoordinator.swift**

  ```swift
  import Foundation
  import SwiftData

  /// Coordinates the full post-log pipeline: XP award → level check → achievement unlock.
  final class GamificationCoordinator: ObservableObject {
      private let store: HabitStore
      private let engine: AchievementEngine

      init(store: HabitStore) {
          self.store = store
          self.engine = AchievementEngine()
      }

      /// Call after successfully writing a HabitLog. Returns newly unlocked achievement keys.
      @discardableResult
      func processLog(_ log: HabitLog, allLogsForHabit: [HabitLog]) throws -> [String] {
          let profile = try store.fetchOrCreateProfile()
          let today = Calendar.current.startOfDay(for: Date())

          // Compute streak
          let completedDays = Set(allLogsForHabit.filter { $0.completed }.map {
              Calendar.current.startOfDay(for: $0.date)
          })
          var streak = 0
          var day = today
          while completedDays.contains(day) {
              streak += 1
              day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
          }

          // Sibling completion check (all active habits completed today)
          let activeHabits = try store.fetchActiveHabits()
          let todayLogs = try activeHabits.compactMap { habit -> HabitLog? in
              habit.logs.first { Calendar.current.isDateInToday($0.date) && $0.completed }
          }
          let siblingsCompleted = todayLogs.count == activeHabits.count

          // XP
          let xpGained = XPCalculator.calculate(for: log, streak: streak, siblingsCompleted: siblingsCompleted)
          profile.xp += xpGained
          profile.level = LevelSystem.level(for: profile.xp)
          profile.totalHabitsCompleted += 1

          // Achievements
          let newAchievementKeys = engine.evaluate(
              habit: log.habit!,
              allLogs: allLogsForHabit,
              profile: profile,
              today: today
          )
          for key in newAchievementKeys {
              let achievement = Achievement(key: key)
              profile.achievements.append(achievement)
          }

          try store.container.mainContext.save()
          return newAchievementKeys
      }
  }
  ```

- [ ] **Step 2: Inject coordinator into environment in AppDelegate**

  Add `@EnvironmentObject var coordinator: GamificationCoordinator` in views that handle log actions. Pass the coordinator via `.environmentObject(coordinator)` on `RootView`.

  In `applicationDidFinishLaunching`:
  ```swift
  let coordinator = GamificationCoordinator(store: store)
  mainWindowController?.window?.contentView = NSHostingView(
      rootView: RootView(renderer: anyRenderer)
          .environmentObject(coordinator)
          .modelContainer(store.container)
  )
  ```

- [ ] **Step 3: Wire coordinator at the call sites that provide HabitRowView's callbacks**

  `HabitRowView` exposes `onToggle` and `onValueSet` closures — it has no write logic itself. The log write and coordinator call belong in whichever view provides those closures. For the NEXUS roster, that is `HabitRosterView`; for the menu bar panel, that is `MenuBarPanelView`.

  In each call site, implement the closures like this:
  ```swift
  HabitRowView(
      habit: habit,
      log: todayLog,
      onToggle: {
          let log = try? store.logHabit(habit, date: Date(), completed: true)
          if let log {
              try? coordinator.processLog(log, allLogsForHabit: habit.logs)
          }
      },
      onValueSet: { value in
          let log = try? store.logHabit(habit, date: Date(), value: value)
          if let log {
              try? coordinator.processLog(log, allLogsForHabit: habit.logs)
          }
      }
  )
  ```

  Both `HabitRosterView` and `MenuBarPanelView` should declare `@EnvironmentObject var coordinator: GamificationCoordinator` and `@Environment(\.modelContext) private var modelContext` to access these dependencies.

- [ ] **Step 4: Build and run end-to-end test**

  - Add a habit via [HABITS] tab
  - Log it via the left roster or menu bar panel
  - Verify XP increases in the right column
  - Log 7 days in a row (adjust dates manually in the store for testing) and verify `streak_7` unlocks

- [ ] **Step 5: Commit**

  ```bash
  git add HabitTracker/Gamification/GamificationCoordinator.swift
  git commit -m "feat: add GamificationCoordinator wiring log → XP → level → achievements"
  ```

---

## Task 21: Reduce Motion Settings Toggle

**Files:**
- Create: `HabitTracker/Views/NEXUS/SettingsView.swift`
- Modify: `HabitTracker/Views/NEXUS/NexusView.swift` (add Settings nav tab)

- [ ] **Step 1: Create SettingsView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct SettingsView: View {
      @Query private var profiles: [UserProfile]
      private var profile: UserProfile? { profiles.first }
      @Environment(\.modelContext) private var modelContext

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                  sectionHeader("SETTINGS")

                  if let profile {
                      settingsContent(profile)
                  }
              }
          }
          .background(Color.darkNavy)
      }

      private func settingsContent(_ profile: UserProfile) -> some View {
          VStack(alignment: .leading, spacing: 16) {
              // Accessibility
              VStack(alignment: .leading, spacing: 8) {
                  Text("ACCESSIBILITY")
                      .font(.firaCode(10, weight: .bold))
                      .foregroundColor(.neonGreen.opacity(0.5))
                      .padding(.horizontal, 12)

                  Toggle(isOn: Binding(
                      get: { profile.reduceMotion },
                      set: { newValue in
                          profile.reduceMotion = newValue
                          try? modelContext.save()
                      }
                  )) {
                      VStack(alignment: .leading, spacing: 2) {
                          Text("REDUCE MOTION")
                              .font(.firaCode(12))
                              .foregroundColor(.white)
                          Text("DISABLES SCAN LINES, GLOW, AND GLITCH EFFECTS")
                              .font(.firaCode(9))
                              .foregroundColor(.white.opacity(0.4))
                      }
                  }
                  .toggleStyle(.switch)
                  .padding(.horizontal, 12)

                  if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                      Text("> SYSTEM REDUCE MOTION ACTIVE — EFFECTS DISABLED")
                          .font(.firaCode(9))
                          .foregroundColor(.neonPink.opacity(0.6))
                          .padding(.horizontal, 12)
                  }
              }
          }
          .padding(.vertical, 16)
      }

      private func sectionHeader(_ text: String) -> some View {
          HStack {
              Text(text)
                  .font(.firaCode(10, weight: .bold))
                  .foregroundColor(.neonGreen.opacity(0.6))
              Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.voidBlack)
      }
  }
  ```

- [ ] **Step 2: Add Settings tab to NexusView**

  In `CyberpunkStyle.swift`, add `case settings = "SETTINGS"` to the `NexusTab` enum.
  In `NexusView.centerPanel`, add `case .settings: SettingsView()`.

- [ ] **Step 3: Build and verify toggle works**

  Cmd+R. Open [SETTINGS] tab. Toggle Reduce Motion. Expected: scan lines and glitch effects disappear immediately; neon colors and typography remain.

- [ ] **Step 4: Commit**

  ```bash
  git add HabitTracker/Views/NEXUS/SettingsView.swift
  git commit -m "feat: add Settings panel with reduce motion accessibility toggle"
  ```

---

## Task 22: Notification Permission + Scheduling Wiring

**Files:**
- Modify: `HabitTracker/HabitTrackerApp.swift`

- [ ] **Step 1: Request notification permission on first launch**

  Add `NotificationScheduler` as a stored property on `AppDelegate` so it is not immediately deallocated:
  ```swift
  // At the top of AppDelegate, alongside menuBarController and mainWindowController:
  private var notificationScheduler: NotificationScheduler?
  ```

  In `applicationDidFinishLaunching`, after building the store:
  ```swift
  notificationScheduler = NotificationScheduler()
  let scheduler = notificationScheduler!
  Task {
      await scheduler.requestPermission()
      let habits = (try? store.fetchActiveHabits()) ?? []
      try? await scheduler.rebuild(for: habits)
  }
  ```

- [ ] **Step 2: Rebuild notifications after habit changes**

  In `HabitsManagementView`, after `addHabit()` and `archiveHabit()`, call `scheduler.rebuild(for: habits)`. Pass `scheduler` via environment or inject directly.

- [ ] **Step 3: Build and run, verify notification request dialog appears on first launch**

  Delete the app's sandbox container to simulate first launch:
  `~/Library/Containers/com.yourname.habittracker` → delete.
  Cmd+R. Expected: macOS shows notification permission dialog.

- [ ] **Step 4: Commit**

  ```bash
  git add HabitTracker/HabitTrackerApp.swift
  git commit -m "feat: wire notification permission request and schedule rebuild"
  ```

---

## Done

At this point the app has:
- Menu bar quick-log panel
- NEXUS with three-column layout and tab navigation
- SwiftData persistence (local only)
- XP formula, level system, and all achievement rules
- Reduce motion accessibility toggle (in-app + system setting)
- Scheduled daily notifications per habit
- EffectRenderer seam ready for Metal migration
