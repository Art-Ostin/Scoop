//
//  InviteTimeSelector .swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI


struct SelectTimeView: View {
    
    @Binding var selectedTime: Date?
    
    @Binding var showTimePopup: Bool
    
    
    
    var body: some View {
        
        VStack {
            
            InviteTimeSelector(selectedTime: $selectedTime)
            
            Divider()
            
            DatePicker("Select a Time", selection: Binding(get: {selectedTime ?? Date()}, set: {selectedTime = $0}), displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .foregroundStyle(.black)
            
            Image(systemName: "checkmark")
                .font(.body(.bold))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.accent)
                .offset(y: -24)
                .onTapGesture {
                    showTimePopup.toggle()
                }
            
        }
        .padding([.leading, .trailing], 32)
        .padding(.top, 24)
        .frame(width: 335)
        .background(Color.background)
        .cornerRadius(30)
        .overlay (
            RoundedRectangle(cornerRadius: 30).stroke(Color.grayBackground, lineWidth: 0.5)
        )
    }
    
    
}


#Preview {
    SelectTimeView(
       selectedTime: .constant(Date()), showTimePopup: .constant(false))
    .padding()
}

struct TimeSelect: View {
    
    var body: some View {
        
        ScrollView {
            VStack {
                ForEach(0..<24, id: \.self) {index in
                    
                    Text("\(index)")
                        .font(.body(22))
                }
            }
        }
        .frame(width: 41, height: 152)
    }
}






struct InviteTimeSelector: View {
    
    @State private var selectedIndex: Int = 1
    
    @Binding var selectedTime: Date?
    
    private let today = Date()

    private let nextSevenDays: [Date] = {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }()
    
    
    var body: some View {
        HStack(spacing: 12) {
            
            ForEach(nextSevenDays.indices, id: \.self) { idx in
                
                let day = nextSevenDays[idx]
                
                let isToday = Calendar.current.isDate(day, inSameDayAs: today)
                

                VStack(spacing: 24) {
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.body(12, .bold))

                    Text(day, format: .dateTime.day())
                        .font(.body(18))
                        .foregroundStyle((isToday && !(selectedIndex == idx)) ? .blue: .black)
                        .frame(width: 40, height : 40)
                        .background(selectedIndex == idx ? Color.accent.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            
                            selectedIndex = idx
                            selectedTime = day
                        }
                }
                .frame(width: 36, height: 60)
            }
        }
        .padding()
    }
}


#Preview {
    InviteTimeSelector(selectedTime: .constant(Date()))
}
