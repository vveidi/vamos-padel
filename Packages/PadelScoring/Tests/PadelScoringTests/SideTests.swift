import Testing

@testable import PadelScoring

@Suite("Сторона")
struct SideTests {
    @Test("У каждой стороны есть противоположная")
    func everySideHasAnOpposite() {
        #expect(Side.us.opposite == .them)
        #expect(Side.them.opposite == .us)
    }

    @Test("Противоположная к противоположной — исходная сторона")
    func oppositeOfOppositeIsTheOriginalSide() {
        for side in Side.allCases {
            #expect(side.opposite.opposite == side)
        }
    }
}
