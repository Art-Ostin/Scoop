//
//  Interests2.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

import SwiftUI

struct InterestsView: View {
    
    let passions: [String]
    
    private var rows: [[String]] {
        stride(from: 0, to: passions.count, by: 2).map {
            Array(passions[$0..<min($0+2, passions.count)])
        }
    }
    var body: some View {
        
        CustomList(title: "Interests") {
            VStack(spacing: 16) {
                
                
                Image("EditButtonBlack")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    HStack {
                        
                        Text(row[safe: 0] ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Text(row.count > 1 ? row[1] : "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if index < rows.count - 1 {
                        Divider()
                    }
                }
                
            }
            .padding()
            .font(.body())
        }
        .padding(.horizontal, 32)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    InterestsView(passions: ["Running", "Football", "Cricket", "Golf", "Hockey", "Table Tennis"])
}
