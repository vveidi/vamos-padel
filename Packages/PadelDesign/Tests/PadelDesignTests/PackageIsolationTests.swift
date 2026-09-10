import Foundation
import Testing

/// The design knows the domain; the domain never hears about the design
/// (ADR-0006). Half of that runs one way and is worth checking: `PadelDesign`
/// depends on `PadelScoring` and on nothing else.
///
/// The other half needs no test. `PadelStorage` and `PadelDelivery` cannot
/// import this package without declaring it in their manifests, and
/// `PadelScoring`'s own `PackageIsolationTests` allows no import at all.
///
/// Built as an allowlist for the reason spelled out in that suite: a denylist
/// is incomplete by its nature, and what is allowed is known exactly.
@Suite("Package isolation")
struct PackageIsolationTests {
    /// SwiftUI because this package draws; `PadelScoring` for `Side` and, from
    /// ticket 03, `MatchOutcome`; `CoreGraphics` for `CGFloat`, which the
    /// radii are.
    ///
    /// A line appearing here should be a deliberate decision, not a side
    /// effect of somebody else's edit.
    static let allowedModules: Set<String> = ["SwiftUI", "PadelScoring", "CoreGraphics"]

    static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()  // PadelDesignTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // the package root

    @Test("The package sources import nothing beyond what is allowed")
    func sourcesImportOnlyAllowedModules() throws {
        let sourcesRoot = Self.packageRoot.appending(path: "Sources/PadelDesign")

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
    /// regardless.
    @Test("The manifest declares one dependency, and it is the engine")
    func packageDependsOnScoringAlone() throws {
        let manifest = try String(
            contentsOf: Self.packageRoot.appending(path: "Package.swift"), encoding: .utf8)

        let declarations = manifest.components(separatedBy: ".package(").dropFirst()

        #expect(declarations.count == 1, "the design package grew a second dependency")
        #expect(manifest.contains(#".package(path: "../PadelScoring")"#))
    }

    /// The guard above is only as good as the parser under it, and this file's
    /// doc comments mention `PadelStorage`, `PadelDelivery` and `SwiftUI` in
    /// prose. A parser that counted those would fail the suite for no reason;
    /// one that missed a real `import` would pass it for no reason.
    @Test("Imports are recognized, mentions in comments are not")
    func importsAreRecognizedButCommentsAreNot() {
        let source = """
            // import SwiftUI in a comment does not count
            import Foundation
            @preconcurrency import HealthKit
            public import SwiftData
            """

        let modules = Self.importedModules(in: source)

        #expect(modules == ["Foundation", "HealthKit", "SwiftData"])
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
}
