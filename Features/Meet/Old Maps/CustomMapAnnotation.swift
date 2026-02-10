//
//  CustomMapAnnotation.swift
//  Scoop
//
//  Created by Art Ostin on 10/02/2026.
//

import SwiftUI
import MapKit

struct CustomMapAnnotation: View {
    
    @Bindable var vm: MapViewModel
    
    let item: MKMapItem
    
    let category: MapCategory
    
    let isSelected: Bool

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

                category.image
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white)
                    .font(.system(size: innerSize * 0.46, weight: .semibold))
            }
            .frame(width: innerSize, height: innerSize)
            .offset(y: ringWidth)
        }
        .frame(width: size, height: totalHeight, alignment: .top)
        .offset(y: -24)
        .onTapGesture {
            withAnimation (.easeInOut(duration: 0.3)) {
                vm.selectedMapItem = item
            }
        }
        .scaleEffect(isSelected ? 1 : 0.5)
    }
}
//
//#Preview {
//    CustomMapAnnotation()
//}
