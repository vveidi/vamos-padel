public enum Points: Equatable, Sendable {
    case count(SideCounts)

    case game(SideCounts)

    var counts: SideCounts {
        switch self {
        case .count(let counts), .game(let counts): counts
        }
    }

    public var isEmpty: Bool { counts == SideCounts() }

    /// 15/30/40 is padel's own notation, not a translation: the digits and
    /// `AD` are the same in any language, so the label lives in the engine,
    /// next to the rule that produces it.
    public func label(for side: Side) -> String {
        switch self {
        case .count(let counts):
            "\(counts[side])"
        case .game(let counts):
            Self.gameLabel(for: side, counts: counts)
        }
    }

    private static let ladder = ["0", "15", "30", "40"]

    static var pointsInGame: Int { ladder.count }

    static var deuce: Int { ladder.count - 1 }

    private static func gameLabel(for side: Side, counts: SideCounts) -> String {
        let own = counts[side]
        let other = counts[side.opposite]

        guard own >= deuce && other >= deuce else {
            return ladder[min(max(own, 0), deuce)]
        }

        return own > other ? "AD" : ladder[deuce]
    }
}
