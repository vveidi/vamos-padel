import PadelDelivery
import PadelLogging
import Pulse
import PulseUI
import SwiftUI

struct DiagnosticsConsole: View {
    @Environment(\.logSender) private var sender

    @State private var sending = Sending.ready

    var body: some View {
        NavigationStack {
            // Pulse opens on its network tab by default, and the app has
            // no network of its own.
            ConsoleView(mode: .logs)
                .toolbar {
                    // The top bar's two places are taken: the sheet's close
                    // button and Pulse's settings.
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: send) {
                            Label("Send to iPhone", systemImage: sending.symbol)
                        }
                        .disabled(sending == .copying)
                    }
                }
        }
    }

    private func send() {
        sending = .copying

        Task {
            sending = await Self.send(through: sender)
        }
    }

    /// Off the main actor: the copy reads the whole database.
    @concurrent private static func send(through sender: any LogSender) async -> Sending {
        let snapshot: LogSnapshot

        do {
            let outgoing = URL.applicationSupportDirectory.appending(path: "Outgoing logs")
            try FileManager.default.createDirectory(at: outgoing, withIntermediateDirectories: true)

            snapshot = try LoggerStore.shared.snapshot(into: outgoing)
        } catch {
            logger.error("the log store was not copied: \(error.localizedDescription)")

            return .failed
        }

        do {
            try sender.send(snapshot)

            return .queued
        } catch {
            try? FileManager.default.removeItem(at: snapshot.database)

            return .failed
        }
    }

    /// `queued` is as far as the watch can know: the phone does not answer.
    private enum Sending {
        case ready, copying, queued, failed

        var symbol: String {
            switch self {
            case .ready, .copying: "iphone.and.arrow.forward"
            case .queued: "checkmark"
            case .failed: "exclamationmark.triangle"
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var logSender: any LogSender = NoMatchTransport()
}

nonisolated private let logger = PadelLogger(subsystem: "com.vveidi.padel.watchkitapp", category: "diagnostics")
