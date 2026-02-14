//
//  DraftUserModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//


struct DraftProfile: Codable {
    let id: String
    let email: String
    var sex = ""
    var attractedTo = ""
    var year = ""
    var height = ""
    var interests: [String] = []
    var degree = ""
    var hometown = ""
    var nationality: [String] = []
    var lookingFor = ""
    var imagePath: [String] = []
    var imagePathURL: [String] = []
    var drinking = ""
    var smoking = ""
    var marijuana = ""
    var drugs = ""
    var prompt1 = PromptResponse(prompt: "", response: "")
    var prompt2 = PromptResponse(prompt: "", response: "")
    
    init(user: User) {
        self.id = user.uid
        self.email = user.email ?? ""
    }
}
