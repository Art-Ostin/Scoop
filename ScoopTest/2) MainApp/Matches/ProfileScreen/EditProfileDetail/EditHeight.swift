//
//  OptionSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI



#Preview {
    AttractedTo()
}

struct HeightSelection: View {
    
    @State private var isSelected: String? = nil
    
    let heightOptions = ["4' 5", "4' 6","4' 7","4' 8", "4' 9","4' 10","5' 0","5' 1","5' 2","5' 3", "5' 4", "5' 5", "5' 6", "5' 7", "5' 8", "5' 9", "5' 10", "6' 0", "6' 1", "6' 2", "6' 3", "6' 4", "6' 5", "6' 6", "6' 7", "6' 8", "6' 9", "7' 0"]

    @State var height = ["5' 5"]

    
    var body: some View {
        
        OptionSelect(title: "Height", isSelected: $isSelected) {
            
            Picker("Height", selection: $height) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                }
            }
            .pickerStyle(.wheel)
        }
        
    }
}

struct YearSelection: View {
    
    @State private var isSelected: String? = nil
    
    var body: some View {
        OptionSelect(title: "Year", isSelected: $isSelected) {
            HStack{
                ForEach(0..<5) { i in
                    OptionCell2(title: "U\(i)", width: 61, isSelected: $isSelected) {}
                    Spacer()
                }
            }
        }
    }
}
