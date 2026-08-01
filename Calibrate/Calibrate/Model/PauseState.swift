import Foundation

enum PauseSource: Equatable {
    case manual
    case schedule(id: UUID)
}

enum PauseState: Equatable {
    case inactive
    case active(until: Date, source: PauseSource)

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    var endsAt: Date? {
        if case let .active(until, _) = self { return until }
        return nil
    }
}
