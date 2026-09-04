import Foundation
import Testing

/// The package is pure domain logic: it knows nothing about the UI, the store
/// or the watch's system frameworks (ticket 01, ADR-0003).
///
/// The check is built as an allowlist, not a denylist. A denylist is incomplete
/// by its very nature: today it holds nine modules, tomorrow a tenth appears,
/// and the guard silently lets a violation through. What is allowed, on the
/// other hand, is known exactly.
///
/// The compiler covers only part of the ban on its own: UIKit, WatchKit,
/// HealthKit and WatchConnectivity are unavailable on macOS, where the tests
/// run. SwiftUI and SwiftData are available to every target on every Apple
/// platform — the compiler will never complain about them, and it is exactly
/// that gap the tests below close.
@Suite("Package isolation")
struct PackageIsolationTests {
    /// The engine currently needs no module at all, Foundation included.
    ///
    /// A line appearing here should be a deliberate decision, not a side
    /// effect of somebody else's edit — that is the whole point of an
    /// allowlist.
    static let allowedModules: Set<String> = []

    static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()  // PadelScoringTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // the package root

    @Test("The package sources import nothing beyond what is allowed")
    func sourcesImportOnlyAllowedModules() throws {
        let sourcesRoot = Self.packageRoot.appending(path: "Sources/PadelScoring")

        let swiftFiles = try FileManager.default
            .subpathsOfDirectory(atPath: sourcesRoot.path(percentEncoded: false))
            .filter { $0.hasSuffix(".swift") }

        // Otherwise, on an empty list of files, the guard silently passes.
        #expect(!swiftFiles.isEmpty, "no sources found — the guard is useless")

        for file in swiftFiles {
            let source = try String(
                contentsOf: sourcesRoot.appending(path: file), encoding: .utf8)

            for importedModule in Self.importedModules(in: source) {
                #expect(
                    Self.allowedModules.contains(importedModule),
                    "\(file) imports \(importedModule), which is not on the allowlist")
            }
        }
    }

    /// Checking imports is not enough: a dependency can be declared in the
    /// manifest and imported in no file at all — the linking has happened
    /// regardless. The ban from ADR-0003 is structural, so it has to be
    /// checked structurally.
    @Test("The package declares no external dependencies")
    func packageDeclaresNoExternalDependencies() throws {
        let manifest = try String(
            contentsOf: Self.packageRoot.appending(path: "Package.swift"), encoding: .utf8)

        #expect(
            !manifest.contains(".package("),
            "an external dependency appeared in Package.swift — the engine must stay pure")
    }

    /// The names of the modules imported in a source file. Comment lines are
    /// skipped so that mentioning a module in documentation does not fail the
    /// test.
    static func importedModules(in source: String) -> [String] {
        source.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("//") else { return nil }

            let words = trimmed.split(separator: " ").map(String.init)
            guard let keyword = words.firstIndex(of: "import"), keyword + 1 < words.count
            else { return nil }

            // `import Foundation.NSURL` imports the Foundation module.
            return words[keyword + 1].split(separator: ".").first.map(String.init)
        }
    }

    @Test("Imports are recognized, mentions in comments are not")
    func importsAreRecognisedButCommentsAreNot() {
        let source = """
            // import SwiftUI in a comment does not count
            import Foundation
            @preconcurrency import HealthKit
            public import SwiftData
            """

        let modules = Self.importedModules(in: source)

        #expect(modules == ["Foundation", "HealthKit", "SwiftData"])
    }
}
