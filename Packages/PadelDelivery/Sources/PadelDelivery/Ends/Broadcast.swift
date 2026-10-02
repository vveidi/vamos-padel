import Foundation
import Synchronization

/// Every value to every listener in the order it was sent, and the latest one
/// first to a listener that arrives late — unless made with `keepsLatest: false`.
final class Broadcast<Value: Sendable>: Sendable {
    private struct Listeners {
        var latest: Value?
        var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
    }

    private let listeners: Mutex<Listeners>
    private let keepsLatest: Bool

    init(_ initial: Value? = nil, keepsLatest: Bool = true) {
        listeners = Mutex(Listeners(latest: initial))
        self.keepsLatest = keepsLatest
    }

    func send(_ value: Value) {
        listeners.withLock { [keepsLatest] listeners in
            if keepsLatest { listeners.latest = value }

            for continuation in listeners.continuations.values { continuation.yield(value) }
        }
    }

    func stream() -> AsyncStream<Value> {
        let id = UUID()

        return AsyncStream { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.listeners.withLock { _ = $0.continuations.removeValue(forKey: id) }
            }

            listeners.withLock { listeners in
                listeners.continuations[id] = continuation

                if let latest = listeners.latest { continuation.yield(latest) }
            }
        }
    }
}
