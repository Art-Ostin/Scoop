//
//  Prompts.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//


struct Prompt: Identifiable {
    let text: String
    var id: String {
        String(text.prefix(3).lowercased())
    }
}

struct Prompts {
    
    
    static let instance: [String: String] = [
        
        
        "you'll just have": "You’ll just have to meet me to find out about...",
        "want to be" : "Want to be shocked? Ask me about...",
        "I will tell" : "I will tell you the best place at McGill to...",
        "my ideal date" : "My ideal date involves...",
        "on the date" : "On the date i’ll steer the convo towards...",
        "on a saturday" : "On a Saturday night you’ll find me... ",
        "a tuesday night" : "A Tuesday night involves...",
        "would you be" : "Would you be a sausage or a pear? Why?...",
        "my unapologetic pleasures" : "My unapologetic pleasures...",
        "three words that" : "Three words that capture who I am... "
    ]
}
