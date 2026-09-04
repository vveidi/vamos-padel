import Foundation
import Testing

/// Пакет — чистая доменная логика: он не знает ни про UI, ни про хранилище,
/// ни про системные фреймворки часов (тикет 01, ADR-0003).
///
/// Проверка устроена белым списком, а не чёрным. Чёрный список неполон по
/// своей природе: сегодня в нём девять модулей, завтра появляется десятый, и
/// предохранитель молча пропускает нарушение. Разрешённое же известно точно.
///
/// Компилятор закрывает лишь часть запрета сам: UIKit, WatchKit, HealthKit и
/// WatchConnectivity недоступны на macOS, где идут тесты. SwiftUI и SwiftData
/// доступны всем таргетам на всех платформах Apple — на них компилятор не
/// пожалуется никогда, и ровно эту разницу закрывают тесты ниже.
@Suite("Изоляция пакета")
struct PackageIsolationTests {
    /// Движку сейчас не нужен ни один модуль, включая Foundation.
    ///
    /// Появление строки здесь должно быть осознанным решением, а не побочным
    /// эффектом чужой правки — в этом весь смысл белого списка.
    static let allowedModules: Set<String> = []

    static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()  // PadelScoringTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // корень пакета

    @Test("Исходники пакета не импортируют ничего сверх разрешённого")
    func sourcesImportOnlyAllowedModules() throws {
        let sourcesRoot = Self.packageRoot.appending(path: "Sources/PadelScoring")

        let swiftFiles = try FileManager.default
            .subpathsOfDirectory(atPath: sourcesRoot.path(percentEncoded: false))
            .filter { $0.hasSuffix(".swift") }

        // Иначе на пустом списке файлов предохранитель молча проходит.
        #expect(!swiftFiles.isEmpty, "не найдено исходников — предохранитель бесполезен")

        for file in swiftFiles {
            let source = try String(
                contentsOf: sourcesRoot.appending(path: file), encoding: .utf8)

            for importedModule in Self.importedModules(in: source) {
                #expect(
                    Self.allowedModules.contains(importedModule),
                    "\(file) импортирует \(importedModule), которого нет в белом списке")
            }
        }
    }

    /// Проверки импортов недостаточно: зависимость можно объявить в манифесте
    /// и не импортировать ни в одном файле — линковка при этом уже состоялась.
    /// Запрет из ADR-0003 структурный, поэтому и проверять его надо структурно.
    @Test("Пакет не объявляет внешних зависимостей")
    func packageDeclaresNoExternalDependencies() throws {
        let manifest = try String(
            contentsOf: Self.packageRoot.appending(path: "Package.swift"), encoding: .utf8)

        #expect(
            !manifest.contains(".package("),
            "в Package.swift появилась внешняя зависимость — движок должен оставаться чистым")
    }

    /// Имена модулей, импортированных в исходнике. Строки комментариев
    /// пропускаются, чтобы упоминание модуля в документации не роняло тест.
    static func importedModules(in source: String) -> [String] {
        source.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("//") else { return nil }

            let words = trimmed.split(separator: " ").map(String.init)
            guard let keyword = words.firstIndex(of: "import"), keyword + 1 < words.count
            else { return nil }

            // `import Foundation.NSURL` импортирует модуль Foundation.
            return words[keyword + 1].split(separator: ".").first.map(String.init)
        }
    }

    @Test("Импорты распознаются, а упоминания в комментариях — нет")
    func importsAreRecognisedButCommentsAreNot() {
        let source = """
            // import SwiftUI в комментарии не считается
            import Foundation
            @preconcurrency import HealthKit
            public import SwiftData
            """

        let modules = Self.importedModules(in: source)

        #expect(modules == ["Foundation", "HealthKit", "SwiftData"])
    }
}
