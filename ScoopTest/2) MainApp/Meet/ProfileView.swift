//
//  ProfileView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI

struct ProfileView: View {
    
    @State private var selection: Int = 0
    
    
    /// Profile Images
    @State private var Image1: String = "A"
    @State private var Image2: String = "A"
    @State private var Image3: String = "A"
    @State private var Image4: String = "A"
    @State private var Image5: String = "A"
    @State private var Image6: String = "A"
    
    @State private var firstName: String = "Arthur"
    
    @State private var nationalities: [String] = ["🇬🇧", "🇸🇪"]
    
    
    @State var startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.83
    @State var currentDragOffsetY: CGFloat =  0
    @State var endingOffsetY: CGFloat = 0
    
    
    var body: some View {
        
        ZStack{
            Color.green.ignoresSafeArea()
            
            VStack{
                heading
                Image("ProfileImage1A")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 380, height: 380)
                
                Spacer()
                
            }
            
            MySignUpView()
                .offset(y: startingOffsetY)
                .offset(y: currentDragOffsetY)
                .offset(y: endingOffsetY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.spring()) {
                                currentDragOffsetY = value.translation.height
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()){
                                if currentDragOffsetY < -150 {
                                    endingOffsetY = -startingOffsetY
                                    currentDragOffsetY = 0
                                }else if endingOffsetY != 0 && currentDragOffsetY > 150 {
                                    currentDragOffsetY = 0
                                    endingOffsetY = 0
                                } else {
                                    currentDragOffsetY = 0
                                }
                            }
                        }
                )
                .ignoresSafeArea(edges: .bottom)
                .onTapGesture {
                    withAnimation(.spring()){
                        endingOffsetY = -startingOffsetY
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView()
        .offWhite()

}



extension ProfileView {
    
    private var heading: some View {
        HStack{
            
            Text(firstName)
                .font(.custom("ModernEra-Bold", size: 24))
            ForEach(nationalities, id: \.self) { nationality in
                Text(nationality)
                    .font(.custom("ModernEra-Bold", size: 24))
            }
            Spacer()
            Button {

            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding()
            }
        }
    }
    
    private var tabSection: some View {

        TabView (selection: $selection) {
            
            Tab("", image: "letterIcon", value: 0) {
                
            }
            
            Tab("", image: "LogoIcon", value: 1) {

            }
            
            Tab("", image: "MessageIcon", value: 2) {

            }
        }
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }
}


struct MySignUpView: View {
    var body: some View {
        VStack(spacing: 20){
            Image(systemName: "chevron.up")
                .padding(.top)
            
            Text("Sign Up")
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            Text("This is a new experiment it is also very interesting to see what people write to fill space")
                .multilineTextAlignment(.center)
            
            Text("Create Account")
                .padding()
                .padding(.horizontal)
                .background(Color.black)
                .cornerRadius(20)
                .foregroundStyle(.white)
            
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(30)
    }
}
