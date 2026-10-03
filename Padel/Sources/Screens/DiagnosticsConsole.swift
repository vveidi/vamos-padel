import PadelLogging
import Pulse
import PulseUI
import SwiftUI

struct DiagnosticsConsole: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // `.all` reopens Pulse's last tab, which starts as its network one,
            // and the app has no network.
            ConsoleView(mode: .logs)
                .closeButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink("Watch logs") { WatchLogs() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

private struct WatchLogs: View {
    @State private var opened: Opened?

    var body: some View {
        Group {
            switch opened {
            case nil:
                ProgressView()
            case .store(let store):
                ConsoleView(store: store, mode: .logs)
                    .closeButtonHidden()
            case .nothingYet:
                ContentUnavailableView(
                    "No watch logs yet", systemImage: "applewatch",
                    description: Text("Send them from the console on the watch."))
            case .failed:
                ContentUnavailableView(
                    "The watch logs did not open", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Watch logs")
        .task { opened = Self.open() }
    }

    private static func open() -> Opened {
        do {
            return try LatestLogStore.fromTheWatch.open().map(Opened.store) ?? .nothingYet
        } catch {
            logger.error("the watch's log store did not open: \(error.localizedDescription)")

            return .failed
        }
    }

    private enum Opened {
        case store(LoggerStore)
        case nothingYet
        case failed
    }
}

private let logger = PadelLogger(subsystem: "com.vveidi.padel", category: "diagnostics")
