/// Единица игры, которая заканчивается тем, что одна из сторон получает очко.
///
/// Наименьшее событие, которое приложение записывает.
public struct Rally: Equatable, Sendable {
    /// Сторона, выигравшая розыгрыш.
    public let winner: Side

    public init(wonBy winner: Side) {
        self.winner = winner
    }
}

