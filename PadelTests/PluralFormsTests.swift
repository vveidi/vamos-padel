import Testing

/// The forms are data in `Shared/Localizable.xcstrings`, and data rots without
/// a sound: a form filed under the wrong category neither crashes nor warns.
/// So every sentence below is written out by hand — one derived from a rule
/// would agree with itself about the numbers it had already got wrong.
@Suite("The plural forms")
struct PluralFormsTests {
    @Test("Scoring to N points", arguments: Reading.pointsTo)
    func scoringToPoints(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("Scoring to \(reading.number) points", in: reading.language)))
    }

    @Test("Serve changes every X rallies", arguments: Reading.serveChanges)
    func serveChangesEveryRallies(_ reading: Reading) {
        #expect(
            reading.matches(Catalog.text("Serve changes every \(reading.number) rallies", in: reading.language))
        )
    }

    @Test("Classic scoring · N sets", arguments: Reading.classicScoring)
    func classicScoringSets(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("Classic scoring · \(reading.number) sets", in: reading.language)))
    }

    @Test("N sets", arguments: Reading.sets)
    func sets(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) sets", in: reading.language)))
    }

    @Test("N points", arguments: Reading.points)
    func points(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) points", in: reading.language)))
    }

    @Test("First to N sets", arguments: Reading.matchToSets)
    func matchToSets(_ reading: Reading) {
        #expect(
            reading.matches(
                Catalog.text(
                    "First to \(reading.number) sets. A set is 6 games, a tiebreak at 6:6.",
                    in: reading.language))
        )
    }

    @Test("N games", arguments: Reading.games)
    func games(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) games", in: reading.language)))
    }

    @Test("N matches", arguments: Reading.matches)
    func matches(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) matches", in: reading.language)))
    }

    // MARK: The genitive after "до"

    /// Counted the ordinary way Russian says "21 очко" and "22 очка", the noun
    /// agreeing with the numeral. After "до" the noun goes into the genitive
    /// and the pair turns around: 21 takes the singular *очка* and 22 the
    /// plural *очков*, so the shorter word belongs to the larger number.
    @Test("After «до» 21 takes the genitive singular and 22 the genitive plural")
    func theGenitiveAfterDo() {
        #expect(Catalog.text("Scoring to \(21) points", in: .ru) == "Счёт до 21 очка")
        #expect(Catalog.text("Scoring to \(22) points", in: .ru) == "Счёт до 22 очков")
    }
}

struct Reading: Sendable, CustomTestStringConvertible {
    let language: Language
    let number: Int
    let sentence: String

    var testDescription: String { "\(language.rawValue): \(sentence)" }

    func matches(_ text: String) -> Bool { text == sentence }
}

extension Reading {
    private static func spread(
        _ language: Language,
        _ numbers: ClosedRange<Int>,
        _ sentence: (Int) -> String
    ) -> [Reading] {
        numbers.map { Reading(language: language, number: $0, sentence: sentence($0)) }
    }

    /// Walked whole rather than sampled: Russian changes form on the last two
    /// digits, so 21 and 31 are separate chances to get it wrong.
    static let pointsTo: [Reading] =
        spread(.en, 5...40, { "Scoring to \($0) points" })
            + spread(.ru, 5...20, { "Счёт до \($0) очков" })
            + spread(.ru, 21...21, { "Счёт до \($0) очка" })
            + spread(.ru, 22...30, { "Счёт до \($0) очков" })
            + spread(.ru, 31...31, { "Счёт до \($0) очка" })
            + spread(.ru, 32...40, { "Счёт до \($0) очков" })

    static let serveChanges: [Reading] =
        spread(.en, 1...1, { _ in "Serve changes every rally" })
            + spread(.en, 2...6, { "Serve changes every \($0) rallies" })
            + spread(.ru, 1...1, { "Смена подачи через \($0) розыгрыш" })
            + spread(.ru, 2...4, { "Смена подачи через \($0) розыгрыша" })
            + spread(.ru, 5...6, { "Смена подачи через \($0) розыгрышей" })

    static let classicScoring: [Reading] =
        spread(.en, 1...1, { "Classic scoring · \($0) set" })
            + spread(.en, 2...3, { "Classic scoring · \($0) sets" })
            + spread(.ru, 1...1, { "Классический счёт · \($0) сет" })
            + spread(.ru, 2...3, { "Классический счёт · \($0) сета" })

    static let points: [Reading] =
        spread(.en, 5...40, { "\($0) points" })
            + spread(.ru, 5...20, { "\($0) очков" })
            + spread(.ru, 21...21, { "\($0) очко" })
            + spread(.ru, 22...24, { "\($0) очка" })
            + spread(.ru, 25...30, { "\($0) очков" })
            + spread(.ru, 31...31, { "\($0) очко" })
            + spread(.ru, 32...34, { "\($0) очка" })
            + spread(.ru, 35...40, { "\($0) очков" })

    static let sets: [Reading] =
        spread(.en, 0...0, { "\($0) sets" })
            + spread(.en, 1...1, { "\($0) set" })
            + spread(.en, 2...3, { "\($0) sets" })
            + spread(.ru, 0...0, { "\($0) сетов" })
            + spread(.ru, 1...1, { "\($0) сет" })
            + spread(.ru, 2...3, { "\($0) сета" })

    static let matchToSets: [Reading] =
        spread(.en, 1...1, { _ in "A single set of 6 games, a tiebreak at 6:6." })
            + spread(.en, 2...3, { "First to \($0) sets. A set is 6 games, a tiebreak at 6:6." })
            + spread(.ru, 1...1, { _ in "Один сет: 6 геймов, на 6:6 тай-брейк." })
            + spread(
                .ru, 2...3,
                { "Матч до \($0) выигранных сетов. Сет — 6 геймов, на 6:6 тай-брейк." })

    static let matches: [Reading] =
        spread(.en, 1...1, { "\($0) match" })
            + spread(.en, 2...40, { "\($0) matches" })
            + spread(.ru, 1...1, { "\($0) матч" })
            + spread(.ru, 2...4, { "\($0) матча" })
            + spread(.ru, 5...20, { "\($0) матчей" })
            + spread(.ru, 21...21, { "\($0) матч" })
            + spread(.ru, 22...24, { "\($0) матча" })
            + spread(.ru, 25...30, { "\($0) матчей" })
            + spread(.ru, 31...31, { "\($0) матч" })
            + spread(.ru, 32...34, { "\($0) матча" })
            + spread(.ru, 35...40, { "\($0) матчей" })

    static let games: [Reading] =
        spread(.en, 0...0, { "\($0) games" })
            + spread(.en, 1...1, { "\($0) game" })
            + spread(.en, 2...7, { "\($0) games" })
            + spread(.ru, 0...0, { "\($0) геймов" })
            + spread(.ru, 1...1, { "\($0) гейм" })
            + spread(.ru, 2...4, { "\($0) гейма" })
            + spread(.ru, 5...7, { "\($0) геймов" })
}
