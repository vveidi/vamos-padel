import Foundation
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Сохранённый матч")
struct SavedMatchTests {
    /// Матч — это игра от первого розыгрыша, а не от запуска приложения. Между
    /// «открыл на корте» и «подали» проходит разминка, и записывать её в
    /// длительность матча значит врать в истории на телефоне (тикет 11).
    @Test("Матч начинается первым розыгрышем, а не открытием приложения")
    func theMatchStartsWithItsFirstRally() {
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: aMoment)

        saved.record(rallyWonBy: .us, at: aMoment.addingTimeInterval(10 * 60))

        #expect(saved.startedAt == aMoment.addingTimeInterval(10 * 60))
        #expect(saved.duration == 0)
    }

    @Test("Длительность — от первого розыгрыша до последнего")
    func theDurationSpansTheRallies() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(75 * 60))

        #expect(saved.duration == 75 * 60)
    }

    /// Касание по инерции после последнего очка движок не принимает, и время
    /// оно двигать тоже не должно: иначе законченный матч продолжал бы
    /// удлиняться, пока экран итога висит перед глазами.
    @Test("Розыгрыш, который движок не принял, не удлиняет матч")
    func aRejectedRallyDoesNotLengthenTheMatch() {
        var saved = SavedMatch.played(
            [.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        let finished = saved

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == finished)
    }
}
