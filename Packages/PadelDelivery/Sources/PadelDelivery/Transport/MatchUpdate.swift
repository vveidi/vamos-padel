import PadelStorage

/// What the scorer broadcasts after every change. `echo` is `nil` when the scorer
/// sent it on its own rather than in answer to an intent.
public enum MatchUpdate: Equatable, Sendable {
    /// A match that is not paired is the phone's alone: the remote may draw it
    /// and is refused anything it asks of it.
    case match(SavedMatch, isPaired: Bool, echo: Echo?)
    case noMatch(echo: Echo?)
}

public struct Echo: Equatable, Sendable {
    public let intent: MatchIntent
    public let accepted: Bool

    public init(intent: MatchIntent, accepted: Bool) {
        self.intent = intent
        self.accepted = accepted
    }
}
