#if canImport(WatchConnectivity)

    import Foundation
    import PadelStorage
    import WatchConnectivity
    import os

    /// Транспорт на WatchConnectivity: единственная реализация шва из
    /// ADR-0002, и единственное место во всём коде, которое о нём знает.
    ///
    /// Матч ставится в очередь через `transferUserInfo`, а не отправляется
    /// сообщением: сообщение требует, чтобы телефон был доступен прямо сейчас,
    /// а он лежит в сумке за сеткой. Очередь ведёт система — она переживает и
    /// выгрузку приложения, и перезагрузку часов, доставляет в порядке
    /// постановки и будит приложение на телефоне ради каждой посылки.
    ///
    /// Один и тот же объект стоит на обоих концах: сессия у устройства одна, и
    /// делить её между отправкой и приёмом нечем. Приложения при этом
    /// пользуются разными половинами — часы отправляют, телефон принимает.
    public final class WatchConnectivityTransport: NSObject, MatchSender, MatchReceiver {
        /// Обработчики ставятся при сборке приложения, а зовутся с очереди
        /// сессии. Замок здесь не от гонки за них, а ради того, чтобы это
        /// утверждение было проверяемым компилятором.
        private let handlers = Handlers()

        public override init() {
            super.init()
        }

        /// Включает сессию.
        ///
        /// Зовётся после того, как обработчики поставлены: посылка, приехавшая
        /// в приложение без обработчика, не приедет второй раз.
        public func activate() {
            guard WCSession.isSupported() else {
                // iPad и прочие устройства без пары. Матч на них не приезжает
                // и не уезжает, всё остальное работает.
                logger.notice("WatchConnectivity недоступен, доставки не будет")
                return
            }

            WCSession.default.delegate = self
            WCSession.default.activate()
        }

        public func send(_ match: SavedMatch) {
            guard WCSession.isSupported() else { return }

            WCSession.default.transferUserInfo(MatchPayload.encode(match))
        }

        public func onDelivery(_ confirm: @escaping @Sendable (UUID) -> Void) {
            handlers.setConfirm(confirm)
        }

        public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
            handlers.setReceive(receive)
        }
    }

    extension WatchConnectivityTransport: WCSessionDelegate {
        public func session(
            _ session: WCSession,
            activationDidCompleteWith state: WCSessionActivationState,
            error: (any Error)?
        ) {
            if let error {
                logger.error("Сессия не активирована: \(error.localizedDescription)")
            }
        }

        /// Доставка подтверждена — или не состоялась.
        ///
        /// Идентификатор берётся из самой посылки, а не из таблицы «что мы
        /// отправляли»: подтверждение приходит когда угодно, в том числе
        /// приложению, запущенному заново, — и никакой таблицы к тому моменту
        /// уже нет. При ошибке не делается ничего: матч остаётся в очереди
        /// хранилища и уедет со следующим запуском.
        public func session(
            _ session: WCSession,
            didFinish userInfoTransfer: WCSessionUserInfoTransfer,
            error: (any Error)?
        ) {
            if let error {
                logger.error("Матч не доставлен: \(error.localizedDescription)")
                return
            }

            guard let id = MatchPayload.matchId(in: userInfoTransfer.userInfo) else {
                logger.error("Доставлена посылка без идентификатора матча")
                return
            }

            handlers.confirm(id)
        }

        public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
            do {
                handlers.receive(try MatchPayload.decode(userInfo))
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

    /// Два замыкания под замком — ровно столько состояния, сколько у
    /// транспорта есть.
    private final class Handlers: @unchecked Sendable {
        private let lock = NSLock()
        private var confirmDelivery: (@Sendable (UUID) -> Void)?
        private var receiveMatch: (@Sendable (SavedMatch) -> Void)?

        func setConfirm(_ handle: @escaping @Sendable (UUID) -> Void) {
            lock.withLock { confirmDelivery = handle }
        }

        func setReceive(_ handle: @escaping @Sendable (SavedMatch) -> Void) {
            lock.withLock { receiveMatch = handle }
        }

        func confirm(_ id: UUID) {
            lock.withLock { confirmDelivery }?(id)
        }

        func receive(_ match: SavedMatch) {
            lock.withLock { receiveMatch }?(match)
        }
    }

    private let logger = Logger(subsystem: "com.vveidi.padel", category: "delivery")

#endif
