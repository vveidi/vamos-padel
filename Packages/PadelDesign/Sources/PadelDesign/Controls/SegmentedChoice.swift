import SwiftUI

/// A choice between two options, drawn as two capsules side by side, the
/// chosen one ringed in `ball`. The watch picks the same value with
/// ``ChoiceRow``, which has room to read two labels where this does not.
@available(watchOS, unavailable)
public struct SegmentedChoice<Value: Equatable>: View {
    /// One side of the choice. The label is a `Text` and not a
    /// `LocalizedStringKey` because this package owns no words — a control
    /// that took a key would resolve it against the wrong bundle.
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
        // Side by side while both labels fit, stacked when they stop: at the
        // largest Dynamic Type setting the pair is wider than a phone.
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
