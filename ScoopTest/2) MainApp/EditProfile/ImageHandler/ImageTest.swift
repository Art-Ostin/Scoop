//
//  ImageTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImageTest: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    var body: some View {
        
        let user = dependencies.userStore.user
        
        ScrollView {
            VStack(spacing: 36) {
                if let urlStrings = user?.imagePathURL {
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
