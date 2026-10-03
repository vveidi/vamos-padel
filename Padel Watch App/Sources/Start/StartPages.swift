import PadelDesign
import PadelScoring
import SwiftUI

struct StartPages: View {
    @Binding var ruleset: Ruleset

    @Binding var recordsToHealth: Bool

    @Binding var startsPaired: Bool

    @Binding var tapMode: TapMode

    let onStart: (Side) -> Void

    private enum Page {
        case start
        case settings
    }

    var body: some View {
        TabView {
            StartView(onStart: onStart)
                .tag(Page.start)

            StartSettings(
                ruleset: $ruleset, recordsToHealth: $recordsToHealth,
                startsPaired: $startsPaired, tapMode: $tapMode)
                .tag(Page.settings)
        }
        .tabViewStyle(.verticalPage)
    }
}

private struct StartSettings: View {
    @Binding var ruleset: Ruleset

    @Binding var recordsToHealth: Bool

    @Binding var startsPaired: Bool

    @Binding var tapMode: TapMode

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RulesetSettings(ruleset: $ruleset).padding(.top, Board.titleGap)

                    TapModeSettings(tapMode: $tapMode).padding(.top, Board.cardGap)

                    SettingsCard {
                        health

                        pairing
                    }
                    .padding(.top, Board.cardGap)
                }
                .padding(.horizontal, Board.inset)
                .padding(.bottom, Board.inset)
            }
            .background {
                Color.night
                    .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
                    .ignoresSafeArea()
            }
            .navigationTitle("Settings")
        }
    }

    /// Worded as what the app will do, not as the name of a feature: "Health"
    /// alone is a noun the two languages decline differently.
    private var health: some View {
        Toggle(isOn: $recordsToHealth) { label("Record to Health") }
            .toggleStyle(.ball)
    }

    private var pairing: some View {
        Toggle(isOn: $startsPaired) { label("Score on iPhone") }
            .toggleStyle(.ball)
    }

    private func label(_ words: LocalizedStringKey) -> some View {
        Text(words)
            .textStyle(.control)
            .foregroundStyle(.ink.weight(.control))
            // Two lines already at the default setting in both languages:
            // the switch takes a third of the row. The scale factor covers
            // the settings past that, where a third line would push the
            // switch off the card.
            .lineLimit(2)
            .minimumScaleFactor(0.7)
    }
}

/// The start, rules and tap-mode boards' pixels halved — the watch artboards
/// were 2x (`docs/design/README.md`, "Reading the boards").
private enum Board {
    /// The board's 16px.
    static let inset: CGFloat = 8

    /// The rules board gave the title a 46px band and started the controls
    /// under it.
    static let titleGap: CGFloat = 10

    /// The board's 12px.
    static let cardGap: CGFloat = 6

    /// The rules board's 0.12, the bottom of the range ``Floodlight``
    /// documents: there is no court here for it to cross.
    static let floodlight: Double = 0.12
}

#if DEBUG

private func start(_ ruleset: Ruleset, recordsToHealth: Bool = true) -> some View {
    StartScreen(ruleset: ruleset, recordsToHealth: recordsToHealth)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private struct StartScreen: View {
    @State var ruleset: Ruleset

    @State var recordsToHealth: Bool

    @State private var startsPaired = false

    @State private var tapMode = TapMode.multiTap

    var body: some View {
        StartPages(
            ruleset: $ruleset, recordsToHealth: $recordsToHealth, startsPaired: $startsPaired,
            tapMode: $tapMode, onStart: { _ in })
    }
}

private func settingsFoot(_ tapMode: TapMode, startsPaired: Bool = false) -> some View {
    SettingsFoot(tapMode: tapMode, startsPaired: startsPaired)
}

private struct SettingsFoot: View {
    @State var tapMode: TapMode

    @State var startsPaired: Bool

    @State private var ruleset = Ruleset.classic(setsToWin: 2, goldenPoint: true)

    @State private var recordsToHealth = true

    var body: some View {
        StartSettings(
            ruleset: $ruleset, recordsToHealth: $recordsToHealth,
            startsPaired: $startsPaired, tapMode: $tapMode)
            .defaultScrollAnchor(.bottom)
    }
}

#Preview("Classic scoring") { start(.defaultClassic) }

#Preview("In Russian: classic scoring") { inRussian(start(.defaultClassic)) }

#Preview("Two sets") { start(.classic(setsToWin: 2, goldenPoint: false)) }

#Preview("In Russian: two sets") {
    inRussian(start(.classic(setsToWin: 2, goldenPoint: false)))
}

#Preview("The match to N points") { start(.pointsTo(target: 21, serveChangesEvery: 2)) }

#Preview("In Russian: the match to N points") {
    inRussian(start(.pointsTo(target: 21, serveChangesEvery: 2)))
}

#Preview("At the largest type: two sets") {
    atLargestType(start(.classic(setsToWin: 2, goldenPoint: true)))
}

#Preview("In Russian, at the largest type: two sets") {
    atLargestType(inRussian(start(.classic(setsToWin: 2, goldenPoint: true))))
}

#Preview("At the largest type: the match to N points") {
    atLargestType(start(.pointsTo(target: 21, serveChangesEvery: 2)))
}

#Preview("In Russian, at the largest type: the match to N points") {
    atLargestType(inRussian(start(.pointsTo(target: 21, serveChangesEvery: 2))))
}

#Preview("Health turned off") { start(.defaultClassic, recordsToHealth: false) }

#Preview("The settings page's foot: multi-tap") { settingsFoot(.multiTap) }

#Preview("In Russian: the settings page's foot: multi-tap") {
    inRussian(settingsFoot(.multiTap))
}

#Preview("The settings page's foot: tap zones") { settingsFoot(.tapZones) }

#Preview("In Russian: the settings page's foot: tap zones") {
    inRussian(settingsFoot(.tapZones))
}

#Preview("Scored on iPhone") { settingsFoot(.multiTap, startsPaired: true) }

#Preview("In Russian: scored on iPhone") { inRussian(settingsFoot(.multiTap, startsPaired: true)) }

#Preview("At the largest type: the settings page's foot") {
    atLargestType(settingsFoot(.tapZones))
}

#Preview("In Russian, at the largest type: the settings page's foot") {
    atLargestType(inRussian(settingsFoot(.tapZones)))
}

#endif
