import PadelScoring
import SwiftUI

/// The screen a match starts from.
///
/// Speed is what matters here. A group plays by the same rules for months, so
/// the previous match's rules are already filled in and the only thing asked is
/// what changes every time — whose serve is first. That same answer starts the
/// match: the tap by which the player names the serving side is exactly the
/// "start with one tap". A separate "Start" button next to the serve choice
/// would be a second tap that says nothing new.
///
/// The rules screen sits behind a navigation push: a setting asked before every
/// match is a tax paid for something that happens twice a year.
struct StartView: View {
    /// The ruleset the match will start with. The rules screen changes it and
    /// the store remembers it: it arrives here from the previous match.
    @Binding var ruleset: Ruleset

    /// Starts the match with the given first server.
    let onStart: (Side) -> Void

    var body: some View {
        NavigationStack {
            List {
                // The opponents on top, us at the bottom — the same as on the
                // score screen and the same as on court: they are across the
                // net, in front of us. The colours are the same, so the half
                // the player will be tapping for their own points all match is
                // recognisable before the first rally.
                serve(.them)
                serve(.us)

                NavigationLink {
                    RulesetView(ruleset: $ruleset)
                } label: {
                    rules
                }
            }
            .navigationTitle("Начать матч")
        }
    }

    private func serve(_ side: Side) -> some View {
        Button {
            onStart(side)
        } label: {
            Text(side == .us ? "Подаём мы" : "Подают соперники")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(side == .us ? ScoreView.ourColor.opacity(0.35) : .white.opacity(0.12)))
    }

    /// The rules are visible without needing to be touched: the row says what
    /// we are playing by today, and opens the screen where that is changed.
    private var rules: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(Self.name(of: ruleset))
                .font(.footnote)

            Text(Self.parameters(of: ruleset))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    /// The name of the ruleset — the one the glossary gives it. Numbers are
    /// not substituted in: "Счёт до 21 очков" would need declension, whereas
    /// "Счёт до N очков" is a name, and the N in it explains the row below.
    private static func name(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic: "Классический счёт"
        case .pointsTo: "Счёт до N очков"
        }
    }

    private static func parameters(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            "\(sets(setsToWin)) · \(goldenPoint ? "золотое очко" : "без золотого очка")"
        case .pointsTo(let target, let serveChangesEvery):
            "N = \(target) · X = \(serveChangesEvery)"
        }
    }

    /// The rules screen offers no more than three sets, so there are exactly
    /// two grammatical cases to handle.
    private static func sets(_ count: Int) -> String {
        count == 1 ? "1 сет" : "\(count) сета"
    }
}

#Preview("Classic scoring") {
    @Previewable @State var ruleset = Ruleset.defaultClassic

    StartView(ruleset: $ruleset, onStart: { _ in })
}

#Preview("The match to N points") {
    @Previewable @State var ruleset = Ruleset.pointsTo(target: 21, serveChangesEvery: 2)

    StartView(ruleset: $ruleset, onStart: { _ in })
}
