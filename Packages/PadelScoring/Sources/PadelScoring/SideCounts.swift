/// A pair of counters, one per side.
///
/// A type of its own rather than two fields side by side, because the score
/// has to be read by side: `points[rally.winner]`. The switch over the side
/// does not go away — it is gathered here instead of being repeated in every
/// place where the score is read or incremented.
public struct SideCounts: Equatable, Sendable {
    public let us: Int
    public let them: Int

    public init(us: Int = 0, them: Int = 0) {
        self.us = us
        self.them = them
    }

    /// Both sides together: rallies, games or sets played.
    public var total: Int { us + them }

    public subscript(side: Side) -> Int {
        switch side {
        case .us: us
        case .them: them
        }
    }

    /// The counters with one added to the given side.
    func incrementing(_ side: Side) -> SideCounts {
        switch side {
        case .us: SideCounts(us: us + 1, them: them)
        case .them: SideCounts(us: us, them: them + 1)
        }
    }
}
