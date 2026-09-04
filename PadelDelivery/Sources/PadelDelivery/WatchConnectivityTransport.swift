#if canImport(WatchConnectivity)

    import Foundation
    import PadelStorage
    import WatchConnectivity

    /// Транспорт на WatchConnectivity: единственная реализация шва из
    /// ADR-0002, и единственное место во всём коде, которое о нём знает.
    ///
    /// Матч ставится в очередь через `transferUserInfo`, а не отправляется
    /// сообщением: сообщение требует, чтобы телефон был доступен прямо сейчас,
    /// а он лежит в сумке за сеткой. Очередь ведёт система — она переживает и
    /// выгрузку приложения, и перезагрузку часов, доставляет в порядке
    /// постановки и будит приложение на телефоне ради каждой посылки. Тем же
    /// способом возвращается расписка: телефон ровно так же может оказаться
    /// первым, кто проснулся.
    ///
    /// Один и тот же объект стоит на обоих концах: сессия у устройства одна, и
    /// делить её между отправкой и приёмом нечем. Приложения при этом
    /// пользуются разными половинами — часы отправляют, телефон принимает.
    public final class WatchConnectivityTransport: NSObject, MatchSender, MatchReceiver {
        /// Обработчики ставятся при сборке приложения, а зовутся с очереди
        /// сессии. Замок здесь не от гонки за них, а ради того, чтобы это
        /// утверждение было проверяемым компилятором.
        private let handlers = Handlers()

        /// Сессия, если устройство её поддерживает.
        ///
        /// `nil` на iPad и прочих устройствах без пары: матч на них не
        /// приезжает и не уезжает, всё остальное работает.
        private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

        public override init() {
            super.init()
        }

        /// Включает сессию.
        ///
        /// Зовётся после того, как обработчики поставлены: посылка, приехавшая
        /// в приложение без обработчика, не приедет второй раз.
        ///
        /// Готовность приходит не отсюда, а позже, из `activationDidComplete`:
        /// активация асинхронная, и до её конца сессия ничего не повезёт.
        public func activate() {
            guard let session else {
                logger.notice("WatchConnectivity недоступен, доставки не будет")
                return
            }

            session.delegate = self
            session.activate()
        }

        public func send(_ match: SavedMatch) {
            transfer(.match(match))
        }

        public func confirmArrival(of match: SavedMatch) {
            transfer(.receipt(match))
        }

        public func onReady(_ ready: @escaping @Sendable () -> Void) {
            handlers.setReady(ready)
        }

        public func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
            handlers.setConfirm(confirm)
        }

        public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
            handlers.setReceive(receive)
        }

        /// Ставит посылку в системную очередь.
        ///
        /// Неактивированная сессия не берётся везти ничего, поэтому отданное
        /// ей до готовности пропало бы молча. Матч в этом случае просто
        /// остаётся в очереди хранилища и уедет по готовности.
        private func transfer(_ arrival: Arrival) {
            guard let session, session.activationState == .activated else {
                logger.notice("Сессия не активирована, посылка осталась в очереди")
                return
            }

            session.transferUserInfo(MatchPayload.encode(arrival))
        }
    }

    extension WatchConnectivityTransport: WCSessionDelegate {
        /// Сессия поднялась — и только теперь ей можно что-то отдавать.
        public func session(
            _ session: WCSession,
            activationDidCompleteWith state: WCSessionActivationState,
            error: (any Error)?
        ) {
            if let error {
                logger.error("Сессия не активирована: \(error.localizedDescription)")
            }

            guard state == .activated else { return }

            handlers.ready()
        }

        /// Посылка ушла — или не ушла.
        ///
        /// Доставку это не подтверждает: система знает лишь, что довезла
        /// словарь до приложения на той стороне, а часам нужно знать, что матч
        /// попал в историю. Расписывается в этом телефон, отдельной посылкой.
        public func session(
            _ session: WCSession,
            didFinish userInfoTransfer: WCSessionUserInfoTransfer,
            error: (any Error)?
        ) {
            if let error {
                logger.error("Посылка не доставлена: \(error.localizedDescription)")
            }
        }

        public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
            do {
                switch try MatchPayload.decode(userInfo) {
                case .match(let match): handlers.receive(match)
                case .receipt(let match): handlers.confirm(match)
                }
            } catch {
                logger.error("Приехавшая посылка не разобрана: \(error.localizedDescription)")
            }
        }

        #if os(iOS)
            // Требуются протоколом на телефоне: сессия рвётся при смене
            // сопряжённых часов. Нам от этого ничего не нужно, кроме как
            // подняться заново, — история уже записана в свою базу.
            public func sessionDidBecomeInactive(_ session: WCSession) {}

            public func sessionDidDeactivate(_ session: WCSession) {
                WCSession.default.activate()
            }
        #endif
    }

    /// Три замыкания под замком — ровно столько состояния, сколько у
    /// транспорта есть.
    private final class Handlers: @unchecked Sendable {
        private let lock = NSLock()
        private var transportReady: (@Sendable () -> Void)?
        private var confirmDelivery: (@Sendable (SavedMatch) -> Void)?
        private var receiveMatch: (@Sendable (SavedMatch) -> Void)?

        func setReady(_ handle: @escaping @Sendable () -> Void) {
            lock.withLock { transportReady = handle }
        }

        func setConfirm(_ handle: @escaping @Sendable (SavedMatch) -> Void) {
            lock.withLock { confirmDelivery = handle }
        }

        func setReceive(_ handle: @escaping @Sendable (SavedMatch) -> Void) {
            lock.withLock { receiveMatch = handle }
        }

        func ready() {
            lock.withLock { transportReady }?()
        }

        func confirm(_ match: SavedMatch) {
            lock.withLock { confirmDelivery }?(match)
        }

        func receive(_ match: SavedMatch) {
            lock.withLock { receiveMatch }?(match)
        }
    }

#endif
