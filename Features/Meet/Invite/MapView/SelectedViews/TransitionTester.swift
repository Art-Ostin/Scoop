//
//  TransitionTester.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//

import SwiftUI

struct TransitionTester: View {
    @State var showMainAnnotation = false
    
    @Namespace var ns
    
    var body: some View {
        VStack {
            Text("Hello world")
            
            if showMainAnnotation {
                MapAnnotation(category: .restaurant)
                    .matchedGeometryEffect(id: "test", in: ns)
            } else {
                MapImageIcon(category: .airport)
                    .matchedGeometryEffect(id: "test", in: ns)
            }
        }
        .onTapGesture {
            showMainAnnotation.toggle()
        }
        .animation(.easeInOut(duration: 0.3), value:showMainAnnotation )
    }
}

#Preview {
    TransitionTester()
}
