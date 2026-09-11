import Testing

/// The plural forms, pinned.
///
/// Until the catalog these forms were computed — a hand-written Russian table
/// with a second function for the genitive after "до" — and a function can be
/// read and reasoned about. They are data now, four Russian forms and two
/// English ones per key sitting in `Shared/Localizable.xcstrings`, and data
/// rots without a sound: a form under the wrong category does not crash, does
/// not warn, and does not show up until it is on a screen in front of a
/// player. So every number the rules screen can produce is resolved here, in
/// both languages, against a sentence written out below by hand.
///
/// Written out, and not computed. A test that derived the form from a rule
/// would be that deleted table standing again on the far side of the
/// assertion, agreeing with itself about the numbers it had already got wrong.
@Suite("The plural forms")
struct PluralFormsTests {
    /// N — the target of a match to N points. The rules screen offers 5 to 40.
    ///
    /// This is the key the genitive lives in, and the reason the range is
    /// walked whole rather than sampled: Russian changes form on the last two
    /// digits, so 21 and 31 are two separate chances to get it wrong.
    @Test("Scoring to N points", arguments: Reading.pointsTo)
    func scoringToPoints(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("Scoring to \(reading.number) points", in: reading.language)))
    }

    /// X — how many rallies the serve stays on one side. The screen offers 1
    /// to 6.
    ///
    /// English drops the number at one: "Serve changes every rally", not
    /// "every 1 rally". A category may say something other than the number and
    /// a noun, and here it should.
    @Test("Serve changes every X rallies", arguments: Reading.serveChanges)
    func serveChangesEveryRallies(_ reading: Reading) {
        #expect(
            reading.matches(Catalog.text("Serve changes every \(reading.number) rallies", in: reading.language))
        )
    }

    /// The sets a classic match is played to, 1 to 3, as the phone names the
    /// rules a finished match was scored by.
    @Test("Classic scoring · N sets", arguments: Reading.classicScoring)
    func classicScoringSets(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("Classic scoring · \(reading.number) sets", in: reading.language)))
    }

    /// The same count as a clause on its own — the watch's start screen under
    /// the name of the ruleset, and VoiceOver reading the score out.
    ///
    /// Zero because a match is at nil sets until the first one is won, and
    /// three because that is as far as the rules screen goes.
    @Test("N sets", arguments: Reading.sets)
    func sets(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) sets", in: reading.language)))
    }

    /// The target as a clause on its own — the watch's start screen under the
    /// name of the ruleset, where the row used to read "N = 16".
    ///
    /// Counted the ordinary way and not after "до", which is the whole reason
    /// it is pinned separately from the sentence above: here 21 takes *очко*
    /// and 22 *очка*, and the genitive below turns that pair around.
    @Test("N points", arguments: Reading.points)
    func points(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) points", in: reading.language)))
    }

    /// The sentence at the foot of the watch's rules screen, which says the
    /// classic match back in words. 1 to 3, the sets the screen offers.
    ///
    /// One set is a different sentence and not a shorter one — "First to 1
    /// sets" is not English and "Матч до 1 выигранных сетов" is not Russian —
    /// so the `one` category restates the whole line in both languages, which
    /// is exactly the kind of thing that is only visible once it is pinned.
    @Test("First to N sets", arguments: Reading.matchToSets)
    func matchToSets(_ reading: Reading) {
        #expect(
            reading.matches(
                Catalog.text(
                    "First to \(reading.number) sets. A set is 6 games, a tiebreak at 6:6.",
                    in: reading.language))
        )
    }

    /// The games of the current set, read out by VoiceOver: none yet at the
    /// start of a set, and seven at the end of one won 7:6.
    @Test("N games", arguments: Reading.games)
    func games(_ reading: Reading) {
        #expect(reading.matches(Catalog.text("\(reading.number) games", in: reading.language)))
    }

    // MARK: The genitive after "до"

    /// The case the hand-written table needed a second function for, and the
    /// one that is easiest to break by hand in the catalog.
    ///
    /// Counted the ordinary way, Russian would say "21 очко" and "22 очка" —
    /// the noun agreeing with the numeral. After "до" it does not: the noun
    /// goes into the genitive, and there 21 takes the singular *очка* while 22
    /// takes the plural *очков*. So the shorter word belongs to the larger
    /// number, which is exactly the pair a careless edit swaps.
    @Test("After «до» 21 takes the genitive singular and 22 the genitive plural")
    func theGenitiveAfterDo() {
        #expect(Catalog.text("Scoring to \(21) points", in: .ru) == "Счёт до 21 очка")
        #expect(Catalog.text("Scoring to \(22) points", in: .ru) == "Счёт до 22 очков")
    }
}

/// One number, in one language, and the whole sentence the app is expected to
/// say for it.
struct Reading: Sendable, CustomTestStringConvertible {
    let language: Language
    let number: Int
    let sentence: String

    var testDescription: String { "\(language.rawValue): \(sentence)" }

    func matches(_ text: String) -> Bool { text == sentence }
}

extension Reading {
    /// Every number in a range, each with the sentence it is expected to read.
    ///
    /// The ranges below are the answer, not a derivation of it: each line says
    /// "these numbers say this", and the boundaries between the lines are
    /// where Russian changes form.
    private static func spread(
        _ language: Language,
        _ numbers: ClosedRange<Int>,
        _ sentence: (Int) -> String
    ) -> [Reading] {
        numbers.map { Reading(language: language, number: $0, sentence: sentence($0)) }
    }

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

    /// The whole range the rules screen offers, for the same reason as
    /// `pointsTo`: Russian changes form on the last two digits, so 21, 22, 31
    /// and 32 are four separate chances to get it wrong.
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

    /// The two sentences the `one` category restates rather than counts are
    /// written out here beside the two it counts, so that the line the screen
    /// draws for a one-set match is in this file rather than inferred from the
    /// three-set one.
    static let matchToSets: [Reading] =
        spread(.en, 1...1, { _ in "A single set of 6 games, a tiebreak at 6:6." })
            + spread(.en, 2...3, { "First to \($0) sets. A set is 6 games, a tiebreak at 6:6." })
            + spread(.ru, 1...1, { _ in "Один сет: 6 геймов, на 6:6 тай-брейк." })
            + spread(
                .ru, 2...3,
                { "Матч до \($0) выигранных сетов. Сет — 6 геймов, на 6:6 тай-брейк." })

    static let games: [Reading] =
        spread(.en, 0...0, { "\($0) games" })
            + spread(.en, 1...1, { "\($0) game" })
            + spread(.en, 2...7, { "\($0) games" })
            + spread(.ru, 0...0, { "\($0) геймов" })
            + spread(.ru, 1...1, { "\($0) гейм" })
            + spread(.ru, 2...4, { "\($0) гейма" })
            + spread(.ru, 5...7, { "\($0) геймов" })
}
