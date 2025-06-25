//
//  ProfileView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI


struct ProfileView: View {
    
    @Binding var state: MeetSections
    
    @State private var name: String = "Arthur"
    @State private var nationality: [String] = ["🇬🇧", "🇸🇪"]
    
    @State private var images: [String] = ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"]
    @State private var selection: Int = 0
    
    @State private var year = "U3"
    @State private var height = "193"
    @State private var passions: [String] = ["Astrophysics", "Cold Water Swimming", "Music Production", "Historical Geology"]
    @State private var hometown = "London"
    @State private var lookingFor = "Casual"
    @State private var Faculty = "Faculty of Arts"
    
    @State private var PassionImages: [String] = ["graduationcap", "arrow.up.and.down", "magnifyingglass", "graduationcap", "house", "smiley"]
    
    
    @State private var topSelection: [String] = []
    
    @State private var promptSelection1 = Prompts.instance["three words that"]
    @State private var promptSelection2 = Prompts.instance["on the date"]
    
    @State private var tabViewSelection: Int = 0
            

    
    let pageSpacing: CGFloat = -48
    
    //Screen Toggles for the Offset
    @State var startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.78
    @State var currentDragOffsetY: CGFloat = 0
    @State var endingOffsetY: CGFloat = 0
    
    
    private var isSheetOpen: Bool {
      endingOffsetY < 0
    }
    

    var body: some View {

        GeometryReader { geo in
            
            let topGap = geo.size.height * 0.07
            
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    heading
                        .padding()

                    imageSection
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(width: geo.size.width, height: 430)
                    
                    imageScrollSection
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                
                ProfileDetailsView()
                    .offset(y: startingOffsetY)
                    .offset(y: currentDragOffsetY)
                    .offset(y: endingOffsetY)
                    .frame(width: geo.size.width)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .frame(width: 300)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            endingOffsetY = (endingOffsetY == 0)
                                ? (topGap - startingOffsetY)
                                : 0
                        }
                    }
                    .gesture (
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.spring()){
                                    currentDragOffsetY = value.translation.height
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if currentDragOffsetY < -50 {
                                        endingOffsetY = (endingOffsetY == 0)
                                          ? (topGap - startingOffsetY)  
                                          : 0
                                        
                                    } else if endingOffsetY != 0 && currentDragOffsetY > 100 {
                                        endingOffsetY = 0
                                    }
                                    currentDragOffsetY = 0
                                }
                            }
                    )
            }
        }
        .onAppear {
            topSelection = [year, height, lookingFor, Faculty, hometown, "Cold water Swimming"]
        }
    }
}


#Preview {
    ProfileView(state: .constant(.profile))
        .environment(AppState())
        .offWhite()
}

extension ProfileView {
    
    private var heading: some View {
        HStack {
            Text(name)
                .font(.body(24, .bold))
            ForEach (nationality, id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(20, .bold))
                .onTapGesture {
                    state = .twoDailyProfiles
                }
        }
    }
    
    private var imageSection: some View {
        GeometryReader { geo in
            
            if topSelection.count == images.count {
                TabView(selection: $selection) {
                    ForEach(images.indices, id: \.self) {index in
                        VStack{
                            HStack {
                                
                                Image(systemName: PassionImages[index])
                                
                                Text(topSelection[index])
                                    .font(.body(18))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .font(.body(18))
                            Image(images[index])
                                .frame(height: 380)
                                .overlay(alignment: .bottomTrailing) {
                                    InviteButton()
                                        .padding(24)
                                }
                        }
                        .tag(index)
                    }
                }
            }
        }
    }
    
    private var imageScrollSection: some View {
        ScrollViewReader {proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack (spacing: 48) {
                    ForEach(images.indices, id: \.self) {index in
                        ZStack {
                            Image(images[index])
                                .resizable()
                                .scaledToFit( )
                                .frame(width: 60, height: 60)
                                .cornerRadius(16)
                                .shadow(color: selection == index ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 10)
                            if selection == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor, lineWidth: 1)
                                    .frame(width: 60, height: 60)
                            }
                            
                        }
                        .id(index)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)){
                                selection = index
                            }
                        }
                    }
                }
                .padding()
            }
            .onChange(of: selection) {oldIndex,newIndex in
                if oldIndex < 3 && newIndex == 3 {
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .leading)
                    }
                }
                if oldIndex >= 3 && newIndex == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .trailing)
                    }
                }
            }
        }
    }
    
    private var inviteButton: some View {
        
        Button {
            
        } label: {
            Image("LetterIconProfile")
                .foregroundStyle(.white)
                .frame(width: 53, height: 53)
            
                .background(
                    Circle()
                        .fill(Color.accent.opacity(0.95))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 5)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
