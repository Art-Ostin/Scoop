//
//  ImageTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI

struct ImageTest: View {
    var body: some View {
        
        let url = URL(string: "https://picsum.photos/200")
        
               
        AsyncImage(url: url) { image in
            
            
            
            
        } placeholder: {
            
        }
    }
}

#Preview {
    ImageTest()
}
