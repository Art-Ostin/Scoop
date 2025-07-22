//
//  Prompts.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//





class Prompts {
    
    static let instance = Prompts()
    
    
    let prompts1: [String] = [
        "My favourite bathroom on campus",
        "In five years time I hope to be",
        "My ideal Saturday Night involves",
        "My Pleasures",
        "The dream date",
        "My biggest F**K up",
        "Since arriving at McGill I’ve learnt"
    ]
    
    let prompts2: [String] = [
        "My McGill confession:",
        "Three qualities I look for in a person",
        "I’ll fall for you if",
        "I’m looking for",
        "My wildest experience",
        "I’ll know you’re the one if",
        "My defining values"
    ]
    
    let prompts3: [String] = [
        "By the end of the degree I hope to be",
        "My most harrowing experience",
        "Chairs or Couches. Why?",
        "My controversial take",
        "I'll say yes if you invite me to",
        "The dream date",
        "In five years time I hope to be"
    ]

}


enum Prompt: String, Hashable {
    case youllJustHave = "You’ll just have to meet me to find out about"
    case wantToBe = "Want to be shocked? Ask me about"
    case iWillTell = "I will tell you the best place at McGill to"
    case myIdealDate = "My ideal date involves"
    case onTheDate = "on the date I’ll steer the convo towards "
    case onASaturday = "On a Saturday night you’ll find me... "
    case aTuesdayNight = "A Tuesday Night involves"
    case wouldYouBe = "Would you be a sausage or a pear? Why?"
    case myUnapologeticPleasures = "My unapologetic pleasures"
    case threeWordsThat = "Three words that capture who I am"
}
