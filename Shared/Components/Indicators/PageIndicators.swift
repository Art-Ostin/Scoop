//
//  PageIndicators.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2026.
//
import SwiftUI

struct ImagePageIndicator: View {
    let count: Int
    let progress: Double

    var dotSize: CGFloat = 7
    var activeWidth: CGFloat = 12
    var spacing: CGFloat = 8
    var activeColor: Color = .black

    @State private var sizeState = ImagePageIndicatorSizeState()

    private var selectedIndex: Int {
        guard count > 0 else { return 0 }
        return min(max(Int(progress.rounded()), 0), count - 1)
    }

    var body: some View {
        let row = layout(at: progress, sizeState: sizeState)
        //Centre the packed cluster in a fixed frame so the overlay never shifts.
        let inset = max(0, (steadyWidth - row.width) / 2)
        ZStack(alignment: .leading) {
            ForEach(0..<count, id: \.self) { i in
                let dot = row.dots[i]
                capsule(closeness: dot.closeness)
                    .frame(width: dot.width, height: dot.height)
                    .offset(x: inset + dot.x - dot.width / 2)
            }
        }
        .frame(width: steadyWidth, height: dotSize, alignment: .leading)
        .onAppear { updateSizeState(animated: false) }
        .onChange(of: selectedIndex) { _, _ in updateSizeState(animated: true) }
        .onChange(of: count) { _, _ in updateSizeState(animated: true) }
    }

    private func capsule(closeness: Double) -> some View {
        Capsule()
            .fill(activeColor)
            .opacity(0.55 + 0.45 * closeness)
    }

    private struct Dot {
        let width: CGFloat
        let height: CGFloat
        let x: CGFloat //Centre, in cluster coordinates
        let closeness: Double
    }

    //Dots pack cumulatively: smaller dots sit proportionally closer together,
    //and hidden dots collapse without leaving an empty gap.
    private func layout(
        at progress: Double,
        sizeState: ImagePageIndicatorSizeState
    ) -> (dots: [Dot], width: CGFloat) {
        let clampedProgress = count > 0
            ? min(max(progress, 0), Double(count - 1))
            : 0
        var dots: [Dot] = []
        var cursor: CGFloat = 0
        var previousVisibleScale: CGFloat?

        for index in 0..<count {
            let distance = abs(clampedProgress - Double(index))
            let closeness = max(0, 1 - distance)
            guard let reduction = sizeState.reduction(for: index, count: count) else {
                dots.append(Dot(width: 0, height: 0, x: cursor, closeness: closeness))
                continue
            }

            let scale = 1 - CGFloat(reduction) * 0.25
            let height = max(0, dotSize * scale)
            let width = max(0, height + (activeWidth - dotSize) * CGFloat(closeness))
            if let previousVisibleScale {
                cursor += spacing / 2 * (previousVisibleScale + scale)
            }
            dots.append(
                Dot(
                    width: width,
                    height: height,
                    x: cursor + width / 2,
                    closeness: closeness
                )
            )
            cursor += width
            previousVisibleScale = scale
        }
        return (dots, cursor)
    }

    //Use the widest legal sizing state as a fixed frame so the overlay never
    //moves as edge dots appear and disappear.
    private var steadyWidth: CGFloat {
        guard count > 0 else { return 0 }
        let fullSizeCount = min(ImagePageIndicatorSizeState.fullSizeCount, count)
        let maximumStart = max(0, count - fullSizeCount)

        return (0...maximumStart).reduce(CGFloat.zero) { widest, start in
            let state = ImagePageIndicatorSizeState(fullSizeStart: start)
            let width = layout(at: Double(start), sizeState: state).width
            return max(widest, width)
        }
    }

    private func updateSizeState(animated: Bool) {
        var nextState = sizeState
        nextState.select(selectedIndex, count: count)
        guard nextState != sizeState else { return }

        if animated {
            withAnimation(.move) { sizeState = nextState }
        } else {
            sizeState = nextState
        }
    }
}

struct ImagePageIndicatorSizeState: Equatable {
    static let fullSizeCount = 3
    static let taperCount = 2

    private(set) var fullSizeStart: Int

    init(fullSizeStart: Int = 0) {
        self.fullSizeStart = max(0, fullSizeStart)
    }

    mutating func select(_ rawIndex: Int, count: Int) {
        guard count > 0 else {
            fullSizeStart = 0
            return
        }

        let fullCount = min(Self.fullSizeCount, count)
        let maximumStart = max(0, count - fullCount)
        let selectedIndex = min(max(rawIndex, 0), count - 1)
        var nextStart = min(fullSizeStart, maximumStart)
        let fullSizeEnd = nextStart + fullCount - 1

        if selectedIndex < nextStart {
            nextStart = selectedIndex
        } else if selectedIndex > fullSizeEnd {
            nextStart = selectedIndex - fullCount + 1
        }

        fullSizeStart = min(max(nextStart, 0), maximumStart)
    }

    func reduction(for index: Int, count: Int) -> Int? {
        guard count > 0, (0..<count).contains(index) else { return nil }

        let fullCount = min(Self.fullSizeCount, count)
        let maximumStart = max(0, count - fullCount)
        let start = min(fullSizeStart, maximumStart)
        let end = start + fullCount - 1
        let distance: Int

        if index < start {
            distance = start - index
        } else if index > end {
            distance = index - end
        } else {
            distance = 0
        }

        return distance <= Self.taperCount ? distance : nil
    }
}

struct PageIndicator: View {
    let count: Int
    let progress: Double

    let dotSize: CGFloat = 6
    let activeWidth: CGFloat = 12
    let spacing: CGFloat = 8
    let activeColor: Color = .textPrimary

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                let closeness = max(0, 1 - abs(progress - Double(index)))

                Capsule()
                    .fill(Color.border.mix(with: activeColor, by: closeness))
                    .frame(
                        width: dotSize
                            + (activeWidth - dotSize) * CGFloat(closeness),
                        height: dotSize
                    )
            }
        }
        .frame(
            width: count > 0
                ? activeWidth + CGFloat(count - 1) * (dotSize + spacing)
                : 0,
            height: dotSize
        )
    }
}
