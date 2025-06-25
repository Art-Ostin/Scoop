//
//  SendInviteView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SendInviteView: View {
    
    let name: String
    
    @State var showTypePopup: Bool = false
    
    @State var typeInputText: String = ""
    
    @State var typeDefaultOption: String = ""
    
    @State var showMessageScreen: Bool = false
    
    
    
    var body: some View {
        
        ZStack {
            PopupTemplate(profileImage: "Image1", title: "Meet Arthur") {
                
                VStack(spacing: 30) {
                                        
                    InviteTypeRowView(typeDefaultOption: typeDefaultOption, typeInputText: $typeInputText, showTypePopup: $showTypePopup, showMessageScreen: $showMessageScreen)
                    
                    
                    Divider()
                    
                    
                    
                    
                    
                }
            }
            
            if showTypePopup {
                
                SelectTypeView(typeDefaultOption: $typeDefaultOption, showTypePopup: $showTypePopup)
                
            }
            
        }
        .sheet(isPresented: $showMessageScreen) {
            InviteAddMessageView(typeInputText: $typeInputText, typeDefaultOption: $typeDefaultOption, showTypePopup: $showTypePopup)
        }
    }
}

#Preview {
    SendInviteView(name: "Arthur")
}
