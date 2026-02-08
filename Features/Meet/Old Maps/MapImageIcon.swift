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
     
     let isSearch: Bool
     
     var size: CGFloat {
         if isSearch {
             return 30
         } else {
             return 23
         }
     }
     
     
     var body: some View {
         VStack() {
             ZStack {
                 if !isSearch {
                     Circle()
                         .fill(Color.white)
                         .frame(width: size + 5, height: size + 5)
                         .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
                 }
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

                 category.imageSmall
                     .symbolRenderingMode(.monochrome)
                     .foregroundStyle(.white)
                     .font(.system(size: size * 0.42, weight: .semibold))
             }
             .frame(width: size, height: size)

             
             
             
         }
         
         
     }
 }

 #Preview {
     MapImageIcon(category: .restaurant, isSearch: false)
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
