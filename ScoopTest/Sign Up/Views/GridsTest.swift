//
//  GridsTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/06/2025.
//

import SwiftUI

struct GridsTest: View {
    
    
    
    
    let columns: [GridItem] = [
        
        GridItem(.adaptive(minimum: 50, maximum: 300), spacing: nil, alignment: nil),
                 ]
    
    
    
    var body: some View {
        
        LazyVGrid(columns: columns) {
            ForEach(0..<50) {index in
                Rectangle()
                    .frame(height: 50)
            }
        }
        

    }
}

#Preview {
    GridsTest()
}

extension GridsTest {
    
    
}
