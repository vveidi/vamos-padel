public enum Side: String, Sendable, CaseIterable {
    case us
    case them

    public var opposite: Side {
        switch self {
        case .us: .them
        case .them: .us
        }
    }

    /// The side serving after `changes` service changes.
    func alternating(_ changes: Int) -> Side {
        changes % 2 == 0 ? self : opposite
    }
}
