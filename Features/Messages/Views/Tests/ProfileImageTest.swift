//
//  ProfileImageTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/06/2026.

import SwiftUI

struct ProfileImageTest: View {
    @State private var expanded = false

    var body: some View {
        ZStack {
            profileLayer

            profileImage
        }
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.snappy) {
                expanded.toggle()
            }
        }
    }
}

extension ProfileImageTest {

    // The expanded "profile" surface — background + chrome. Maps to ProfileView's
    // ZStack { ... }.background(profileBackground). Fades in as the image grows.
    private var profileLayer: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Hello World")
                Spacer().frame(height: 250)
                Text("Hello World")
            }
        }
        .opacity(expanded ? 1 : 0)
    }
    
    private var profileImage: some View {
        ZStack {
            Image("Demo1")
                .resizable()
                .scaledToFill()
                .opacity(expanded ? 0 : 1)

            Image("Demo2")
                .resizable()
                .scaledToFill()
                .opacity(expanded ? 1 : 0)
        }
        .frame(width: expanded ? 250 : 44, height: expanded ? 250 : 44)
        .clipShape(.rect(cornerRadius: expanded ? 16 : 22))
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: expanded ? .center : .topTrailing)
    }
}

#Preview {
    ProfileImageTest()
}

// MARK: - True-morph version
// Single drawing image (true corner morph via MorphShape) whose frame/position is
// owned by an anchor INSIDE profileLayer — maps onto ProfileView's structure while
// keeping a genuine circle→rounded-rect morph (not a cross-fade).

struct ProfileMorphTest: View {
    @State private var expanded = false
    // Second phase: the swipeable gallery only appears once the morph has settled,
    // so the growing image never fights a full-size ScrollView mid-animation.
    @State private var showGallery = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            // Collapsed frame anchor — lives outside the profile layer.
            Color.clear
                .frame(width: 44, height: 44)
                .matchedGeometryEffect(id: "photo", in: ns, isSource: !expanded)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            profileLayer

            morphingImage
        }
        .contentShape(.rect)
        .onTapGesture { toggle() }
    }

    private func toggle() {
        let willExpand = !expanded
        withAnimation(.snappy) { expanded = willExpand }
        if willExpand {
            Task {
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.easeInOut(duration: 0.2)) { showGallery = true }
            }
        } else {
            showGallery = false
        }
    }
}

extension ProfileMorphTest {

    private var profileLayer: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Hello World")
                // Expanded frame anchor — owned by the layer's layout, where the
                // image lands. This is the structural map onto ProfileImageView.
                Color.clear
                    .frame(width: 250, height: 250)
                    .matchedGeometryEffect(id: "photo", in: ns, isSource: expanded)

                Text("Hello World")
            }
        }
        .opacity(expanded ? 1 : 0)
    }

    // One persistent view so the corner radius truly interpolates. Demo1 is also
    // page one of the gallery, so the hand-off to the ScrollView is invisible.
    private var morphingImage: some View {
        Image("Demo1")
            .resizable()
            .scaledToFill()
            .opacity(showGallery ? 0 : 1)
            .frame(width: expanded ? 250 : 44, height: expanded ? 250 : 44)
            .clipShape(MorphShape(cornerRadius: expanded ? 16 : 22))
            // Base stays visible underneath the opaque gallery — never hidden, so there's
            // nothing to un-hide on dismiss and no teardown gap / flash.
            .overlay {
                if showGallery {
                    gallery.transition(.asymmetric(insertion: .opacity, removal: .identity))
                }
            }
            .matchedGeometryEffect(id: "photo", in: ns, isSource: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: expanded ? .center : .topTrailing)
    }

    // Phase two: swipe through all six photos. Page one is Demo1 at the same 250pt
    // frame, so it lands exactly over the morphed image with no jump.
    private var gallery: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(1...6, id: \.self) { i in
                    Image("Demo\(i)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(MorphShape(cornerRadius: 16))
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .frame(width: 250, height: 250)
    }
}

struct MorphShape: Shape {
    var cornerRadius: CGFloat
    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

// MARK: - Path A: zoom navigation transition (iOS 18+)
// The system performs the morph from the circular thumbnail into the destination,
// so the gallery genuinely lives INSIDE the destination view — no anchors, no
// hide/teardown dance, no flash. The morph is framework-driven (same engine as the
// Photos/app-icon zoom) and the starting shape comes from the source's clipShape.

struct ProfileZoomTest: View {
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            NavigationLink {
                ProfileGalleryDestination()
                    .navigationTransition(.zoom(sourceID: "photo", in: ns))
            } label: {
                Image("Demo1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(.circle)
                    .matchedTransitionSource(id: "photo", in: ns)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
        }
    }
}

struct ProfileGalleryDestination: View {
    // Chrome fades in on appear (concurrent with the zoom). The zoom still scales the
    // whole destination, but a uniform color/text being scaled is imperceptible — so
    // visually only the gallery photo reads as zooming while the background fades in.
    @State private var showChrome = false

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
                .opacity(showChrome ? 1 : 0)

            VStack(spacing: 24) {
                Text("Hello World")
                    .opacity(showChrome ? 1 : 0)
                gallery   // stays opaque so it visibly zooms
                Text("Hello World")
                    .opacity(showChrome ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { showChrome = true }
        }
    }

    // Lives inside the destination — exactly where ProfileView's image/gallery sits.
    private var gallery: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(1...6, id: \.self) { i in
                    Image("Demo\(i)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(.rect(cornerRadius: 16))
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .frame(width: 250, height: 250)
    }
}

#Preview("Zoom") {
    ProfileZoomTest()
}
