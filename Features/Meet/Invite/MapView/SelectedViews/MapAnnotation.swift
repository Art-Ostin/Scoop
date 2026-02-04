//
//  SwiftUIView.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//


import SwiftUI
import MapKit


struct MapAnnotation: View {
    
    let category: MKPointOfInterestCategory
    let size: CGFloat = 65
    
    private var colorGradient: LinearGradient {
        LinearGradient(
            colors: [
                category.startColor,
                category.endColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    
    var ringWidth: CGFloat = 4
    var dipWidthRatio: CGFloat = 0.5
    var dipHeightRatio: CGFloat = 0.17
    var dipOverlapRatio: CGFloat = 0.25
    var dipCurveRatio: CGFloat = 0.80
    
    private var innerSize: CGFloat { max(size - ringWidth * 2, 0) }
    private var dipWidth: CGFloat {size * dipWidthRatio }
    private var dipHeight: CGFloat { size * dipHeightRatio }
    private var dipOverlap: CGFloat { size * dipOverlapRatio }
    private var totalHeight: CGFloat { size + dipHeight - dipOverlap }
    

    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                Circle()
                    .frame(width: size, height: size)
                
                PinDipShape(curveRatio: dipCurveRatio)
                    .frame(width: dipWidth, height: dipHeight)
                    .offset(y: size - 4)
                
                SmallDot(color: colorGradient)
                    .offset(y: size + 12)
            }
            .foregroundStyle(.white)
            .defaultShadow()
            
            ZStack {
                Circle()
                    .fill(colorGradient)

                category.imageLarge
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white)
                    .font(.system(size: innerSize * 0.46, weight: .semibold))
            }
            .frame(width: innerSize, height: innerSize)
            .offset(y: ringWidth)
        }
        .frame(width: size, height: totalHeight, alignment: .top)
        .offset(y: -24)
    }
}

private struct SmallDot: View {
    let color: LinearGradient

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(Color.white)
            
            Circle()
                .frame(width: 7, height: 7)
                .foregroundStyle(color)
        }
        .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
    }
}




private struct PinDipShape: Shape {
    var curveRatio: CGFloat
    var tipRadiusRatio: CGFloat = 0.25 // increase for rounder tip

    
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let topY = rect.minY
        let tipY = rect.maxY
        let midX = rect.midX

        let tipWidth: CGFloat = 3              // width of the rounded bottom
        let neckInset: CGFloat = w * 0.35        // bigger = slants inward sooner
        let startPullY: CGFloat = h * 0.3      // how soon the inward slant begins
        let endDropY: CGFloat = h * 0.1         // bigger = more “vertical drop” near bottom

        let leftJoin  = CGPoint(x: midX - tipWidth/2, y: tipY)
        let rightJoin = CGPoint(x: midX + tipWidth/2, y: tipY)

        // Left side cubic controls:
        // control1 sets the start tangent (pull inward early)
        // control2 sets the end tangent (make it drop vertically into leftJoin)
        let leftC1 = CGPoint(x: rect.minX + neckInset, y: topY + startPullY)
        let leftC2 = CGPoint(x: leftJoin.x,          y: tipY - endDropY)

        // Rounded tip cap (simple + smooth)
        let capDepth: CGFloat = tipWidth * 0.7
        let capControl = CGPoint(x: midX, y: tipY + capDepth)

        // Right side cubic controls (mirrored)
        let rightC1 = CGPoint(x: rightJoin.x,         y: tipY - endDropY)
        let rightC2 = CGPoint(x: rect.maxX - neckInset, y: topY + startPullY)

        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: topY))

        // left side: inward then drop
        path.addCurve(to: leftJoin, control1: leftC1, control2: leftC2)

        // rounded drip tip
        path.addQuadCurve(to: rightJoin, control: capControl)

        // right side: rise back up (mirror)
        path.addCurve(to: CGPoint(x: rect.maxX, y: topY), control1: rightC1, control2: rightC2)

        path.closeSubpath()
        return path
    }
}

/*
 MapAnnotation(image: Image(systemName: "fork.knife"), startColor: Color(red: 0.99, green: 0.69, blue: 0.28), endColor: Color(red: 0.96, green: 0.44, blue: 0.18))
f
 */
