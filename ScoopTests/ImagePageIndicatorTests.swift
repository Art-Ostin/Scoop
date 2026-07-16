import Testing
@testable import Scoop

struct ImagePageIndicatorTests {
    @Test
    func sixImagePageIndicatorMovesForwardOnlyWhenSelectingSmallerDots() {
        var state = ImagePageIndicatorSizeState()

        #expect(reductions(in: state, count: 6) == [0, 0, 0, 1, 2, nil])

        state.select(1, count: 6)
        state.select(2, count: 6)
        #expect(reductions(in: state, count: 6) == [0, 0, 0, 1, 2, nil])

        state.select(3, count: 6)
        #expect(reductions(in: state, count: 6) == [1, 0, 0, 0, 1, 2])

        state.select(4, count: 6)
        #expect(reductions(in: state, count: 6) == [2, 1, 0, 0, 0, 1])

        state.select(5, count: 6)
        #expect(reductions(in: state, count: 6) == [nil, 2, 1, 0, 0, 0])
    }

    @Test
    func sixImagePageIndicatorRetainsSizingUntilSelectingSmallerDotsBehind() {
        var state = ImagePageIndicatorSizeState()
        state.select(5, count: 6)

        state.select(4, count: 6)
        state.select(3, count: 6)
        #expect(reductions(in: state, count: 6) == [nil, 2, 1, 0, 0, 0])

        state.select(2, count: 6)
        #expect(reductions(in: state, count: 6) == [2, 1, 0, 0, 0, 1])

        state.select(1, count: 6)
        #expect(reductions(in: state, count: 6) == [1, 0, 0, 0, 1, 2])

        state.select(0, count: 6)
        #expect(reductions(in: state, count: 6) == [0, 0, 0, 1, 2, nil])
    }

    @Test
    func indicatorHandlesShortAndChangingPageCounts() {
        var state = ImagePageIndicatorSizeState()

        for count in 1...3 {
            state.select(count - 1, count: count)
            #expect(reductions(in: state, count: count) == Array(repeating: 0, count: count))
        }

        state.select(9, count: 10)
        #expect(state.fullSizeStart == 7)

        state.select(3, count: 4)
        #expect(state.fullSizeStart == 1)
        #expect(reductions(in: state, count: 4) == [1, 0, 0, 0])

        state.select(0, count: 0)
        #expect(state.fullSizeStart == 0)
    }

    private func reductions(in state: ImagePageIndicatorSizeState, count: Int) -> [Int?] {
        (0..<count).map { state.reduction(for: $0, count: count) }
    }
}
