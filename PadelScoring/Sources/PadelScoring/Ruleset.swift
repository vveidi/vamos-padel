/// Данные, определяющие, как из журнала розыгрышей вычисляется счёт и когда
/// матч закончен.
///
/// Именно данные, а не ветвление в коде: «сегодня играем до 9 геймов» должно
/// становиться другим значением, а не другой веткой движка.
public enum Ruleset: Equatable, Sendable {
    /// Классический счёт падела: 15/30/40, геймы, сеты, тай-брейк при 6:6.
    ///
    /// При `goldenPoint` счёт «ровно» разыгрывается одним решающим очком
    /// вместо игры до разницы в два.
    case classic(sets: Int, goldenPoint: Bool)

    /// Матч до `target` очков; подача переходит к другой стороне каждые
    /// `serveChangesEvery` розыгрышей.
    case pointsTo(target: Int, serveChangesEvery: Int)

    /// Стартовые значения подобраны под любительскую игру на оплаченный
    /// час корта; дальше приложение помнит настройки прошлого матча.
    public static let defaultClassic = Ruleset.classic(sets: 1, goldenPoint: true)

    public static let defaultPointsTo = Ruleset.pointsTo(target: 16, serveChangesEvery: 4)
}
