public struct SideCounts: Equatable, Sendable {
    public let us: Int
    public let them: Int

    public init(us: Int = 0, them: Int = 0) {
        self.us = us
        self.them = them
    }

    public var total: Int { us + them }

    public subscript(side: Side) -> Int {
        switch side {
        case .us: us
        case .them: them
        }
    }

    func incrementing(_ side: Side) -> SideCounts {
        switch side {
        case .us: SideCounts(us: us + 1, them: them)
        case .them: SideCounts(us: us, them: them + 1)
        }
    }
}
