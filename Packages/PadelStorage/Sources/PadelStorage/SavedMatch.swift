import Foundation
import PadelScoring

/// Матч, каким его помнит хранилище: сам матч плюс когда он игрался.
///
/// Матч в движке — это набор правил и журнал розыгрышей, больше ничего
/// (ADR-0001). Времени в нём нет и быть не должно: счёт от него не зависит,
/// а истории на телефоне (тикеты 11, 12) без него нечего показать. Поэтому
/// время живёт здесь, снаружи движка, и матч остаётся тем, чем был.
public struct SavedMatch: Equatable, Sendable, Identifiable {
    /// Кто этот матч. Заводится один раз при первом розыгрыше и не меняется:
    /// по нему хранилище узнаёт, что перед ним тот же матч, а не новый, — и по
    /// нему же телефон отличит матч, доставленный дважды (тикет 10).
    public let id: UUID

    public var match: Match

    /// Момент первого розыгрыша.
    public var startedAt: Date

    /// Момент последнего розыгрыша.
    public var lastRallyAt: Date

    /// Сколько матч длился.
    ///
    /// Вычисляется из двух моментов, а не хранится третьим числом, по той же
    /// причине, по которой не хранится счёт (ADR-0001): величину, которую
    /// кто-то обязан поддерживать в актуальном состоянии, однажды забудут
    /// обновить. Конец матча здесь — последний розыгрыш, а не «сейчас»:
    /// матч, прерванный севшей батареей, длился до последнего очка, а не до
    /// момента, когда его открыли заново.
    public var duration: TimeInterval { lastRallyAt.timeIntervalSince(startedAt) }

    /// `lastRallyAt` по умолчанию совпадает с началом: у матча, в котором ещё
    /// не сыграно ни одного розыгрыша, длительность нулевая.
    public init(
        id: UUID = UUID(), match: Match, startedAt: Date, lastRallyAt: Date? = nil
    ) {
        self.id = id
        self.match = match
        self.startedAt = startedAt
        self.lastRallyAt = lastRallyAt ?? startedAt
    }
}

extension SavedMatch {
    /// Записывает розыгрыш и запоминает, когда он случился.
    ///
    /// Матч начинается первым розыгрышем — так его определяет глоссарий, — а
    /// не запуском приложения: между «открыл приложение на корте» и «подали»
    /// проходит разминка, и она не длительность матча.
    ///
    /// Розыгрыш, который движок не принял (матч уже закончен), не двигает и
    /// время: иначе касание по инерции удлиняло бы законченный матч.
    public mutating func record(rallyWonBy side: Side, at moment: Date) {
        let journalBefore = match.journal

        match.record(rallyWonBy: side)

        guard match.journal != journalBefore else { return }

        if journalBefore.isEmpty { startedAt = moment }
        lastRallyAt = moment
    }
}
