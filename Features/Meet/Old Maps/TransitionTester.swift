//
//  TransitionTester.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//

import SwiftUI

import MapKit



/*
 
 
 struct TransitionTester: View {
     @State private var showMainAnnotation = false
     @Namespace private var ns
     
     var cameraPosition: MapCameraPosition = .region(
         MKCoordinateRegion(
             center:  CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
             span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.08) // city-ish view
         )
     )
     var body: some View {
         VStack {
             Text("Hello world")

             Map {
                 Annotation("Hello World", coordinate: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673)) {
                     if showMainAnnotation {
                         MapAnnotation(category: .restaurant)
                             .opacity(showMainAnnotation ? 1 : 0)
                             .scaleEffect(showMainAnnotation ? 1 : 0.92)
                             .matchedGeometryEffect(id: "container", in: ns)
                     } else {
                         MapImageIcon(category: .airport, isSearch: false)
                             .opacity(showMainAnnotation ? 0 : 1)
                             .scaleEffect(showMainAnnotation ? 0.92 : 1)
                             .matchedGeometryEffect(id: "container", in: ns)
                     }
                 }
             }
                     
         }
         .contentShape(Rectangle())
         .onTapGesture {
             withAnimation(.easeInOut(duration: 0.3)) {
                 showMainAnnotation.toggle()
             }
         }
     }
 }

 #Preview {
     TransitionTester()
 }

 struct TransitionTester: View {
     @State private var showMainAnnotation = false
     @Namespace private var ns
     
     var cameraPosition: MapCameraPosition = .region(
         MKCoordinateRegion(
             center:  CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
             span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.08) // city-ish view
         )
     )
     var body: some View {
         VStack {
             Text("Hello world")

             Map {
                 Annotation("Hello World", coordinate: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673)) {
                     if showMainAnnotation {
                         MapAnnotation(category: .restaurant)
                             .opacity(showMainAnnotation ? 1 : 0)
                             .scaleEffect(showMainAnnotation ? 1 : 0.92)
                             .matchedGeometryEffect(id: "container", in: ns)
                     } else {
                         MapImageIcon(category: .airport, isSearch: false)
                             .opacity(showMainAnnotation ? 0 : 1)
                             .scaleEffect(showMainAnnotation ? 0.92 : 1)
                             .matchedGeometryEffect(id: "container", in: ns)
                     }
                 }
             }
                     
         }
         .contentShape(Rectangle())
         .onTapGesture {
             withAnimation(.easeInOut(duration: 0.3)) {
                 showMainAnnotation.toggle()
             }
         }
     }
 }

 #Preview {
     TransitionTester()
 }

 
 */


