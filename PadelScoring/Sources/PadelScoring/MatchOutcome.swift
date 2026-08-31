/// Чем закончился матч.
///
/// Недоигранный матч — прекращённый досрочно — станет отдельным исходом
/// в тикете 09.
public enum MatchOutcome: Equatable, Sendable {
    case inProgress
    case finished(winner: Side)

    public var isFinished: Bool {
        winner != nil
    }

    /// Сторона, выигравшая матч, если он закончен.
    public var winner: Side? {
        switch self {
        case .inProgress: nil
        case .finished(let winner): winner
        }
    }
}
