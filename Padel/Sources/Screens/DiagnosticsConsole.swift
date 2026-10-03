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
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
