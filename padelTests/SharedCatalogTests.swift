import Testing

/// One catalog, two apps.
///
/// `Shared/Localizable.xcstrings` is a member of both targets, so the phone
/// ships the watch's sentences and the watch ships the phone's. That is the
/// arrangement everything else here rests on — it is why the watch needs no
/// test target of its own, and this suite is the only thing that checks it
/// rather than assuming it.
///
/// The keys below are the watch's alone: nothing in `padel/` says them. Found
/// in the phone's own bundle, they can only have come from the shared file.
@Suite("The shared catalog")
struct SharedCatalogTests {
    /// The name of a ruleset about to be chosen — the watch's start screen.
    /// The phone names a ruleset already played and puts the numbers in it, so
    /// this sentence has no reason to exist on the phone at all.
    ///
    /// The Russian is what carries the proof. English is the source language,
    /// so a key that resolved to nothing would still come back as its own
    /// English text and the two would be indistinguishable; a key that
    /// resolved to nothing in Russian comes back in English, and that is
    /// visible.
    @Test("The watch's name for the match to N points is in the phone's bundle")
    func theWatchsRulesetName() {
        #expect(Catalog.text("Match to N points", in: .ru) == "Счёт до N очков")
        #expect(Catalog.text("Match to N points", in: .en) == "Match to N points")
    }

    /// A VoiceOver action on two of the watch's screens, and a second key from
    /// a different file: one shared key could be an accident of a single
    /// sentence, two are the file.
    @Test("The watch's undo action is in the phone's bundle")
    func theWatchsUndoAction() {
        #expect(Catalog.text("Undo the last rally", in: .ru) == "Отменить последний розыгрыш")
    }
}
