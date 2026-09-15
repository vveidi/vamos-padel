import SwiftUI

/// The watch's way of setting anything: a row that says what a value is, and
/// opens a page to change it.
@available(iOS, unavailable)
public struct ChoiceRow<Value: Hashable>: View {
    /// One thing the value could be. The label is a `Text` and not a
    /// `LocalizedStringKey` because this package owns no words — the catalog
    /// lives in the app.
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
        HStack(spacing: ControlMetrics.rowGapToChevron) {
            // The value under the label and never beside it, so each gets the
            // row's whole width. "Подача через (X)" is wider than a watch
            // before the value is put anywhere, and a row that stacked only on
            // running out of room would be one text tall in English, two in Russian.
            VStack(alignment: .leading, spacing: ControlMetrics.rowGap) {
                labelText
                chosenText
            }

            Spacer(minLength: 0)

            Chevron()
        }
        .padding(.vertical, ControlMetrics.rowPaddingVertical)
        .frame(
            maxWidth: .infinity, minHeight: ControlMetrics.stackedRowHeight,
            alignment: .leading)
        .contentShape(Rectangle())
        // One element and not two: VoiceOver reading the label and the value as
        // separate stops is a way of hearing a row and not knowing it opens.
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
            .multilineTextAlignment(.leading)
    }

    private var chosen: Option? {
        options.first { $0.value == selection }
    }
}

// MARK: - A number is a choice too

@available(iOS, unavailable)
extension ChoiceRow where Value == Int {
    /// A numeral standing on its own says the same thing in both languages, so
    /// the options are `verbatim` and the catalog is never asked for a "%lld".
    public init(_ label: Text, value: Binding<Int>, in range: ClosedRange<Int>) {
        self.init(
            label,
            selection: value,
            options: range.map { .init(Text(verbatim: "\($0)"), value: $0) })
    }
}

// MARK: - The page it opens

/// The list a ``ChoiceRow`` pushes, one capsule per option. It keeps watchOS's
/// title and back chevron: a pushed page that hid its bar could only be left by
/// choosing, and the edge swipe is no substitute for Back.
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
                                label: option.label, isChosen: option.value == selection,
                                place: .downThePage)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            option.value == selection ? .isSelected : [])
                    }
                }
                .padding(.horizontal, ControlMetrics.cardPadding)
            }
            // Opened on what is chosen and not at the top: 5...40 is 36
            // capsules, and starting at 5 would make the crown do the work the
            // row was opened to avoid.
            .onAppear { page.scrollTo(selection, anchor: .center) }
        }
        .background(Color.night)
        .navigationTitle(title)
    }
}
