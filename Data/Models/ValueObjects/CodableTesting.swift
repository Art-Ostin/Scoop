//
//  CodableTesting.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

import SwiftUI


struct TestUser: Codable {
    let name: String
    let age: Int
}




struct CodableTesting: View {
    
    let data: Data
    
    @State var user: TestUser?
    
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
        .task {
            do {
                self.user = try JSONDecoder().decode(TestUser.self, from: data)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    CodableTesting()
}
