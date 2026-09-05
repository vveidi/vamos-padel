/// A unit of play that ends with one of the sides winning a point.
///
/// The smallest event the app records.
public struct Rally: Equatable, Sendable {
    /// The side that won the rally.
    public let winner: Side

    public init(wonBy winner: Side) {
        self.winner = winner
    }
}
