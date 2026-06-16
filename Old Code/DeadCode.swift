//
//  DeadCode.swift
//  Scoop
//
//  Created by Art Ostin on 15/06/2026.
//



/*
 Measuring bottom of scrollView then passing it up
 //1
 func measure<Key: PreferenceKey>(key: Key.Type = Key.self, value transform: @escaping (GeometryProxy) -> Key.Value) -> some View {
     modifier(GeoPreferenceKey<Key>(transform: transform))
 }

 // 1. Measure this view’s geometry and write the transformed value into a PreferenceKey
 struct GeoPreferenceKey<Key: PreferenceKey>: ViewModifier {
     let transform: (GeometryProxy) -> Key.Value
     
     func body(content: Content) -> some View {
         content
             .background(
                 GeometryReader { geo in
                     Color.clear
                         .preference(key: Key.self,
                                     value: transform(geo))
                 }
             )
     }
 }
 */
