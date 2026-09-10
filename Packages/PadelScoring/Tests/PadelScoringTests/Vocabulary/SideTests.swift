import Testing

@testable import PadelScoring

@Suite("Side")
struct SideTests {
    @Test("Every side has an opposite")
    func everySideHasAnOpposite() {
        #expect(Side.us.opposite == .them)
        #expect(Side.them.opposite == .us)
    }

    @Test("The opposite of the opposite is the original side")
    func oppositeOfOppositeIsTheOriginalSide() {
        for side in Side.allCases {
            #expect(side.opposite.opposite == side)
        }
    }
}
