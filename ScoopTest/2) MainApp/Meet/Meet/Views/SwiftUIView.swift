//
//  SwiftUIView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//
import SwiftUI


struct TimeWheelPicker: View {
  @Binding var hour: Int
  @Binding var minute: Int

  private let hours = Array(0...23)
  private let minutes = stride(from: 0, to: 60, by: 15).map { $0 }

  var body: some View {
    HStack(spacing: 16) {
      WheelColumn(items: hours.map { String(format: "%02d", $0) },
                  selection: $hour)
      WheelColumn(items: minutes.map { String(format: "%02d", $0) },
                  selection: $minute)
    }
    .frame(height: 200)
  }
}

struct WheelColumn: View {
  let items: [String]
  @Binding var selection: Int

  // rowHeight, spacing, etc.
  var body: some View {
    ZStack {
      // The pink highlight pill
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(red:1, green:0.9, blue:0.95))
        .frame(height: 40)
      // The scrolling content
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            // add padding so first & last can center
            Color.clear.frame(height: 80)
            ForEach(items.indices, id: \.self) { idx in
              Text(items[idx])
                .font(.system(size: 24, weight: idx == selection ? .bold : .regular))
                .foregroundColor(idx == selection ? .black : .gray)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .id(idx)
            }
            Color.clear.frame(height: 80)
          }
        }
        .onChange(of: selection) { new in
          withAnimation { proxy.scrollTo(new, anchor: .center) }
        }
        .gesture(DragGesture()
          .onEnded { value in
            // compute which row is closest to center
            // update `selection` to that index
          }
        )
      }
    }
    .frame(width: 60)
  }
}

#Preview {
    @State var h = 10
    @State var m = 0
    TimeWheelPicker(hour: $h, minute: $m)
}
