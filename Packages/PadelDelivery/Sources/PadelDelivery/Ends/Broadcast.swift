import Foundation

/// Every value to every listener in the order it was sent, and the latest one
/// first to a listener that arrives late.
final class Broadcast<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var latest: Value?
    private var listeners: [UUID: AsyncStream<Value>.Continuation] = [:]

    init(_ initial: Value? = nil) {
        latest = initial
    }

    func send(_ value: Value) {
        lock.withLock {
            latest = value

            for listener in listeners.values { listener.yield(value) }
        }
    }

    func stream() -> AsyncStream<Value> {
        let id = UUID()

        return AsyncStream { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.listeners.removeValue(forKey: id) }
            }

            lock.withLock {
                listeners[id] = continuation

                if let latest { continuation.yield(latest) }
            }
        }
    }
}
