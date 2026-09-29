public struct Rally: Equatable, Sendable {
    public let winner: Side

    public init(wonBy winner: Side) {
        self.winner = winner
    }
}
