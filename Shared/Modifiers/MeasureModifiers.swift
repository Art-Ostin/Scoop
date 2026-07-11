//
//  MeasureModifiers.swift
//  Scoop
//
//  Created by Art Ostin on 15/06/2026.
//

import SwiftUI

//Helpers that report a view's measured geometry into bound state.
extension View {
    
    func getHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height.wrappedValue = $0 }
    }
    
    func getWidth(_ width: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width.wrappedValue = $0 }
    }
    
    func getRect(_ rect: Binding<CGRect>, coordSpace: String? = nil) -> some View {
        onGeometryChange(for: CGRect.self) { geo in
            geo.frame(in: coordSpace.map { CoordinateSpace.named($0) } ?? .global) }
        action: {
            rect.wrappedValue = $0
        }
    }
    
    func getBottom(coordinateSpace: String, bottom: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { geo in
            geo.frame(in: .named(coordinateSpace)).maxY
        } action: { bottomPosition in
            if bottom.wrappedValue < 25 { //Updates only once. If less than 25 it indicates still on transient
                bottom.wrappedValue = bottomPosition
            }
        }
    }
}
