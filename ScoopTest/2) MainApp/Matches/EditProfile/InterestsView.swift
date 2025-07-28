//
//  Interests2.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

import SwiftUI

//struct InterestsView: View {
//    
////    
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
////        let sections = [
////            ("Social", "figure.socialdance", vm.socialPassions),
////            ("Interests", "book", vm.interests),
////            ("Activities", "MyCustomShoe", vm.activities),
////            ("Sports", "tennisball", vm.sportsPassions),
////            ("Music", "MyCustomMic", vm.music1),
////            (nil, nil, vm.music2),
////            (nil, nil, vm.music3)
////        ]
////
////        let sections2 = [
////            ("Social", "figure.socialdance", vm.socialPassions),
////            ("Interests", "book", vm.interests),
////            ("Activities", "MyCustomShoe", vm.activities),
////            ("Sports", "tennisball", vm.sportsPassions),
////            ("Music", "MyCustomMic", vm.music1),
////            (nil, nil, vm.music2),
////            (nil, nil, vm.music3)
////        ]
////        
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
//struct InterestsLayout: View {
//    
//    let passions: [String]
//    
//    
//    private var rows: [[String]] {
//        stride(from: 0, to: passions.count, by: 2).map {
//            Array(passions[$0..<min($0+2, passions.count)])
//        }
//    }
//    var body: some View {
//    
//            VStack(spacing: 16) {
//                    ForEach(rows.indices, id: \.self) { index in
//                        let row = rows[index]
//                        HStack {
//                            
//                            Text(row[safe: 0] ?? "")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            
//                            Divider()
//                                .frame(height: 20)
//                            
//                            Text(row.count > 1 ? row[1] : "")
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        }
//                        
//                        if index < rows.count - 1 {
//                            Divider()
//                        }
//                    }
//                
//            }
//            .padding()
//            .font(.body())
//            .foregroundStyle(passions.count < 1 ? Color.accent : Color.black)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.white)
//                    .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
//            )
//            .overlay(RoundedRectangle(cornerRadius: 12).stroke(passions.count < 1 ? Color.accent : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 0.5))
//
//        }
//        
//    }
//
//extension Array {
//    subscript(safe index: Int) -> Element? {
//        indices.contains(index) ? self[index] : nil
//    }
//}
//

//#Preview {
//    InterestsLayout(interests: ["Running", "Football", "Cricket", "Golf", "Hockey", "Table Tennis"])
//}
