import Foundation
import PadelScoring
import PadelStorage

@testable import PadelDelivery

/// Момент, с которого начинаются матчи в тестах. Круглая секунда намеренно:
/// хранилище держит время с точностью до миллисекунды, и круговой рейс через
/// базу и посылку должен возвращать ровно то же значение.
let aMoment = Date(timeIntervalSince1970: 1_800_000_000)

/// Матч кончается на втором очке: тестам про доставку важно, что он кончился,
/// а не то, каким счётом.
let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

extension SavedMatch {
    /// Матч, в котором сыграны перечисленные розыгрыши, по одному в секунду.
    static func played(
        _ winners: [Side],
        ruleset: Ruleset = toTwo,
        firstServer: Side = .us,
        from start: Date = aMoment
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played)))
        }

        return saved
    }
}

/// Транспорт, который никуда не везёт, но помнит, что ему отдали, и умеет
/// подтвердить доставку по требованию теста.
///
/// Заглушка возможна ровно потому, что транспорт спрятан за протоколом
/// (ADR-0002): будь на его месте `WCSession`, очередь на доставку проверялась
/// бы только парой устройств на столе.
final class FakeTransport: MatchSender, MatchReceiver, @unchecked Sendable {
    private let lock = NSLock()
    private var queued: [SavedMatch] = []
    private var confirmDelivery: (@Sendable (UUID) -> Void)?
    private var receiveMatch: (@Sendable (SavedMatch) -> Void)?

    /// Что стоит в очереди с последнего `forget()`.
    var sent: [SavedMatch] { lock.withLock { queued } }

    func send(_ match: SavedMatch) {
        lock.withLock { queued.append(match) }
    }

    func onDelivery(_ confirm: @escaping @Sendable (UUID) -> Void) {
        lock.withLock { confirmDelivery = confirm }
    }

    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
        lock.withLock { receiveMatch = receive }
    }

    /// Телефон оказался доступен: всё, что стояло в очереди, доехало.
    func confirmDelivered() {
        let confirm = lock.withLock { confirmDelivery }

        for match in sent { confirm?(match.id) }
    }

    /// Матч приехал на телефон.
    func deliver(_ match: SavedMatch) {
        lock.withLock { receiveMatch }?(match)
    }

    /// Забывает отправленное, чтобы следующая проверка говорила о новом.
    func forget() {
        lock.withLock { queued = [] }
    }
}
