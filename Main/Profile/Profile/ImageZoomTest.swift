//
//  ImageZoomTest.swift
//  Scoop
//
//  Created by Art Ostin on 15/01/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func pinchZoom(_ dimsBackground: Bool = true) -> some View {
        PinchZoomHelper(dimsBackground: dimsBackground) {
            self
        }
    }
}

struct ZoomContainer<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    private var containerData = ZoomContainerData()
    var body: some View {
        GeometryReader { _ in
            content
                .environment(containerData)
            
            ZStack(alignment: .topLeading) {
                if let view = containerData.zoomingView {
                    view
                        .scaleEffect(containerData.zoom, anchor: containerData.zoomAnchor)
                        .offset(containerData.dragOffset)
                        .offset(x: containerData.viewRect.minX, y: containerData.viewRect.minY)
                }
            }
            .ignoresSafeArea()
    }
        .coordinateSpace(name: ZoomContainerConstants.coordinateSpace)
    }
}


private enum ZoomContainerConstants {
    static let coordinateSpace = "zoomContainer"
}


@Observable
fileprivate class ZoomContainerData {
    var zoomingView: AnyView?
    var viewRect: CGRect = .zero
    var dimsBackground: Bool = false
    
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
}

fileprivate struct PinchZoomHelper<Content: View> : View {
    var dimsBackground: Bool
    @ViewBuilder var content: Content
    
    @Environment(ZoomContainerData.self) private var containerData
    @State private var config: Config = .init()
    var body: some View {
        content
            .opacity(config.hidesSourceView ? 0 : 1)
            .overlay(GestureOverlay(config: $config))
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .named(ZoomContainerConstants.coordinateSpace))
                    Color.clear
                        .onChange(of: self.config.isGestureActive) {oldValue, newValue in
                            if newValue {
                                containerData.viewRect = rect
                                containerData.zoomAnchor = config.zoomAnchor
                                containerData.dimsBackground = dimsBackground
                                containerData.zoomingView = .init(erasing: content)
                                
                                config.hidesSourceView = true
                            } else {
                                withAnimation(.snappy(duration: 0.3), completionCriteria: .logicallyComplete) {
                                    containerData.dragOffset = .zero
                                    containerData.zoom = 1
                                } completion: {
                                    config = .init()
                                    containerData.zoomingView = nil
                                }
                            }
                        }
                        .onChange(of: config.zoom) { oldValue, newValue in
                            if config.isGestureActive {
                                containerData.zoom = config.zoom
                            }
                        }
                        .onChange(of: config.dragOffset) { oldValue, newValue in
                            if config.isGestureActive {
                                containerData.dragOffset = config.dragOffset
                            }
                        }
                }
            }
    }
}

fileprivate struct GestureOverlay: UIViewRepresentable {
    @Binding var config: Config
    
    func makeCoordinator() -> Coordinator {
        Coordinator(config: $config)
    }
    
    func makeUIView(context: Context ) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "PINCHPANGESTURE"
        panGesture.minimumNumberOfTouches = 2
        panGesture.addTarget(context.coordinator, action: #selector(Coordinator.panGesture(gesture:)))
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.name = "PINCHZOOMGESTURE"
        pinchGesture.addTarget(context.coordinator, action: #selector(Coordinator.pinchGesture(gesture:)))
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)
        

        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var config: Config
        init(config: Binding<Config>) {
            self._config = config
        }
        
        @objc
        func panGesture(gesture: UIPanGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                config.dragOffset = .init(width: translation.x, height: translation.y)
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        @objc
        func pinchGesture(gesture: UIPinchGestureRecognizer) {
            
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                if let bounds = gesture.view?.bounds  {
                    config.zoomAnchor = .init(x: location.x / bounds.width, y: location.y / bounds.height)
                }
            }
            
            
            
            if gesture.state == .began || gesture.state == .changed {
                let scale = max(gesture.scale, 1)
                config.zoom = scale
                
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        //Maybe change later
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer.name == "PINCHPANGESTURE" || otherGestureRecognizer.name == "PINCHZOOMGESTURE" {
                return true
            }
            return false
        }
    }
}


fileprivate struct Config: Equatable {
    var isGestureActive: Bool = false
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var hidesSourceView: Bool = false
}
