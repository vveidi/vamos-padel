import PadelStorage

/// What the host broadcasts after every change. `echo` is `nil` when the host
/// sent it on its own rather than in answer to an intent.
public enum MatchUpdate: Equatable, Sendable {
    case match(SavedMatch, echo: Echo?)
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
