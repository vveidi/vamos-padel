import Testing

@testable import PadelScoring

@Suite("Подающая сторона")
struct ServingSideTests {
    // MARK: Счёт до N очков

    @Test("До первого розыгрыша подаёт тот, кто назван первым подающим", arguments: [Side.us, .them])
    func theFirstServerServesTheFirstRally(firstServer: Side) {
        #expect(pointsToState([], firstServer: firstServer).servingSide == firstServer)
    }

    @Test("Подача переходит каждые X розыгрышей и возвращается через 2X")
    func serveChangesEveryXRallies() {
        // Кто выигрывает розыгрыши, на подачу не влияет — важно их число.
        let winners: [Side] = [.us, .them, .them, .us, .us, .them, .us, .them]

        for played in 0...8 {
            let expected: Side = (played / 4) % 2 == 0 ? .us : .them

            #expect(pointsToState(Array(winners.prefix(played))).servingSide == expected)
        }
    }

    @Test("При X = 1 подача переходит после каждого розыгрыша")
    func serveChangesEveryRallyWhenXIsOne() {
        #expect(pointsToState([], every: 1).servingSide == .us)
        #expect(pointsToState([.them], every: 1).servingSide == .them)
        #expect(pointsToState([.them, .them], every: 1).servingSide == .us)
        #expect(pointsToState([.them, .them, .us], every: 1).servingSide == .them)
    }

    /// X приходит со стартового экрана (тикет 06) и может оказаться нулём;
    /// делить на него — не тот способ об этом сообщить.
    @Test("X меньше единицы не роняет матч, а ведёт себя как X = 1", arguments: [0, -2])
    func serveChangeBelowOneBehavesLikeOne(every: Int) {
        #expect(pointsToState([.us], every: every).servingSide == .them)
    }

    // MARK: Классический счёт

    @Test("В классическом счёте подача переходит после каждого гейма")
    func serveChangesAfterEveryGame() {
        // Внутри гейма подача не двигается.
        for played in 0...3 {
            #expect(classicState(rallies(.us, played)).servingSide == .us)
        }

        #expect(classicState(gamesWonBy([.us])).servingSide == .them)
        #expect(classicState(gamesWonBy([.us, .them])).servingSide == .us)
        #expect(classicState(gamesWonBy([.us, .them, .them])).servingSide == .them)
    }

    @Test("Подача не сбивается на границе сета")
    func theSetBoundaryDoesNotDisturbTheServe() {
        // Шесть геймов позади — подача вернулась к нам, и новый сет ничего
        // в этом не меняет.
        let firstSet = gamesWonBy([.us, .us, .us, .us, .us, .us])

        #expect(classicState(firstSet, setsToWin: 2).servingSide == .us)
        #expect(classicState(firstSet + gamesWonBy([.them]), setsToWin: 2).servingSide == .them)
    }

    @Test("Первая подача переносится и на классический счёт")
    func theFirstServerCarriesIntoClassic() {
        #expect(classicState([], firstServer: .them).servingSide == .them)
        #expect(classicState(gamesWonBy([.us]), firstServer: .them).servingSide == .us)
    }

    // MARK: Тай-брейк

    /// Тай-брейк — единственное место, где подача ходит не по границе гейма:
    /// первый розыгрыш подаёт тот, чья очередь, дальше меняются каждые два.
    @Test("В тай-брейке подача переходит после первого очка, затем каждые два")
    func theTieBreakServeChangesAfterOnePointThenEveryTwo() {
        // Двенадцать геймов позади — очередь снова наша.
        let expected: [Side] = [.us, .them, .them, .us, .us, .them, .them, .us, .us]

        // Очки в тай-брейке делятся поровну: иначе он кончится раньше, чем
        // ротация подачи успеет пройти круг.
        let traded: [Side] = (0..<expected.count).map { $0.isMultiple(of: 2) ? .us : .them }

        for (played, side) in expected.enumerated() {
            let state = classicState(toSixAll + Array(traded.prefix(played)))

            #expect(state.games == SideCounts(us: 6, them: 6))
            #expect(state.servingSide == side)
        }
    }

    // MARK: Через матч

    @Test("Матч отдаёт подачу, считая от своей первой")
    func theMatchServesFromItsOwnFirstServer() {
        var match = Match(ruleset: .defaultPointsTo, firstServer: .them)

        #expect(match.state.servingSide == .them)

        for _ in 0..<4 { match.record(rallyWonBy: .us) }

        #expect(match.state.servingSide == .us)
    }
}

// MARK: - Постройка журналов

private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

private func pointsToState(
    _ winners: [Side], every: Int = 4, firstServer: Side = .us
) -> MatchState {
    MatchState(
        // Цель заведомо недостижима: тикет про подачу, а не про конец матча.
        ruleset: .pointsTo(target: 99, serveChangesEvery: every),
        journal: journal(winners),
        firstServer: firstServer)
}

private func classicState(
    _ winners: [Side], setsToWin: Int = 3, firstServer: Side = .us
) -> MatchState {
    MatchState(
        ruleset: .classic(setsToWin: setsToWin, goldenPoint: true),
        journal: journal(winners),
        firstServer: firstServer)
}

private func journal(_ winners: [Side]) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}

private func rallies(_ side: Side, _ count: Int) -> [Side] {
    Array(repeating: side, count: count)
}

private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { rallies($0, 4) }
}
