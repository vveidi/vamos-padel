public enum Ruleset: Equatable, Sendable {
    /// `setsToWin` is how many sets have to be won, not how many will be
    /// played: a match to two sets lasts two or three.
    case classic(setsToWin: Int, goldenPoint: Bool)

    /// A match to `target` points; the serve passes to the other side every
    /// `serveChangesEvery` rallies.
    case pointsTo(target: Int, serveChangesEvery: Int)

    /// `MatchState.finalScore` settles the same question when it picks the
    /// score the match will be remembered by — and the two answers have to
    /// agree.
    public var isMultiSet: Bool {
        switch self {
        case .classic(let setsToWin, _): setsToWin > 1
        case .pointsTo: false
        }
    }

    public static let defaultClassic = Ruleset.classic(setsToWin: 1, goldenPoint: true)

    public static let defaultPointsTo = Ruleset.pointsTo(target: 16, serveChangesEvery: 4)
}
