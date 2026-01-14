//
//  TransitionTester.swift
//  Scoop
//
//  Created by Art Ostin on 14/01/2026.
//

import SwiftUI


struct ContentView: View {
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Tap the image")
                    .font(.title2.bold())

                NavigationLink {
                    DetailView()
                        .navigationTransition(.zoom(sourceID: "testImage", in: zoomNS))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jansj")
                            .font(.headline)

                        Image("CoolGuys")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .matchedTransitionSource(id: "testImage", in: zoomNS)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        }
        // This stays put across navigation and does NOT animate with the zoom.
        .overlay(alignment: .bottom) {
            Text("Hello World")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 12)
        }
    }
}

struct DetailView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detail Screen")
                .font(.title.bold())

            Image("CoolGuys")
                .resizable()
                .scaledToFill()
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Text("Some text below the image.")
            Spacer()
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
