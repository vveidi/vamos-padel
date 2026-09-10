import SwiftUI

/// A choice between two options, drawn as two capsules side by side, the
/// chosen one ringed in `ball`.
///
/// **The phone's control, and only the phone's.** It needs both labels legible
/// beside each other, which a 198pt screen does not have: "Классический"
/// against "По очкам" on a wrist is two columns two words wide. The watch
/// picks the same value with ``ChoiceRow``, which names it on a row and opens
/// a page — same act, same capsules, room to read them.
///
/// **Two options, and not n.** "Classic" against "By points" is the whole of
/// its job, and the app has exactly two rulesets. A general n-way control is a
/// thing to build the day a third one exists — until then it would be a
/// parameter with one value, and a `ForEach` where two named sides read
/// better.
///
/// Not a `Picker` restyled. `.pickerStyle(.segmented)` is the system's control
/// with the system's proportions and the system's idea of a selection, and the
/// brief for this package is that none of the five controls is one of those.
/// What is kept is the shape underneath: each side is a real `Button`, so
/// VoiceOver gets a button without being told, and the chosen one carries
/// `.isSelected` the way the system's segments do.
///
/// ```swift
/// SegmentedChoice(
///     selection: $isClassic,
///     .init(Text("Classic"), value: true),
///     .init(Text("By points"), value: false))
/// ```
@available(watchOS, unavailable)
public struct SegmentedChoice<Value: Equatable>: View {
    /// One side of the choice: what it says, and what choosing it means.
    ///
    /// The label is a `Text` and not a `LocalizedStringKey`, because this
    /// package owns no words. The catalog lives in the app, the screens do the
    /// speaking, and a control that took a key would be resolving it against
    /// the wrong bundle to no one's benefit.
    public struct Option {
        let label: Text
        let value: Value

        public init(_ label: Text, value: Value) {
            self.label = label
            self.value = value
        }
    }

    @Binding private var selection: Value

    private let one: Option
    private let other: Option

    public init(selection: Binding<Value>, _ one: Option, _ other: Option) {
        _selection = selection
        self.one = one
        self.other = other
    }

    public var body: some View {
        // Side by side while both labels fit, and stacked when they stop
        // fitting. At the largest Dynamic Type setting the pair is wider than
        // a phone, and the choice between wrapping them into two illegible
        // columns and dropping one under the other is not a close one.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ControlMetrics.segmentGap) { capsules }
            VStack(spacing: ControlMetrics.segmentGap) { capsules }
        }
    }

    @ViewBuilder private var capsules: some View {
        capsule(one)
        capsule(other)
    }

    private func capsule(_ option: Option) -> some View {
        let isChosen = option.value == selection

        return Button {
            selection = option.value
        } label: {
            ChoiceCapsule(label: option.label, isChosen: isChosen, place: .besideItsTwin)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
