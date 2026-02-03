//
//  MapImageIcon.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI
import MapKit



struct MapImageIcon: View {
    
    let category: MKPointOfInterestCategory
    
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            category.startColor,
                            category.endColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: category.image)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white)
                .font(.system(size: size * 0.42, weight: .semibold))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    MapImageIcon(category: .restaurant)
        .padding()
}



/*
 struct ForkKnifeBadge: View {
     
     
     var size: CGFloat = 30

     var body: some View {
         ZStack {
             Circle()
                 .fill(
                     LinearGradient(
                         colors: [
                             Color(red: 1.00, green: 0.84, blue: 0.20), // bright yellow
                             Color(red: 0.96, green: 0.64, blue: 0.10)  // warm orange
                         ],
                         startPoint: .top,
                         endPoint: .bottom
                     )
                 )
                 .frame(width: size, height: size)

             Image(systemName: "fork.knife")
                 .symbolRenderingMode(.monochrome)
                 .foregroundStyle(.white)
                 .font(.system(size: size * 0.42, weight: .semibold))
         }
         .frame(width: size, height: size)
     }
 }

 */
