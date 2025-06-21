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
    
    @State var HSpacing: CGFloat = 32
    
    @State var VSpacing: CGFloat = 54
    
    @State var isFilled: Bool = true
    
    
    var body: some View {
        
        let columns: [GridItem] = {
            if width < 100 { return options.map { _ in GridItem(.fixed(61), spacing: HSpacing)} }
            else { return [GridItem(.adaptive(minimum: 148), spacing: HSpacing)]}} ()
        
        LazyVGrid(columns: columns, alignment: .leading, spacing: 54) {
                ForEach(options.indices, id: \.self) { index in
                    OptionCell(options: options, selectedIndex: $selectedIndex, width: width, isFilled: isFilled, index: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

#Preview {
    OptionView(options: ["Hello", "World", "Hello"], width: 148, isFilled: false)
        .padding(32)
        .environment(AppState())
}




struct OptionCell: View {
    
    @Environment(AppState.self) private var appState
    
    @State var options: [String]
    
    @Binding var selectedIndex: Int?
    
    @State var width:  CGFloat
    
    @State var isFilled: Bool
    
    @State var index: Int
    
    var body: some View {
        Text(options[index])
            .frame(width: width, height: 44)
            .background(selectedIndex == index ? Color.accentColor : (isFilled ? Color.grayBackground : Color.clear))
            .cornerRadius(20)
            .font(.body(16, .bold))
            .foregroundStyle(selectedIndex == index ? .white: .black)
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(selectedIndex == index ? Color.accentColor : Color.grayBackground, lineWidth: isFilled ? 0 : 2))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)){
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
