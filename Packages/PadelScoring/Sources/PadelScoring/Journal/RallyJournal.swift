/// The ordered sequence of a match's rallies — the single stored truth about
/// the match.
///
/// The score is computed from the journal and is nowhere stored alongside it
/// (ADR-0001). Undoing the last point is therefore the removal of the last
/// entry rather than arithmetic run backwards, and the journal cannot drift
/// out of sync with the score.
public struct RallyJournal: Equatable, Sendable {
    public private(set) var rallies: [Rally]

    public init(_ rallies: [Rally] = []) {
        self.rallies = rallies
    }

    public var count: Int { rallies.count }

    public var isEmpty: Bool { rallies.isEmpty }

    /// The last rally played, if there was one.
    public var last: Rally? { rallies.last }

    /// Records a rally won by the given side.
    public mutating func append(wonBy side: Side) {
        rallies.append(Rally(wonBy: side))
    }

    /// Removes the last rally and returns it.
    ///
    /// On an empty journal it does nothing and returns `nil`: undo pressed
    /// before the first point must not break anything.
    @discardableResult
    public mutating func removeLast() -> Rally? {
        rallies.popLast()
    }
}
