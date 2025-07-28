//
//  Interests2.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

//import SwiftUI
//
//
//
//struct InterestsView: View {
//
//    
//    @Environment(\.appDependencies) private var dependencies: AppDependencies
//
//    var body: some View {
//        
//        let user = dependencies.userStore.user
//        
//        let interests = user?.interests ?? []
//        
//        let character = user?.character ?? [("Add info")]
//                
//        
//        let sections = [
//            ("Social", "figure.socialdance", vm.socialPassions),
//            ("Interests", "book", vm.interests),
//            ("Activities", "MyCustomShoe", vm.activities),
//            ("Sports", "tennisball", vm.sportsPassions),
//            ("Music", "MyCustomMic", vm.music1),
//            (nil, nil, vm.music2),
//            (nil, nil, vm.music3)
//        ]
//
//        let sections2 = [
//            ("Social", "figure.socialdance", vm.socialPassions),
//            ("Interests", "book", vm.interests),
//            ("Activities", "MyCustomShoe", vm.activities),
//            ("Sports", "tennisball", vm.sportsPassions),
//            ("Music", "MyCustomMic", vm.music1),
//            (nil, nil, vm.music2),
//            (nil, nil, vm.music3)
//        ]
//        
//        
//            CustomList {
//                
//                NavigationLink {
//                    EditInterests(sections: sections, title: "Interests", isOnboarding: false)
//                } label: {
//                VStack(spacing: 8) {
//                    HStack {
//                        Text("Interests")
//                            .font(.body(12, .bold))
//                            .foregroundStyle(Color.grayText)
//                        
//                        Spacer()
//                        
//                        Image("EditGray")
//                    }
//                    .padding(.horizontal, 8)
//                    InterestsLayout(passions: interests)
//                }
//                .padding(.horizontal)
//            }
//                
//           NavigationLink {
//               EditInterests(sections: sections2, title: "Character", isOnboarding: false)
//                    } label: {
//                        VStack(spacing: 8) {
//                        HStack {
//                            Text("Character")
//                                .font(.body(12, .bold))
//                                .foregroundStyle(Color.grayText)
//                            
//                            Spacer()
//                            
//                            Image(character.count < 1 ? "EditButton" : "EditGray")
//                        }
//                        .padding(.horizontal, 8)
//                        InterestsLayout(passions: character)
//                    }
//                }
//                    .padding(.horizontal)
//                    .padding(.top, 24)
//            }
//            .padding(.horizontal, 32)
//            .foregroundStyle(Color.black)
//        }
//}
//
//
