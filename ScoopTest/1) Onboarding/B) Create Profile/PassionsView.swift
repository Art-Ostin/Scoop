//
//  Passions.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/06/2025.
//

import SwiftUI
import SwiftUIFlowLayout

struct PassionsView: View {
    
    @State private var selectedTabIndex: Int = 0
    
    @State private var selectedPassions: [String] = []
    
    @State private var socialPassions: [String] = [ "Bars", "Raves", "Clubbing", "Movie Nights", "House Party", "Darties", "Dinner Parties", "Road Trips", "Concerts", "Wine n Dine", "Pub", "Game Nights", "Brunch", "Festival", "Karoke"]
    
    
    
    
    var body: some View {
        
        VStack{
            
            titleSection
            
            menuScroll

            tabView
                .padding(.horizontal, -5)
            
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 32)
    }
}

#Preview {
    PassionsView()
        .environment(AppState())
        .offWhite()
}


extension PassionsView {
    
    private var titleSection: some View {
        SignUpTitle(text: "Passions", count: 3, subtitle: "(max 5)")
            .padding(.top, 60)
            .padding(.bottom, 60)
    }
    
    private var menuScroll: some View {
        VStack (spacing: 17) {
            HStack {
                Text("Explore")
                    .foregroundStyle( selectedTabIndex == 0 ? .accent : Color(red: 0.3, green: 0.3, blue: 0.3) )
                Spacer()
                Text("Custom")
                    .foregroundStyle( selectedTabIndex == 1 ? .accent : Color(red: 0.3, green: 0.3, blue: 0.3) )
            }
            .padding(.horizontal, 5)
            .font(.body(16, .bold))
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 332, height: 1, alignment: .center)
                    .foregroundStyle(Color(red: 0.86, green: 0.86, blue: 0.86))
                
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 67, height: 1)
                    .frame(maxWidth: .infinity, alignment: selectedTabIndex == 0 ? .leading : .trailing)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.bottom, 36)
    }
    
    private var tabView: some View {
        TabView (selection: $selectedTabIndex) {
            
            ScrollView {
                VStack (alignment: .leading){
                    
                    sectionTitle(image: "figure.socialdance", title: "Social")
                    
                    newSocialPassions
                    
                }
                
                
                    .tag(0)
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            
            Text ("Page 2")
                .tag (1)
            
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

    
extension PassionsView {
    
    private var newSocialPassions: some View {
        
        
        FlowLayout(mode: .scrollable, items: socialPassions, itemSpacing: 6) { item in
            Button {
                if let index = selectedPassions.firstIndex(of: item) {
                    selectedPassions.remove(at: index)
                } else {
                    selectedPassions.append(item) 
                }
            } label: {
                Text(item)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .font(.body(14))
                    .background(selectedPassions.contains(item) ? Color.clear : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                    )
                    .foregroundStyle(.black)
            }
        }
    }
    
}


private struct sectionTitle: View {
    
    let image: String
    let title: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 21) {
            Image(systemName: image)
                .resizable()
                .frame(width: 22, height: 20)
            
            Text(title)
                .font(.body(20))
                .offset(y: 1)
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 16)

    }
    
}
