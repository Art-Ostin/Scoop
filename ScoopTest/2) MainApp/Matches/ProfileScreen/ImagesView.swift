//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImageView: View {
    
   
    
    var body: some View {
        VStack {
            if let urls = EditProfileViewModel.instance.user?.imagePathURL {
                ForEach(urls, id: \.self) {url in
                    if let url = URL(string: url) {
                        AsyncImage(url: url) { Image in
                            Image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    ImageView()
}
