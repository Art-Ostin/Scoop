//
//  OptionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct OptionView: View {
    
    
    @Environment(AppState.self) private var appState
    
    @State var options: [String]
    
    @State var selectedIndex: Int? = nil
    
    @State var width:  CGFloat
    
    @State var height: CGFloat
    
    @State var isFilled: Bool = false
    
    
    
    
    /// If it is filled
    /// Background Gray If not, a clear background.
    ///
    ///
    /// If it is Filled an overlay of and stroke of gray
    
    
    
    
    var body: some View {
        
        let columns: [GridItem] = {
            if width < 30 { return options.map { _ in GridItem(.fixed(61), spacing: 10)} }
            else { return [GridItem(.adaptive(minimum: 148), spacing: 32)]}} ()
        
        
        LazyVGrid(columns: columns, alignment: .leading, spacing: 54) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index])
                        .frame(width: width, height: height)
                        .background(selectedIndex == index ? Color.gray : Color.clear)
                    
    
                    
                        .cornerRadius(20)
                        .font(.body(16, .bold))
                        .foregroundStyle(selectedIndex == index ? .white: .black)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.accentColor, lineWidth: 2))
                    
                    
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)){
                                selectedIndex = index
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    appState.nextStep()
                                }
                            }
                        }
                    
                        
                    
                    
                    
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

#Preview {
    OptionView(options: ["Hello", "World"], width: 48, height: 30, isFilled: true)
        .padding(32)
        .environment(AppState())

}
