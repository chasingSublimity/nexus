import Foundation

protocol Clock {
    var now: Date { get }
}

struct SystemClock: Clock {
    nonisolated var now: Date { Date() }
}

struct MockClock: Clock {
    nonisolated var now: Date
    nonisolated init(_ date: Date) { self.now = date }
}
