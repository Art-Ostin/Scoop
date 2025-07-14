//
//  Quotes.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/06/2025.




struct quoteContent: Identifiable {
    let quoteText: String
    let name: String
    
    var id: String {
        let firstFiveWords = quoteText
            .components(separatedBy: " ")
            .prefix(5)
            .joined(separator: " ")
        return name + firstFiveWords
    }
}


class quotes {
    
    static let shared = quotes()
    
    let allQuotes: [quoteContent] = [
        
        quoteContent(quoteText: "You don't love someone for their looks, or their clothes, or for their fancy car, but because they sing a song only you can hear", name: "Oscar Wilde"),
        quoteContent(quoteText: "Oh let a 1000 Angels Gawp for they are witnessing the rare phenomenon of true love's gaze", name: "Anonymous"),
        quoteContent(quoteText: "If Life's a drink, then love's a drug", name: "Coldplay"),
        quoteContent(quoteText: "To say I love you, one must first know how to say the 'I'", name: "Ayn Rand"),
        quoteContent(quoteText: "Who, being loved, was poor?", name: "Oscar Wilde"),
        quoteContent(quoteText: "You know you're in love when you can't fall asleep because reality is finally better than your dreams", name: "Dr Suess")
        ]
}




