//
//  DateFormatterTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import SwiftUI

struct DateFormatterTest: View {
    
    var body: some View {
        
        Text(.now, format: .dateTime.month(.abbreviated).day(.defaultDigits).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))

    }
}

#Preview {
    DateFormatterTest()
}
