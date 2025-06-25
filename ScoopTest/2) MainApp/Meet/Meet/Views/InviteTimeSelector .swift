//
//  InviteTimeSelector .swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI



struct timePopup: View {
    
    var body: some View {
        
        VStack {
            
            InviteTimeSelector()
            
            Divider()
            
            TimeSelect()
            
            
        }
        .padding([.leading, .trailing, .bottom], 32)
        .padding(.top, 24)
        .frame(width: 335, height: 326)
        .background(Color.background)
        .cornerRadius(30)
        .overlay (
            RoundedRectangle(cornerRadius: 30).stroke(Color.grayBackground, lineWidth: 0.5)
        )
    }
    
    
}


#Preview {
    timePopup()
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
            ForEach(nextSevenDays.indices, id: \.self) { date in
                
                let isToday = Calendar.current.isDate(nextSevenDays[date], inSameDayAs: today)

                VStack(spacing: 24) {
                    Text(nextSevenDays[date], format: .dateTime.weekday(.narrow))
                        .font(.body(12, .bold))

                    Text(nextSevenDays[date], format: .dateTime.day())
                        .font(.body(18))
                        .foregroundStyle(isToday ? .blue: .black)
                        .frame(width: 40, height : 40)
                        .background(selectedIndex == date ? Color.accent.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedIndex = date
                        }
                }
                .frame(width: 36, height: 60)
            }
        }
        .padding()
    }
}


#Preview {
    InviteTimeSelector()
}
