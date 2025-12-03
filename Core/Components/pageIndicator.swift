//
//  pageIndicator.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct pageIndicator: View {
    
    let count: Int
    let selection: Int
    
    var body: some View {
        HStack {
            ForEach(0..<count, id: \.self) { value in
                
                if value == selection {
                    ZStack {}
                        .frame(width: 10, height: 5)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.black)
                        )
                } else {
                    ZStack {}
                        .frame(width: 5, height: 5)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.clear)
                                .stroke(100, lineWidth: 1, color: .black)
                            )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    pageIndicator(count: 5, selection: 3)
}
