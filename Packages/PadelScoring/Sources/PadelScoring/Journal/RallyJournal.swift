public struct RallyJournal: Equatable, Sendable {
    public private(set) var rallies: [Rally]

    public init(_ rallies: [Rally] = []) {
        self.rallies = rallies
    }

    public var count: Int { rallies.count }

    public var isEmpty: Bool { rallies.isEmpty }

    public var last: Rally? { rallies.last }

    public mutating func append(wonBy side: Side) {
        rallies.append(Rally(wonBy: side))
    }

    @discardableResult
    public mutating func removeLast() -> Rally? {
        rallies.popLast()
    }
}
