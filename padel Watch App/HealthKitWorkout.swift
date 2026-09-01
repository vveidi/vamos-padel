import HealthKit
import os

/// Тренировка на HealthKit: `HKWorkoutSession` плюс `HKLiveWorkoutBuilder`.
///
/// Тонкая обёртка над системным API, и тестами она не покрыта — так решено в
/// спеке, потому что проверять здесь нечего, кроме самого HealthKit. Всё, что
/// обёртка добавляет от себя, — два обещания. Первое: неудача не долетает до
/// матча. Здоровье может быть недоступно, разрешение — не выдано, сессия —
/// упасть посреди игры; счёт от этого не должен ни сбиться, ни исчезнуть.
/// Второе: тренировка либо идёт, либо нет, и переходы между этими состояниями
/// не наступают друг другу на пятки.
final class HealthKitWorkout: NSObject, Workout {
    private let healthStore = HKHealthStore()

    /// Что мы пишем: саму тренировку и потраченные калории. Пульс в списке
    /// отсутствует намеренно — его пишет система, мы только читаем.
    private static let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// Что мы читаем: то, что сборщик тренировки складывает в неё сам.
    private static let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// Непустые ровно тогда, когда тренировка идёт.
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// Очередь длиной в одно звено.
    ///
    /// Старт и завершение — асинхронные операции в несколько шагов, а зовёт их
    /// экран, который ждать не умеет. Без очереди отмена последнего розыгрыша
    /// на экране итога успевала бы начать новую тренировку раньше, чем
    /// закончилась предыдущая, и обе писали бы в один и тот же `session`.
    private var pending: Task<Void, Never>?

    func start() {
        enqueue { await self.begin() }
    }

    func end() {
        enqueue { await self.finish() }
    }

    private func enqueue(_ operation: @escaping () async -> Void) {
        let previous = pending

        pending = Task {
            await previous?.value
            await operation()
        }
    }

    private func begin() async {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }

        // Разрешение спрашивается перед каждым матчем, а показывается один
        // раз: HealthKit сам молчит, если про все типы уже решено. Отказ сюда
        // не долетает — про чтение HealthKit его принципиально не сообщает,
        // чтобы приложение не могло по отказу что-то заключить о здоровье, —
        // поэтому ответ на любой исход один: пробовать дальше и не мешать
        // матчу. Объяснение, зачем счётчику матча доступ к здоровью, живёт в
        // NSHealth*UsageDescription; система показывает его в этом же окне.
        do {
            try await healthStore.requestAuthorization(
                toShare: Self.typesToShare, read: Self.typesToRead)
        } catch {
            logger.error("Разрешение на здоровье не получено: \(error.localizedDescription)")
        }

        let configuration = HKWorkoutConfiguration()

        // Падела среди видов тренировок нет, и теннис — ближайшее, что есть:
        // тот же ракеточный парный корт, та же оценка затрат. Из-за него матч
        // и появится в Health под словом «Теннис».
        configuration.activityType = .tennis

        // Дистанцию мы не считаем, а закрытый корт для часов означает лишь
        // одно: не будить GPS. Полтора часа GPS ради ничего — это батарея,
        // которой не хватит на второй матч.
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(
                healthStore: healthStore, configuration: configuration)
            session.delegate = self

            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore, workoutConfiguration: configuration)

            let startedAt = Date()
            session.startActivity(with: startedAt)

            do {
                try await builder.beginCollection(at: startedAt)
            } catch {
                // Сессия уже идёт, а складывать в неё нечего. Оставить её
                // открытой значит жечь батарею до конца дня.
                session.end()
                throw error
            }

            self.session = session
            self.builder = builder
        } catch {
            logger.error("Тренировка не началась: \(error.localizedDescription)")
        }
    }

    private func finish() async {
        guard let session, let builder else { return }

        // Ссылки снимаются до первого await: пока тренировка закрывается,
        // матч уже считается без неё, и второй `end` не должен закрыть её
        // вторично, а `start` — увидеть занятое место.
        self.session = nil
        self.builder = nil

        let endedAt = Date()
        session.end()

        do {
            try await builder.endCollection(at: endedAt)

            // Именно этот вызов кладёт тренировку в Health. Без него матч
            // остаётся сессией, которая была и прошла.
            try await builder.finishWorkout()
        } catch {
            logger.error("Тренировка не записалась: \(error.localizedDescription)")
        }
    }
}

extension HealthKitWorkout: HKWorkoutSessionDelegate {
    /// Смена состояния сессии нас не занимает: тренировкой распоряжается матч,
    /// а не наоборот. Метод обязателен по протоколу.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    /// Единственный канал, по которому слышно, что тренировка умерла посреди
    /// матча. Ответить на это нечем — счёт продолжает считаться, — но молчать
    /// нельзя: иначе «матча нет в Health» останется без объяснения.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didFailWithError error: Error
    ) {
        let description = error.localizedDescription

        Task { @MainActor in
            logger.error("Тренировка прервалась: \(description)")
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "workout")
