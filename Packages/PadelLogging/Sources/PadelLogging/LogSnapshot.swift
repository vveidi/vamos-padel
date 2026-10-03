import CoreData
import Foundation
import Pulse

/// A store's messages copied out to travel as one file. The manifest goes
/// beside it rather than in it: Pulse wipes a store found without one.
public struct LogSnapshot: Sendable {
    /// A SQLite file with no journal, so nothing else is needed to open it.
    public let database: URL

    public let manifest: Data

    public init(database: URL, manifest: Data) {
        self.database = database
        self.manifest = manifest
    }
}

extension LoggerStore {
    /// Writes a new file into `directory`, which must exist. Blobs stay behind:
    /// they hold network bodies, and the app has no network.
    /// - Important: Pulse 5.2 cannot open its own `.pulse` export, only a store
    ///   package, so this copies the database the way that export does.
    public func snapshot(into directory: URL) throws -> LogSnapshot {
        let database = directory.appending(path: "\(UUID().uuidString).sqlite")

        try copyDatabase(to: database)

        return LogSnapshot(
            database: database,
            manifest: try Data(contentsOf: storeURL.appending(path: PulseLayout.manifest)))
    }

    private func copyDatabase(to target: URL) throws {
        let coordinator = container.persistentStoreCoordinator

        guard let source = coordinator.persistentStores.first, let sourceURL = source.url else {
            throw LogSnapshotError.noDatabase
        }

        let copier = NSPersistentStoreCoordinator(managedObjectModel: coordinator.managedObjectModel)
        let opened = try copier.addPersistentStore(
            type: NSPersistentStore.StoreType(rawValue: source.type),
            configuration: source.configurationName, at: sourceURL,
            options: source.options ?? [:])

        _ = try copier.migratePersistentStore(
            opened, to: target, options: [NSSQLitePragmasOption: ["journal_mode": "OFF"]],
            type: .sqlite)
    }
}

public enum LogSnapshotError: Error {
    /// The store is kept in memory, as only a test's is.
    case noDatabase
}

/// One store received from elsewhere, kept in `directory`; a new one replaces
/// the last. ``keep(_:)`` runs one call at a time; ``open()`` may run beside it.
public struct LatestLogStore: Sendable {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    private var current: URL { directory.appending(path: "latest.pulse") }

    /// Takes the snapshot's database file: it is gone from where it was.
    public func keep(_ snapshot: LogSnapshot) throws {
        let files = FileManager.default
        let incoming = directory.appending(path: "incoming-\(UUID().uuidString).pulse")

        defer { try? files.removeItem(at: incoming) }

        try files.createDirectory(at: incoming, withIntermediateDirectories: true)
        try files.moveItem(at: snapshot.database, to: incoming.appending(path: PulseLayout.database))
        try snapshot.manifest.write(to: incoming.appending(path: PulseLayout.manifest))

        if files.fileExists(atPath: current.path) {
            _ = try files.replaceItemAt(current, withItemAt: incoming)
        } else {
            try files.moveItem(at: incoming, to: current)
        }
    }

    /// `nil` until a store has been kept.
    public func open() throws -> LoggerStore? {
        guard FileManager.default.fileExists(atPath: current.path) else { return nil }

        return try LoggerStore(storeURL: current, options: [.readonly])
    }
}

/// Pulse's names for the files inside a store package, which it keeps to itself.
private enum PulseLayout {
    static let database = "logs.sqlite"
    static let manifest = "manifest.json"
}
