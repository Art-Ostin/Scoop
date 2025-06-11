//
//  Components.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct NextButton: View {
    
    let isEnabled: Bool
    let onInvalidTap: () -> Void
    
    @Environment(ScoopViewModel.self) private var viewModel
    
    
    
    
    var body: some View {
        Button {
            if isEnabled {
                viewModel.nextPage()
            } else {
                onInvalidTap()
            }
            
        } label: {
            Image("ForwardArrow")
                .frame(width: 69, height: 44, alignment: .center)
                .background( isEnabled ? Color.accent : Color(red: 0.93, green: 0.93, blue: 0.93))
                .cornerRadius(33)
                .shadow(color: isEnabled ? .black.opacity(0.25) : .clear , radius: 2, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct submitButton: View {
    
    
    let isEnabled: Bool
    let onInvalidTap: () -> Void
    @Environment(ScoopViewModel.self) private var viewModel

    
    var body: some View {
        
        Button {
            if isEnabled {
                viewModel.nextPage()
                
            } else {
                onInvalidTap()
            }
        } label: {
            Image(systemName: "checkmark")
                .frame(width: 50, height: 50, alignment: .center)
                .background(isEnabled ? Color.accent : Color(red: 0.93, green: 0.93, blue: 0.93))
                .foregroundStyle(.white)
                .font(.system(size: 24, weight: .bold))
                .cornerRadius(1000)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        
        
    }
}



struct XButton: View {
    
    @Environment(ScoopViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        
        Button {
            viewModel.stageIndex = 0
            dismiss()
        }
        label: {
            HStack {
                Image(systemName: "xmark")
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .font(.system(size: 17))
            }
        }
    }
}


struct saveButton: View {
    
    
    @Environment(ScoopViewModel.self) private var viewModel
    
    var body: some View {
        Button {
            
        } label: {
            Text("Save")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                .font(.custom("ModernEra-Medium", size: 14))
        }
    }
}


struct titleView: View {
    let text: String
    let count: Int?
    let subtitle: String?
    
    
    init(text: String, count: Int, subtitle: String? = nil) {
        self.text = text
        self.count = count
        self.subtitle = subtitle
    }
    
    init(text: String, count: Int? = nil, subtitle: String? = nil) {
        self.text = text
        self.count = count
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12){
            
            Text(text)
                .font(.custom("NewYorkLarge-Bold", size: 28))
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            if let subtitle {
                Text(subtitle)
                    .font(.custom("NewYorkLarge-Bold", size: 12))
                    .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
                
            }
            Spacer()
            HStack(spacing: 14){
                ForEach(0..<(count ?? 0), id: \.self) {_ in
                    
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .inset(by: 0.5)
                                .stroke(.black, lineWidth: 1)
                        )
                }
            }
        }
    }
}



struct optionsView: View {
    
    let options: [String]
    let columns = [GridItem(.adaptive(minimum: 140))]
    
    
    
    @State private var selectedIndex: Int? = nil
    @Environment(ScoopViewModel.self) var viewModel
    
    let isFilled: Bool
    
    
    let width: CGFloat
    
    
    var body: some View {
        
        LazyVGrid(columns: columns, spacing: 54) {
            ForEach(0..<options.count, id: \.self) { index in
                Text(options[index])
                    .frame(width: width, height: 44)
                    .background(Color(selectedIndex == index ? Color.accentColor :
                                    (isFilled ? Color(red: 0.93, green: 0.93, blue: 0.93) : Color.clear))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedIndex == index ? Color.accentColor : (isFilled ? Color.clear : Color(red: 0.93, green: 0.93, blue: 0.93)), lineWidth: 4)
                        )
                        .animation(.easeInOut(duration: 0.1), value: selectedIndex)
                    .foregroundStyle(selectedIndex == index ? .white : .black)
                    .cornerRadius(20)
                    .animation(.easeInOut(duration: 0.1), value: selectedIndex)
                    .font(.custom(selectedIndex == index ? "ModernEra-Bold" :"ModernEra-Medium", size: 16))
                    .onTapGesture {
                        selectedIndex = index
                            viewModel.nextPage()
                    }
            }
        }
    }
}


struct inputTextBox: View {
    let placeholder: String
    var inputtedText: Binding<String>
    let textSize: CGFloat
    var isFocused: FocusState<Bool>.Binding
    
    
    var body: some View {
        
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if inputtedText.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.custom("ModernEra-MediumItalic", size: textSize))
                        .foregroundStyle(.gray)
                        .padding(.leading, 5)
                }
                
                TextField("", text: inputtedText)
                    .font(.custom("ModernEra-Medium", size: textSize))
                    .focused(isFocused)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .tint(.blue)
                    .kerning(0.5)
                    .foregroundStyle(.black)
            }
            Rectangle()
                .frame(width: 303, height: 1)
                .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


#Preview {
    
    NextButton(isEnabled: true, onInvalidTap: { })
        .environment(ScoopViewModel())
    
    XButton()
        .environment(ScoopViewModel())
    
    titleView(text: "Hello", count: 4)
    
    submitButton(isEnabled: true, onInvalidTap: {})
        .environment(ScoopViewModel())
    
    saveButton()
        .environment(ScoopViewModel())
    
    optionsView(options: ["Option 1", "Option 2", "Option 3"], isFilled: true, width: 163)
        .environment(ScoopViewModel())
}


