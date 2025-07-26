//
//  ImageTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImageTest: View {
    
    
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 36) {
                if let urlStrings = CurrentUserStore.shared.user?.imagePathURL {
                    ForEach(urlStrings, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            AsyncImage(url: url) { Image in
                                Image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                }
                
            }

            }
        }
    }
}

#Preview {
    ImageTest()
}
