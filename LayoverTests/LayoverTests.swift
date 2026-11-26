import Testing
@testable import Layover

// Swift Testing: each `@Test` function is one test, and `#expect`
// checks a condition. This one only proves the test setup works —
// real tests for the game rules arrive in milestones 2 and 4.
struct LayoverTests {
    @Test func testSetupWorks() {
        #expect(1 + 1 == 2)
    }
}
