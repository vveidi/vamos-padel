/// The sides' points in the current game — what the screen shows in large
/// type.
///
/// The shape of the score is part of the rules, not of the presentation: in a
/// match to N points and in a tiebreak the points are simply counted, while in
/// a game of classic scoring those very same rallies are called 15/30/40. So
/// the way points are named is kept together with the counters instead of
/// being chosen on screen: naming a game's points with a number, or a
/// tiebreak's points "forty", is impossible.
public enum Points: Equatable, Sendable {
    /// Points as a number: the match to N points, and the tiebreak.
    case count(SideCounts)

    /// A game of classic scoring.
    case game(SideCounts)

    /// The rallies won by each side. What the label is made from — and,
    /// unlike the label itself, fit for arithmetic. It does not leave the
    /// package: outside, the score is read with the eyes; it is computed here.
    var counts: SideCounts {
        switch self {
        case .count(let counts), .game(let counts): counts
        }
    }

    /// Whether not a single rally has been played in this game.
    ///
    /// A question, not arithmetic — which is why it is here and the counters
    /// are not. The match card asks it of a match stopped early: was it
    /// stopped in the middle of a game, or exactly on the boundary of one.
    public var isEmpty: Bool { counts == SideCounts() }

    /// What a side's score is called.
    ///
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

    /// The names of a game's points, in order. The length of the ladder is
    /// itself a rule: that many points win a game, and one rung earlier deuce
    /// begins. That is why the game's thresholds are taken from here rather
    /// than written out as numbers in the engine: otherwise the rule would
    /// live in two places and drift apart at the first edit.
    private static let ladder = ["0", "15", "30", "40"]

    /// How many points win a game when it never reaches deuce.
    static var pointsInGame: Int { ladder.count }

    /// The score at which deuce begins.
    private static var deuce: Int { ladder.count - 1 }

    /// After deuce the counters keep growing — 4:3, 5:4 — but there are only
    /// three ways to say it: deuce, advantage, and behind. So past the third
    /// point only the difference between the counters matters, not how large
    /// they are.
    private static func gameLabel(for side: Side, counts: SideCounts) -> String {
        let own = counts[side]
        let other = counts[side.opposite]

        guard own >= deuce && other >= deuce else {
            return ladder[min(max(own, 0), deuce)]
        }

        return own > other ? "AD" : ladder[deuce]
    }
}
