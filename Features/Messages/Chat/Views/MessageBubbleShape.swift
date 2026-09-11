//
//  MessageBubbleShape.swift
//  Scoop
//
//  Created by Art Ostin on 05/03/2026.
//

import SwiftUI

enum MessageBubbleTail {
    case none
    case leading
    case trailing
}

///The Messages balloon, drawn the way Apple's BubbleKit draws it on iOS 26: each corner is Apple's
///continuous corner (three cubics) that blends towards a true circle as the bubble nears a pill, and
///the tail is the droplet hanging under the outer bottom corner. Everything is a multiple of the
///corner radius, so the tail keeps its proportions at any bubble size. `rect` is the body; the tail
///extends below `rect.maxY` by `tailDrop(for:)`.
struct MessageBubbleShape: Shape {
    var messageCornerRadius: CGFloat = 18
    var tail: MessageBubbleTail = .none

    ///How far the tail hangs below the body, so callers can reserve room for it
    static func tailDrop(for cornerRadius: CGFloat) -> CGFloat { cornerRadius * 0.33925 }

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path(rect) }
        let radius = min(messageCornerRadius, rect.width / 2, rect.height / 2)
        //Offsets measured along the top and bottom edges blend by the width, those along the sides by the height
        let h = CornerCurve.blended(spanning: rect.width, radius: radius)
        let v = CornerCurve.blended(spanning: rect.height, radius: radius)
        let minX = rect.minX, minY = rect.minY, maxX = rect.maxX, maxY = rect.maxY

        var path = Path()
        path.move(to: CGPoint(x: minX, y: minY + v.start))

        //Top-leading corner: out of the leading edge, over the top
        path.addCurve(to: CGPoint(x: minX + v.thirdLift, y: minY + v.thirdAnchor),
                      control1: CGPoint(x: minX, y: minY + v.handleFar),
                      control2: CGPoint(x: minX + v.handleLift, y: minY + v.handleNear))
        path.addCurve(to: CGPoint(x: minX + h.thirdAnchor, y: minY + h.thirdLift),
                      control1: CGPoint(x: minX + v.midHandleNear, y: minY + v.midHandleFar),
                      control2: CGPoint(x: minX + h.midHandleFar, y: minY + v.midHandleNear))
        path.addCurve(to: CGPoint(x: minX + h.start, y: minY),
                      control1: CGPoint(x: minX + h.handleNear, y: minY + h.handleLift),
                      control2: CGPoint(x: minX + h.handleFar, y: minY))

        path.addLine(to: CGPoint(x: maxX - h.start, y: minY))

        //Top-trailing corner
        path.addCurve(to: CGPoint(x: maxX - h.thirdAnchor, y: minY + h.thirdLift),
                      control1: CGPoint(x: maxX - h.handleFar, y: minY),
                      control2: CGPoint(x: maxX - h.handleNear, y: minY + h.handleLift))
        path.addCurve(to: CGPoint(x: maxX - v.thirdLift, y: minY + v.thirdAnchor),
                      control1: CGPoint(x: maxX - h.midHandleFar, y: minY + h.midHandleNear),
                      control2: CGPoint(x: maxX - h.midHandleNear, y: minY + v.midHandleFar))
        path.addCurve(to: CGPoint(x: maxX, y: minY + v.start),
                      control1: CGPoint(x: maxX - v.handleLift, y: minY + v.handleNear),
                      control2: CGPoint(x: maxX, y: minY + v.handleFar))

        path.addLine(to: CGPoint(x: maxX, y: maxY - v.start))

        //Bottom-trailing corner: the tail replaces it, hanging from the corner point
        if tail == .none {
            path.addCurve(to: CGPoint(x: maxX - v.thirdLift, y: maxY - v.thirdAnchor),
                          control1: CGPoint(x: maxX, y: maxY - v.handleFar),
                          control2: CGPoint(x: maxX - v.handleLift, y: maxY - v.handleNear))
            path.addCurve(to: CGPoint(x: maxX - h.thirdAnchor, y: maxY - h.thirdLift),
                          control1: CGPoint(x: maxX - h.midHandleNear, y: maxY - v.midHandleFar),
                          control2: CGPoint(x: maxX - h.midHandleFar, y: maxY - v.midHandleNear))
            path.addCurve(to: CGPoint(x: maxX - h.start, y: maxY),
                          control1: CGPoint(x: maxX - h.handleNear, y: maxY - h.handleLift),
                          control2: CGPoint(x: maxX - h.handleFar, y: maxY))
        } else {
            let corner = CGPoint(x: maxX, y: maxY)
            for curve in Self.tailCurves {
                path.addCurve(to: corner + curve.end * radius,
                              control1: corner + curve.control1 * radius,
                              control2: corner + curve.control2 * radius)
            }
        }

        path.addLine(to: CGPoint(x: minX + h.start, y: maxY))

        //Bottom-leading corner
        path.addCurve(to: CGPoint(x: minX + h.thirdAnchor, y: maxY - h.thirdLift),
                      control1: CGPoint(x: minX + h.handleFar, y: maxY),
                      control2: CGPoint(x: minX + h.handleNear, y: maxY - h.handleLift))
        path.addCurve(to: CGPoint(x: minX + v.thirdLift, y: maxY - v.thirdAnchor),
                      control1: CGPoint(x: minX + h.midHandleFar, y: maxY - h.midHandleNear),
                      control2: CGPoint(x: minX + h.midHandleNear, y: maxY - v.midHandleFar))
        path.addCurve(to: CGPoint(x: minX, y: maxY - v.start),
                      control1: CGPoint(x: minX + v.handleLift, y: maxY - v.handleNear),
                      control2: CGPoint(x: minX, y: maxY - v.handleFar))
        path.closeSubpath()

        //The tail is drawn on the trailing side; a leading tail is its mirror image
        guard tail == .leading else { return path }
        return path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: minX + maxX, ty: 0))
    }
}

