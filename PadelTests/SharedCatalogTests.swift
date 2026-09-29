import Testing

/// `Shared/Localizable.xcstrings` is a member of both app targets, so the phone
/// ships the watch's sentences and the watch ships the phone's. The keys below
/// are the watch's alone — nothing in `Padel/` says them — so finding them in
/// the phone's own bundle is the only check there is on that membership.
@Suite("The shared catalog")
struct SharedCatalogTests {
    @Test("A watch rules label is in the phone's bundle")
    func theWatchsRulesLabel() {
        #expect(Catalog.text("Serve changes every", in: .ru) == "Смена подачи через")
        #expect(Catalog.text("Serve changes every", in: .en) == "Serve changes every")
    }

    @Test("The watch's undo is in the phone's bundle, in both its lengths")
    func theWatchsUndoAction() {
        #expect(Catalog.text("Undo the last rally", in: .ru) == "Отменить последний розыгрыш")
        #expect(Catalog.text("Undo the rally", in: .en) == "Undo the rally")
        #expect(Catalog.text("Undo the rally", in: .ru) == "Отменить розыгрыш")
    }

    /// The right and the left are the server's own, not the screen's: ADR-0013
    /// keeps the mirroring a drawing concern, so these disagree with the
    /// picture on purpose.
    @Test("The watch names the half the serve comes from, in both languages")
    func theServingHalf() {
        #expect(Catalog.text("serving from the right", in: .en) == "serving from the right")
        #expect(Catalog.text("serving from the right", in: .ru) == "подача справа")
        #expect(Catalog.text("serving from the left", in: .en) == "serving from the left")
        #expect(Catalog.text("serving from the left", in: .ru) == "подача слева")
    }

    /// Health is Apple's product name and Apple has already translated it, so
    /// the Russian is Здоровье rather than a word for health.
    @Test("The watch's switch for Health is in the phone's bundle")
    func theHealthSwitch() {
        #expect(Catalog.text("Record to Health", in: .en) == "Record to Health")
        #expect(Catalog.text("Record to Health", in: .ru) == "Записывать в Здоровье")
    }

    @Test("The watch says what deuce is, both ways and in both languages")
    func theTwoWaysToPlayDeuce() {
        #expect(Catalog.text("Deuce is one point.", in: .en) == "Deuce is one point.")
        #expect(
            Catalog.text("Deuce is one point.", in: .ru)
                == "При счёте «ровно» — одно решающее очко.")
        #expect(
            Catalog.text("Deuce is played out to a two-point lead.", in: .en)
                == "Deuce is played out to a two-point lead.")
        #expect(
            Catalog.text("Deuce is played out to a two-point lead.", in: .ru)
                == "При счёте «ровно» — игра до преимущества в два очка.")
    }
}
