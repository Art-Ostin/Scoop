//
//  NewInterests.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct NewInterests: View {
    
    
    
    
    var body: some View {
        
        CustomList {
            NavigationLink {
                destination
            } label : {
                VStack(spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.body(12, .bold))
                            .foregroundStyle(Color.grayText)
                        Spacer()
                        Image("EditGray")
                    }
                    .padding(.horizontal, 8)
                    
                }
            }
        }
    }
}

#Preview {
    NewInterests()
}
