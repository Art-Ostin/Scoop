//
//  DropDownTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownTest: View {
    ///Customisation Properties
    var hint: String
    var options: [String]
    var anchor: Anchor = .bottom
    var maxWidth: CGFloat = 180
    var cornerRaidus: CGFloat = 15
    @Binding var selection: String?

    ///View Properties
    @State private var showOptions: Bool = false
    
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            VStack(spacing: 0)  {
                HStack (spacing: 0) {
                    Text(selection ?? hint)
                        .foregroundStyle(selection == nil ? .gray : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .rotationEffect(.init( degrees: showOptions ? -180 : 0))
                    
                }
                .padding(.horizontal, 15)
                .frame(width: size.width, height: size.height)
                .contentShape(.rect)
                .background(scheme == .dark ? .black : .white)
                .onTapGesture {
                    withAnimation(.snappy()) {
                        showOptions.toggle()
                    }
                }
                .background(Color.blue)
                
                if showOptions {
                    OptionsView()
                }

            }
            .clipped()
            .background((scheme == .dark ? Color.black : Color.white).shadow(.drop(color: .primary.opacity(0.15), radius: 4)), in : .rect(cornerRadius: cornerRaidus))
        }
        .frame(width: maxWidth, height: 50)
    }
    
    @ViewBuilder
    func OptionsView() -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                HStack(spacing: 0) {
                    Text(option)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark")
                        .opacity(selection == option ? 1 : 0)
                }
                .foregroundStyle(selection == option ? Color.primary: Color.gray)
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selection = option
                        
                        showOptions = false
                    }
                }

            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .top))
    }
    
    enum Anchor {
        case top
        case bottom
    }
}

#Preview {
    ContentView()
}
