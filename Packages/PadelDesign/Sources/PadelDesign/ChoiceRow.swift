import SwiftUI

/// The watch's way of setting anything: a row that says what a value is, and
/// opens a page to change it.
///
/// **One control for the ruleset and for the numbers alike.** "Classic against
/// To N points" and "sets to win: 2" are the same act on a 198pt screen — pick
/// one of a short list — and the wrist has no room to draw them two different
/// ways. So there is no segmented control here and no ± anywhere: the row
/// names the value, the page lists what it could be, a tap picks and comes
/// back.
///
/// **The crown still crosses 5...40 in one turn**, which is what the spec's
/// "The crown survives the rules screen" was protecting. It does it by
/// scrolling the page rather than by spinning a value in place, so nothing
/// here binds `digitalCrownRotation` and no row has to be focused before it
/// will move. The page opens already scrolled to what is chosen, so 21 is one
/// short turn from 21 rather than sixteen from 5.
///
/// **No chevron.** The brief is "no navigation bar, no list rows, no
/// chevron-and-separator", and the value at the trailing edge is drawn in
/// `ball` — which in this app means exactly *this is yours, or this is chosen*
/// (ADR-0006). The one lit thing on an otherwise quiet row is the affordance,
/// and a chevron beside it would be the system's furniture back again.
///
/// ```swift
/// ChoiceRow(
///     Text("Scoring"),
///     selection: $isClassic,
///     options: [
///         .init(Text("Classic"), value: true),
///         .init(Text("To N points"), value: false),
///     ])
///
/// ChoiceRow(Text("Sets to win"), value: $setsToWin, in: 1...3)
/// ```
///
/// The phone chooses with ``SegmentedChoice`` and ``StepperRow`` instead,
/// which is why this is unavailable there: two controls that both mean "pick
/// one" should not be reachable from the same screen, and which one a platform
/// gets is a decision made once, here, rather than at every call site.
@available(iOS, unavailable)
public struct ChoiceRow<Value: Hashable>: View {
    /// One thing the value could be.
    ///
    /// The label is a `Text` and not a `LocalizedStringKey`, because this
    /// package owns no words: the catalog lives in the app and the screens do
    /// the speaking.
    public struct Option: Identifiable {
        let label: Text
        let value: Value

        public var id: Value { value }

        public init(_ label: Text, value: Value) {
            self.label = label
            self.value = value
        }
    }

    private let label: Text
    private let options: [Option]

    @Binding private var selection: Value

    public init(_ label: Text, selection: Binding<Value>, options: [Option]) {
        self.label = label
        self.options = options
        _selection = selection
    }

    public var body: some View {
        NavigationLink {
            ChoiceList(title: label, options: options, selection: $selection)
        } label: {
            row
        }
        .buttonStyle(.plain)
    }

    private var row: some View {
        // Beside each other while the label leaves room, and above each other
        // when it stops. "Подача через (X)" at the largest setting is wider
        // than a watch on its own, and a row that kept the value beside it
        // would be a row with the label cut off.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ControlMetrics.rowGap) {
                labelText
                Spacer(minLength: ControlMetrics.rowGap)
                chosenText
            }

            VStack(alignment: .leading, spacing: ControlMetrics.rowGap) {
                labelText
                chosenText.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, ControlMetrics.rowPaddingVertical)
        .frame(maxWidth: .infinity, minHeight: ControlMetrics.rowHeight)
        .contentShape(Rectangle())
        // One element and not two: VoiceOver reading a label and then a value
        // as separate stops is a way of hearing a row and not knowing it opens
        // anything.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(chosen?.label ?? Text(verbatim: ""))
    }

    private var labelText: some View {
        label
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.control))
            .multilineTextAlignment(.leading)
    }

    private var chosenText: some View {
        (chosen?.label ?? Text(verbatim: ""))
            .textStyle(.control)
            .foregroundStyle(.ball)
            .multilineTextAlignment(.trailing)
    }

    private var chosen: Option? {
        options.first { $0.value == selection }
    }
}

// MARK: - A number is a choice too

@available(iOS, unavailable)
extension ChoiceRow where Value == Int {
    /// A number from a range, which is the same control with its options
    /// counted out.
    ///
    /// A numeral standing on its own says the same thing in both languages —
    /// `RulesetView` has made that argument since the app had one language —
    /// so the options are `verbatim` and the catalog is never asked for a key
    /// of "%lld".
    public init(_ label: Text, value: Binding<Int>, in range: ClosedRange<Int>) {
        self.init(
            label,
            selection: value,
            options: range.map { .init(Text(verbatim: "\($0)"), value: $0) })
    }
}

// MARK: - The page it opens

/// The list a ``ChoiceRow`` pushes: every option down the screen, the chosen
/// one ringed, a tap picking it and coming straight back.
///
/// Coming back on the tap rather than on a "Done" is the same argument
/// `RulesetView` already makes about leaving the screen: there is nothing to
/// confirm, and an extra tap is the very thing a wrist cannot afford.
///
/// It keeps watchOS's own title and back chevron. The brief's "no navigation
/// bar" is about the screens the boards draw; a pushed page that hid its way
/// back would be a page a player can only leave by choosing something.
@available(iOS, unavailable)
private struct ChoiceList<Value: Hashable>: View {
    let title: Text
    let options: [ChoiceRow<Value>.Option]

    @Binding var selection: Value

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { page in
            ScrollView {
                VStack(spacing: ControlMetrics.segmentGap) {
                    ForEach(options) { option in
                        Button {
                            selection = option.value
                            dismiss()
                        } label: {
                            ChoiceCapsule(
                                label: option.label, isChosen: option.value == selection)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            option.value == selection ? .isSelected : [])
                    }
                }
                .padding(.horizontal, ControlMetrics.cardPadding)
            }
            // Opened on what is chosen and not at the top: the range 5...40 is
            // 36 capsules, and a page that always started at 5 would make the
            // crown do the work the row was opened to avoid.
            .onAppear { page.scrollTo(selection, anchor: .center) }
        }
        .background(Color.night)
        .navigationTitle(title)
    }
}
