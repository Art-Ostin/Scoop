//
//  MessageTriangle.swift
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

struct MessageBubbleShape: Shape {
    var topLeadingRadius: CGFloat
    var bottomLeadingRadius: CGFloat
    var bottomTrailingRadius: CGFloat
    var topTrailingRadius: CGFloat
    var tail: MessageBubbleTail = .none
    var tailWidth: CGFloat = 10
    var tailHeight: CGFloat = 15
    var tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let width = max(rect.width, 0)
        let height = max(rect.height, 0)

        let topLeading = min(topLeadingRadius, width / 2, height / 2)
        let bottomLeading = min(bottomLeadingRadius, width / 2, height / 2)
        let bottomTrailing = min(bottomTrailingRadius, width / 2, height / 2)
        let topTrailing = min(topTrailingRadius, width / 2, height / 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topLeading, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.maxX - topTrailing, y: rect.minY))
        addCorner(
            to: &path,
            center: CGPoint(x: rect.maxX - topTrailing, y: rect.minY + topTrailing),
            radius: topTrailing,
            startAngle: .degrees(-90),
            endAngle: .degrees(0)
        )

        if tail == .trailing {
            let topAttachment = CGPoint(x: rect.maxX, y: rect.maxY - tailHeight)
            path.addLine(to: topAttachment)
            addTrailingTail(to: &path, topAttachment: topAttachment, bottomAttachment: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailing))
        }

        if tail == .trailing, bottomTrailing > 0 {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailing))
        }
        addCorner(
            to: &path,
            center: CGPoint(x: rect.maxX - bottomTrailing, y: rect.maxY - bottomTrailing),
            radius: bottomTrailing,
            startAngle: .degrees(0),
            endAngle: .degrees(90)
        )

        if tail == .leading {
            let bottomAttachment = CGPoint(x: rect.minX, y: rect.maxY)
            path.addLine(to: bottomAttachment)
            addLeadingTail(
                to: &path,
                bottomAttachment: bottomAttachment,
                topAttachment: CGPoint(x: rect.minX, y: rect.maxY - tailHeight)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeading))
        } else {
            path.addLine(to: CGPoint(x: rect.minX + bottomLeading, y: rect.maxY))
            addCorner(
                to: &path,
                center: CGPoint(x: rect.minX + bottomLeading, y: rect.maxY - bottomLeading),
                radius: bottomLeading,
                startAngle: .degrees(90),
                endAngle: .degrees(180)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeading))
        }

        addCorner(
            to: &path,
            center: CGPoint(x: rect.minX + topLeading, y: rect.minY + topLeading),
            radius: topLeading,
            startAngle: .degrees(180),
            endAngle: .degrees(270)
        )

        path.closeSubpath()
        return path
    }
}

private extension MessageBubbleShape {
    func addCorner(
        to path: inout Path,
        center: CGPoint,
        radius: CGFloat,
        startAngle: Angle,
        endAngle: Angle
    ) {
        guard radius > 0 else { return }
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
    }

    func addTrailingTail(to path: inout Path, topAttachment: CGPoint, bottomAttachment: CGPoint) {
        let tip = CGPoint(x: bottomAttachment.x + tailWidth, y: bottomAttachment.y)
        let hypotenuse = hypot(topAttachment.x - tip.x, topAttachment.y - tip.y)
        let radius = min(tailRadius, tailWidth / 2, hypotenuse / 2)

        guard hypotenuse > 0, radius > 0 else {
            path.addLine(to: tip)
            path.addLine(to: bottomAttachment)
            return
        }

        let onHypotenuse = CGPoint(
            x: tip.x + (topAttachment.x - tip.x) * (radius / hypotenuse),
            y: tip.y + (topAttachment.y - tip.y) * (radius / hypotenuse)
        )
        let onBottom = CGPoint(x: tip.x - radius, y: tip.y)

        path.addLine(to: onHypotenuse)
        path.addQuadCurve(to: onBottom, control: tip)
        path.addLine(to: bottomAttachment)
    }

    func addLeadingTail(to path: inout Path, bottomAttachment: CGPoint, topAttachment: CGPoint) {
        let tip = CGPoint(x: bottomAttachment.x - tailWidth, y: bottomAttachment.y)
        let hypotenuse = hypot(topAttachment.x - tip.x, topAttachment.y - tip.y)
        let radius = min(tailRadius, tailWidth / 2, hypotenuse / 2)

        guard hypotenuse > 0, radius > 0 else {
            path.addLine(to: tip)
            path.addLine(to: topAttachment)
            return
        }

        let onBottom = CGPoint(x: tip.x + radius, y: tip.y)
        let onHypotenuse = CGPoint(
            x: tip.x + (topAttachment.x - tip.x) * (radius / hypotenuse),
            y: tip.y + (topAttachment.y - tip.y) * (radius / hypotenuse)
        )

        path.addLine(to: onBottom)
        path.addQuadCurve(to: onHypotenuse, control: tip)
        path.addLine(to: topAttachment)
    }
}

