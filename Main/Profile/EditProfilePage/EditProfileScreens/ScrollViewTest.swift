//
//  ScrollViewTest.swift
//  Scoop
//
//  Created by Art Ostin on 21/11/2025.
//

import SwiftUI

struct TestView: View {
    
    
    @State var currentId: Int? = 1
    
    var body: some View {
        
        
        ZStack {
            ScrollView {
                VStack(spacing: 96) {
                    ForEach(1...4, id: \.self) {_ in
                        Rectangle()
                            .frame(width: 300, height: 300)
                            .foregroundStyle(.orange)
                    }
                    .padding(.bottom, 96)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $currentId, anchor: .top)
            
            HStack {
                ForEach(1...4, id: \.self) { idx in
                    Text("\(idx)")
                        .foregroundStyle(currentId == idx ? .red : .primary)
                        .onTapGesture {
                            withAnimation { currentId = idx }
                        }
                }
            }
        }
    }
}

#Preview("TestView") {
    TestView()
}
