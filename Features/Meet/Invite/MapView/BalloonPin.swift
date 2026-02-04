//
//  SwiftUIView.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//


import SwiftUI

struct MapForkKnifePinIcon: View {
    var size: CGFloat = 52
    var ringWidth: CGFloat = 4
    var dipWidthRatio: CGFloat = 0.45
    var dipHeightRatio: CGFloat = 0.25
    var dipOverlapRatio: CGFloat = 0.25
    var dipCurveRatio: CGFloat = 0.80

    private var innerSize: CGFloat { max(size - ringWidth * 2, 0) }
    private var dipWidth: CGFloat { size * dipWidthRatio }
    private var dipHeight: CGFloat { size * dipHeightRatio }
    private var dipOverlap: CGFloat { dipHeight * dipOverlapRatio }
    private var totalHeight: CGFloat { size + dipHeight - dipOverlap }

    let image: Image
    let startColor: Color
    let endColor: Color
    
    private var orangeGradient: LinearGradient {
        LinearGradient(
            colors: [
                startColor,
                endColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                Circle()
                    .frame(width: size, height: size)

                PinDipShape(curveRatio: dipCurveRatio)
                    .frame(width: dipWidth, height: dipHeight)
                    .offset(y: size - 5.5)
                            
//                            /* - dipOverlap*/)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)

            ZStack {
                Circle()
                    .fill(orangeGradient)

                image
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white)
                    .font(.system(size: innerSize * 0.46, weight: .semibold))
            }
            .frame(width: innerSize, height: innerSize)
            .offset(y: ringWidth)
        }
        .frame(width: size, height: totalHeight, alignment: .top)
    }
}

private struct PinDipShape: Shape {
    var curveRatio: CGFloat
    var tipRadiusRatio: CGFloat = 0.25 // increase for rounder tip

    
    func path(in rect: CGRect) -> Path {
        let width = rect.width + 10
        let height = rect.height
        let topY = rect.minY
        let tipY = rect.maxY
        let midX = rect.midX

        let controlYOffset = height * (curveRatio - 0.4)
        let leftControl = CGPoint(x: rect.minX + width * 0.2, y: topY + controlYOffset)
        let rightControl = CGPoint(x: rect.maxX - width * 0.2, y: topY + controlYOffset)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: topY))
        path.addQuadCurve(to: CGPoint(x: midX, y: tipY), control: leftControl)
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: topY), control: rightControl)
        path.closeSubpath()
        path.addArc(tangent1End: CGPoint(x: midX, y: tipY), tangent2End: CGPoint(x: rect.maxX, y: topY), radius: 12)
        return path
    }
}

#Preview {
    VStack(spacing: 24) {
        MapForkKnifePinIcon(image: Image(systemName: "fork.knife"), startColor: Color(red: 0.99, green: 0.69, blue: 0.28), endColor: Color(red: 0.96, green: 0.44, blue: 0.18))
//        MapForkKnifePinIcon(size: 64, ringWidth: 5)
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}
