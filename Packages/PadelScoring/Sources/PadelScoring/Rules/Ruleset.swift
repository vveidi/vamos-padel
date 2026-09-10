/// The data that decides how the score is computed from the rally journal and
/// when the match is over.
///
/// Data precisely, not a branch in the code: "today we play to 9 games" has to
/// become a different value, not a different branch of the engine.
public enum Ruleset: Equatable, Sendable {
    /// Classic padel scoring: 15/30/40, games, sets, a tiebreak at 6:6.
    ///
    /// `setsToWin` is how many sets have to be won, not how many will be
    /// played: a match to two sets lasts two or three. With `goldenPoint`,
    /// deuce is settled by a single decisive point instead of playing on for
    /// a two-point lead.
    case classic(setsToWin: Int, goldenPoint: Bool)

    /// A match to `target` points; the serve passes to the other side every
    /// `serveChangesEvery` rallies.
    case pointsTo(target: Int, serveChangesEvery: Int)

    /// A match longer than a single set.
    ///
    /// A question for the ruleset, not for the screen. In a match to one set
    /// there is no set score worth showing: it stays 0:0 until the very last
    /// rally. In a match to two it cannot be left out: games reset with every
    /// set, and "4 : 1" without sets does not say who is ahead in the match.
    ///
    /// `MatchState.finalScore` settles the same question when it picks the
    /// score the match will be remembered by — and the two answers have to
    /// agree.
    public var isMultiSet: Bool {
        switch self {
        case .classic(let setsToWin, _): setsToWin > 1
        case .pointsTo: false
        }
    }

    /// The starting values are picked for an amateur game on a court paid
    /// for by the hour; after that the app remembers the previous match's
    /// ruleset — the start screen fills it in by asking the store.
    public static let defaultClassic = Ruleset.classic(setsToWin: 1, goldenPoint: true)

    public static let defaultPointsTo = Ruleset.pointsTo(target: 16, serveChangesEvery: 4)
}
