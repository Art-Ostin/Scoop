//
//  EventMapView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//
import SwiftUI
import MapKit

struct EventMapView: View {
    
    let event: UserEvent
    let imageSize: CGFloat
    @Binding var disableMap: Bool
    let openMaps: () -> ()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    private let toggleAnimation = Animation.easeInOut(duration: 0.2)
    
    private var mapHeight: CGFloat {
        imageSize > 50 ? imageSize - 24 : imageSize
    }
    
    private var defaultCamera: MapCamera {
        MapCamera(centerCoordinate: coord, distance: 1300)
    }
    
    var coord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: event.location.latitude,
            longitude: event.location.longitude
        )
    }
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                Marker(event.location.name ?? "", systemImage: "mappin", coordinate: coord)
                    .tint(.red)
                
                UserAnnotation()
                    .tint(.blue)
            }
            .allowsHitTesting(!disableMap)
            
            if disableMap {
                TwoFingerActivationOverlay {
                    enableMapFromGesture()
                }
            }
        }
        .tint(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(width: imageSize, height: mapHeight)
        .scaleEffect(disableMap ? 1 : 1.03)
        .overlay(alignment: .bottomTrailing) {
            openInMapsButton(event: event)
        }
        .overlay(alignment: .topTrailing) {
            enableMapButton
        }
        .onAppear {
            cameraPosition = .camera(defaultCamera)
        }
        .surfaceShadow(.floating, strength: !disableMap  ? 0.6 : 0)
        .animation(toggleAnimation, value: disableMap)
        .task(id: disableMap) {
            guard disableMap else { return }
            await Task.yield()
            guard disableMap else { return }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    cameraPosition = .camera(defaultCamera)
                }
            }
        }
    }
}

extension EventMapView {
    private var enableMapButton: some View {
        Button {
            withAnimation(toggleAnimation) {
                disableMap.toggle()
            }
        } label: {
            Text(disableMap ? "Enable Map" : "Disable Map")
                .font(.body(10, .bold))
                .foregroundStyle(Color.black)
                .padding(6)
                .padding(.horizontal, 2)
//                .stroke(16, lineWidth: 1, color: .accent)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white).opacity(0.9)
                )
                .contentShape(.rect)
                .padding()
                .padding(4)
        }
    }
    
    private func enableMapFromGesture() {
        guard disableMap else { return }
        
        withAnimation(toggleAnimation) {
            disableMap = false
        }
    }
    
    
    
    private func openInMapsButton(event: UserEvent) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                openMaps()
            }
        } label: {
            Text("Open Maps")
                .font(.custom("SFProRounded-Semibold", size: 14))
                .foregroundStyle(Color.black)
                .opacity(0.6)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .underline()
        }
    }
}

private struct TwoFingerActivationOverlay: UIViewRepresentable {
    let onActivate: () -> Void
    
    func makeUIView(context: Context) -> TouchView {
        let view = TouchView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true
        view.onTwoFingerTouch = onActivate
        return view
    }
    
    func updateUIView(_ uiView: TouchView, context: Context) {
        uiView.onTwoFingerTouch = onActivate
    }
    
    final class TouchView: UIView {
        var onTwoFingerTouch: (() -> Void)?
        private var didTriggerCurrentTouchSequence = false
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            triggerIfNeeded(with: event)
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesMoved(touches, with: event)
            triggerIfNeeded(with: event)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            resetIfNeeded(with: event)
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            didTriggerCurrentTouchSequence = false
        }
        
        private func triggerIfNeeded(with event: UIEvent?) {
            guard didTriggerCurrentTouchSequence == false else { return }
            
            let touchCount = event?.allTouches?.filter {
                $0.phase != .ended && $0.phase != .cancelled
            }.count ?? 0
            
            guard touchCount >= 2 else { return }
            didTriggerCurrentTouchSequence = true
            onTwoFingerTouch?()
        }
        
        private func resetIfNeeded(with event: UIEvent?) {
            let touchCount = event?.allTouches?.filter {
                $0.phase != .ended && $0.phase != .cancelled
            }.count ?? 0
            
            if touchCount < 2 {
                didTriggerCurrentTouchSequence = false
            }
        }
    }
}



/*
 HStack(spacing: 6) {
     Image(systemName: "map")
         .font(.body(14, .bold))
     
     Text("Open Maps")
         .foregroundStyle(Color.blue)
         .font(.body(12, .bold))
 }
 .padding(.horizontal, 8)
 .tint(.blue)
 .padding(.vertical, 6)
 .glassIfAvailable()
 .padding(.horizontal)
 .padding(.vertical, 10)

 */
