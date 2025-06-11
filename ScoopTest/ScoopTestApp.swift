//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

@main
struct ScoopTestApp: App {
  @State private var viewModel = ScoopViewModel()
  var body: some Scene {
    WindowGroup {
        SignUpView()
        .environment(viewModel)
    }
  }
}