private extension MessageBubbleShape {
    ///One corner as Apple draws it: three cubics whose anchors and handles sit at these multiples of
    ///the radius, measured from the corner point. `start` is where the curve leaves the straight edge;
    ///the "lift" values are how far a handle or anchor sits off that edge.
    struct CornerCurve {
        var start: CGFloat
        var handleFar: CGFloat
        var handleNear: CGFloat
        var handleLift: CGFloat
        var thirdAnchor: CGFloat
        var thirdLift: CGFloat
        var midHandleFar: CGFloat
        var midHandleNear: CGFloat

        ///Apple's continuous corner, which needs 1.528665 radii of straight edge on each side
        static let continuous = CornerCurve(start: 1.528665, handleFar: 1.08849, handleNear: 0.868407, handleLift: 0,
                                            thirdAnchor: 0.631494, thirdLift: 0.0749114,
                                            midHandleFar: 0.372824, midHandleNear: 0.16906)
        ///A quarter circle in the same three cubics
        static let circular = CornerCurve(start: 1, handleFar: 0.8732602355268562, handleNear: 0.7476756885741366,
                                          handleLift: 0.024092519875899457,
                                          thirdAnchor: 0.6299337664259247, thirdLift: 0.07099462715854132,
                                          midHandleFar: 0.37476586421208946, midHandleNear: 0.1726399214289621)

        ///Continuous when the edge has room for it, circular once the corners meet (a pill), blended between
        static func blended(spanning span: CGFloat, radius: CGFloat) -> CornerCurve {
            guard radius > 0 else { return CornerCurve.continuous.scaled(by: 0) }
            let circular = min(max((span / 2 / radius - continuous.start) / (1 - continuous.start), 0), 1)
            func mix(_ keyPath: KeyPath<CornerCurve, CGFloat>) -> CGFloat {
                (CornerCurve.circular[keyPath: keyPath] * circular + CornerCurve.continuous[keyPath: keyPath] * (1 - circular)) * radius
            }
            return CornerCurve(start: mix(\.start), handleFar: mix(\.handleFar), handleNear: mix(\.handleNear),
                               handleLift: mix(\.handleLift), thirdAnchor: mix(\.thirdAnchor), thirdLift: mix(\.thirdLift),
                               midHandleFar: mix(\.midHandleFar), midHandleNear: mix(\.midHandleNear))
        }

        func scaled(by radius: CGFloat) -> CornerCurve {
            CornerCurve(start: start * radius, handleFar: handleFar * radius, handleNear: handleNear * radius,
                        handleLift: handleLift * radius, thirdAnchor: thirdAnchor * radius, thirdLift: thirdLift * radius,
                        midHandleFar: midHandleFar * radius, midHandleNear: midHandleNear * radius)
        }
    }

    ///The droplet, in radii from the body's outer bottom corner (x inward is negative, y down is
    ///positive), picking up from the trailing edge `start` radii above the corner. It bulges out
    ///beside the edge, hangs to its lowest point 0.49 radii in and 0.33 radii below the body, and
    ///scoops back up to rejoin the bottom edge 1.10 radii in.
    static let tailCurves: [(end: CGPoint, control1: CGPoint, control2: CGPoint)] = [
        (CGPoint(x: -0.201395, y: -0.40379087), CGPoint(x: 0, y: -0.78469087), CGPoint(x: -0.070745, y: -0.57509087)),
        (CGPoint(x: -0.383, y: -0.22117087), CGPoint(x: -0.254335, y: -0.33438785), CGPoint(x: -0.31546, y: -0.27321571)),
        (CGPoint(x: -0.5209, y: 0.02017913), CGPoint(x: -0.47925, y: -0.14612087), CGPoint(x: -0.5209, y: -0.06782087)),
        (CGPoint(x: -0.4255, y: 0.24937913), CGPoint(x: -0.5209, y: 0.07932913), CGPoint(x: -0.51045, y: 0.13777913)),
        (CGPoint(x: -0.48935, y: 0.33327913), CGPoint(x: -0.38475, y: 0.30287913), CGPoint(x: -0.42565, y: 0.35747913)),
        (CGPoint(x: -0.90025, y: 0.09632913), CGPoint(x: -0.62035, y: 0.28352913), CGPoint(x: -0.76955, y: 0.19297913)),
        (CGPoint(x: -1.1035, y: 0.00062913), CGPoint(x: -1.01735, y: 0.00972913), CGPoint(x: -1.04855, y: 0.00097913)),
    ]
}

private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
private func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint { CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
