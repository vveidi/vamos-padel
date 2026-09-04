import PadelScoring
import PadelStorage
import PadelDelivery
import SwiftUI
import os

/// Корень приложения: старт → счёт → итог и снова старт.
///
/// Здесь живёт единственный вопрос, на который приложение отвечает при запуске:
/// матч уже идёт или его ещё нет. Идёт — часы возвращаются прямо к счёту, минуя
/// старт: игрок, у которого приложение выгрузилось между геймами, стартовый
/// экран не заказывал.
struct RootView: View {
    /// Матч, который сейчас играют, — каким он начался. `nil` — матча нет, и
    /// на экране старт.
    ///
    /// Дальше матч живёт в экране матча и сюда не возвращается: корню довольно
    /// знать, что матч есть. Отдать экрану `Binding` на этот опционал было бы
    /// на вид честнее — одно значение вместо двух, — но SwiftUI разворачивает
    /// такую связку силой при каждом чтении. Кнопка «Новый матч» обнуляет матч,
    /// живой ещё экран матча читает свой `Binding`, и приложение падает на
    /// ровном месте — с этого началась правка после тикета.
    @State private var match: SavedMatch?

    /// Набор правил, с которым начнётся следующий матч. Первым делом сюда
    /// приезжают правила прошлого матча из хранилища, дальше их меняет экран
    /// правил.
    @State private var ruleset = Ruleset.defaultClassic

    /// Хранилище отвечает не мгновенно, а до его ответа неизвестно даже, какой
    /// из экранов показывать. Мигнуть стартовым экраном под рукой игрока,
    /// который вернулся к идущему матчу, — верный способ начать вместо него
    /// новый.
    @State private var isRestored = false

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    /// Хранилище, тренировка и доставка приходят снаружи, а не создаются
    /// здесь: превью не должно ни просить доступ к здоровью, ни заводить базу,
    /// ни поднимать сессию к телефону.
    init(store: any MatchStore, workout: any Workout, delivery: MatchDelivery) {
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
    }

    var body: some View {
        Group {
            if !isRestored {
                ProgressView()
            } else if let match {
                MatchView(
                    match: match,
                    store: store,
                    workout: workout,
                    delivery: delivery,
                    onFinish: startOver)
                    // Другой матч — другой экран, с чистого листа. Без этого
                    // матч, начатый сразу после предыдущего, достался бы экрану
                    // с состоянием прошлого.
                    .id(match.id)
            } else {
                StartView(ruleset: $ruleset, onStart: start(servedBy:))
            }
        }
        .task { restore() }
    }

    /// Матч начинается здесь и первым же розыгрышем попадёт в хранилище.
    /// Набор правил при этом уже неизменен: матч, у которого посреди игры
    /// поменялись правила, — это другой матч.
    private func start(servedBy firstServer: Side) {
        match = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: .now)
    }

    /// Возвращает на стартовый экран. Сыгранный матч уже записан, и терять
    /// здесь нечего; набор правил остаётся тот же — следующий матч почти
    /// наверняка играют по тем же правилам, что и предыдущий.
    private func startOver() {
        match = nil
    }

    /// Восстанавливает то, что приложение помнит: матч, начатый до выгрузки, и
    /// правила прошлого матча.
    ///
    /// Неудача чтения сюда не долетает — по той же причине, по которой до
    /// матча не долетают неудачи записи и тренировки: начать новый матч по
    /// умолчаниям хуже, чем продолжить старый, и всё же лучше, чем не начать
    /// ничего.
    private func restore() {
        do {
            match = try store.matchInProgress()
            ruleset = try store.lastRuleset() ?? .defaultClassic
        } catch {
            logger.error("Прошлый матч не восстановлен: \(error.localizedDescription)")
        }

        isRestored = true

        // Матч, не доехавший до телефона в прошлый раз, уезжает снова — в этом
        // и состоит «очередь переживает перезапуск». Спрашивается это при
        // каждом запуске, а не только после законченного матча: телефона могло
        // не быть рядом весь вечер.
        delivery.deliverPending()
    }
}

#Preview {
    RootView(
        store: NoMatchStore(),
        workout: NoWorkout(),
        delivery: MatchDelivery(store: NoMatchStore(), sender: NoMatchTransport()))
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
