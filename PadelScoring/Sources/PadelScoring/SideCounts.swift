/// Пара счётчиков, по одному на каждую сторону.
///
/// Отдельный тип, а не два поля рядом, потому что читать счёт нужно по
/// стороне: `points[rally.winner]`. Разбор стороны при этом никуда не
/// девается — он собран здесь, вместо того чтобы повторяться в каждом месте,
/// где счёт читают или наращивают.
public struct SideCounts: Equatable, Sendable {
    public let us: Int
    public let them: Int

    public init(us: Int = 0, them: Int = 0) {
        self.us = us
        self.them = them
    }

    public subscript(side: Side) -> Int {
        switch side {
        case .us: us
        case .them: them
        }
    }

    /// Счётчики с прибавленной единицей у указанной стороны.
    func incrementing(_ side: Side) -> SideCounts {
        switch side {
        case .us: SideCounts(us: us + 1, them: them)
        case .them: SideCounts(us: us, them: them + 1)
        }
    }
}
