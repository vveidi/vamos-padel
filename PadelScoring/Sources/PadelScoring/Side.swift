/// Одна из двух пар на корте.
///
/// В v1 стороны обезличены: приложение знает «нашу» сторону и «соперников»,
/// но не знает, кто именно играет.
public enum Side: String, Sendable, CaseIterable {
    case us
    case them

    /// Сторона напротив сетки.
    public var opposite: Side {
        switch self {
        case .us: .them
        case .them: .us
        }
    }
}


