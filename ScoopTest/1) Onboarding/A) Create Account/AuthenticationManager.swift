//
//  AuthenticationManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import Foundation
import FirebaseAuth


final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    
    private init() {}
    
    lazy var actionCodeSettings: ActionCodeSettings = {
      let s = ActionCodeSettings()
      s.url = URL(string: "https://www.example.com")!
      s.handleCodeInApp = true
      s.setIOSBundleID(Bundle.main.bundleIdentifier!)
      s.setAndroidPackageName(
        "com.example.android",
        installIfNotAvailable: false,
        minimumVersion: "12"
      )
      return s
    }()

}
