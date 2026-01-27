//
//  ContentView.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct ContentView: View {
    
    //View Properties
    @State var isExpanded: Bool = false
    
    var body: some View {
            VStack(spacing: 15) {
                
                Button("Click Me") {
                    
                }
                
                DropDownView(showOptions: $isExpanded) {
                    HStack {
                        Text("Grab a drink")
                            .font(.body( 17, .bold))
                        
                        Spacer()
                        
                        DropDownButton(isExpanded: $isExpanded)
                    }
                } dropDown: {
                    SelectTypeView(vm: .init(text: "Hello World"), selectedType: .drink)
                }
                
                Button("Click Me") {
                    
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea(edges: .all)
            .background(Color.background)

        }
    }

#Preview {
    ContentView()
}
