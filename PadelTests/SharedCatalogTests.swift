import Testing

/// One catalog, two apps.
///
/// `Shared/Localizable.xcstrings` is a member of both targets, so the phone
/// ships the watch's sentences and the watch ships the phone's. That is the
/// arrangement everything else here rests on — it is why the watch needs no
/// test target of its own, and this suite is the only thing that checks it
/// rather than assuming it.
///
/// The keys below are the watch's alone: nothing in `Padel/` says them. Found
/// in the phone's own bundle, they can only have come from the shared file.
@Suite("The shared catalog")
struct SharedCatalogTests {
    /// The label of a rules row — the watch's settings page. The phone reads a
    /// match already played and never sets this number, so the sentence has no
    /// reason to exist on the phone at all.
    ///
    /// The Russian is what carries the proof. English is the source language,
    /// so a key that resolved to nothing would still come back as its own
    /// English text and the two would be indistinguishable; a key that
    /// resolved to nothing in Russian comes back in English, and that is
    /// visible.
    ///
    /// It used to be "Point scoring", the name the watch gave a ruleset on the
    /// row that pushed the rules screen. That row went when the rules moved
    /// onto the settings page itself, and a test whose subject nothing says
    /// any more proves less than one whose subject is on screen.
    @Test("A watch rules label is in the phone's bundle")
    func theWatchsRulesLabel() {
        #expect(Catalog.text("Serve changes every", in: .ru) == "Смена подачи через")
        #expect(Catalog.text("Serve changes every", in: .en) == "Serve changes every")
    }

    /// A VoiceOver action on the watch's score screen, and a second key from a
    /// different file: one shared key could be an accident of a single
    /// sentence, two are the file.
    ///
    /// The outcome screen says the shorter of the two on a button rather than
    /// in an action — three lines of Russian is taller than the button it
    /// stands under. Both are pinned, because a sentence that lost the word
    /// they differ by would leave the app saying the same thing twice and
    /// nothing would notice.
    @Test("The watch's undo is in the phone's bundle, in both its lengths")
    func theWatchsUndoAction() {
        #expect(Catalog.text("Undo the last rally", in: .ru) == "Отменить последний розыгрыш")
        #expect(Catalog.text("Undo the rally", in: .en) == "Undo the rally")
        #expect(Catalog.text("Undo the rally", in: .ru) == "Отменить розыгрыш")
    }

    /// The half the serve comes from, as VoiceOver says it on the score
    /// screen. Three whole clauses and not one with a fragment glued on — so
    /// three keys, and the two new ones are pinned here the way the plural
    /// forms are pinned: the sentence written out by hand, in both languages.
    ///
    /// The right and the left are the server's own. The screen mirrors the
    /// opponents' zone and the spoken score does not, which is a difference
    /// worth reading twice before either sentence is "fixed" to agree with the
    /// picture.
    @Test("The watch names the half the serve comes from, in both languages")
    func theServingHalf() {
        #expect(Catalog.text("serving from the right", in: .en) == "serving from the right")
        #expect(Catalog.text("serving from the right", in: .ru) == "подача справа")
        #expect(Catalog.text("serving from the left", in: .en) == "serving from the left")
        #expect(Catalog.text("serving from the left", in: .ru) == "подача слева")
    }

    /// The switch on the watch's settings page — the one sentence the redesign
    /// added rather than moved.
    ///
    /// Health is a product name and Apple has already translated it, so the
    /// Russian says Здоровье rather than a word for health. Pinning it is what
    /// stops the next edit "translating" the app's name for the app.
    @Test("The watch's switch for Health is in the phone's bundle")
    func theHealthSwitch() {
        #expect(Catalog.text("Record to Health", in: .en) == "Record to Health")
        #expect(Catalog.text("Record to Health", in: .ru) == "Записывать в Здоровье")
    }

    /// The clause the golden point turns over at the foot of the rules screen.
    /// The rest of that sentence counts sets and is pinned with the other
    /// plural forms; these two count nothing and are only ever one of the
    /// pair, which is what makes them easy to edit into agreeing with each
    /// other.
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
