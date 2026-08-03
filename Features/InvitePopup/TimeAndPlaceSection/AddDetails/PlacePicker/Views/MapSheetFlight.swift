//
//  MapSheetFlight.swift
//  Scoop
//
//  Created by Art Ostin on 03/08/2026.
//

import SwiftUI
import MapKit

//The stand-in sheet that rides the opening transition. A fullScreenCover cannot contain a real
//sheet while its own transition is running (UIKit presents one thing at a time), so this inert
//twin — the same platter and live content the real sheet shows — is part of MapView's hierarchy
//from the first frame, and the assembled map-plus-sheet slides in as one unit. The real sheet
//then presents invisibly behind it (non-animated, identical geometry) and MapView drops this
//overlay one rendered frame after the real content is on top.
struct MapSheetFlight: View {

    //Injected — the same model and bindings as the real sheet, so both render identically.
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @Binding var useSelectedDetent: Bool

    var body: some View {
        Group {
            //The twin must sit exactly where the real sheet will pop in or the handoff jumps.
            //A recorded frame from a previous presentation is pixel-exact for this device/OS;
            //only the first-ever open falls back to the measured constants.
            if let frame = Self.recordedSheetFrame {
                twin
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            } else {
                twin
                    .padding(.top, Self.topInset)
                    .padding(.horizontal, Self.chromeInset)
                    .padding(.bottom, Self.chromeInset)
            }
        }
        .ignoresSafeArea()
        //An inert twin: it must never take focus (its copy of the auto-focus task would raise
        //the keyboard from the cover's context and die when the real sheet presents) or touches.
        .disabled(true)
        .allowsHitTesting(false)
    }

    private var twin: some View {
        MapSheetContainer(
            vm: vm,
            sheet: $sheet,
            useSelectedDetent: $useSelectedDetent,
            onExitSelection: { _ in },
            selectedLocation: { _ in }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { MapSheetPlatter() }
        .clipShape(Self.sheetShape)
        .overlay(alignment: .top) { grabber } //Above the content, like the system's
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.border)
            .frame(width: 36, height: 5)
            .padding(.top, 5)
    }
}

extension MapSheetFlight {

    //Measured .large-detent chrome of the iOS 26 sheet — the twin must sit exactly where the
    //real sheet will pop in. The side/bottom inset is OS-version dependent (measured: ~3pt on
    //26.0, 8pt on 26.5); corners are the sheet's uneven continuous 38/56pt.
    private static var chromeInset: CGFloat {
        if #available(iOS 26.5, *) { 8 } else { 3 }
    }

    //The cover's own safe area only resolves when its transition completes, so mid-flight reads
    //are 0 and the twin would jump at landing — the window's inset is stable throughout.
    //26.5 seats the .large sheet ~12pt lower than 26.0 (video-measured on Arthur's device).
    private static var topInset: CGFloat {
        let safeTop = keyWindow?.safeAreaInsets.top ?? 59
        if #available(iOS 26.5, *) { return safeTop + 12 } else { return safeTop }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    //Self-calibration: the real sheet's frame is recorded on every presentation, so the twin is
    //pixel-exact on any device/OS from the second open onward — no chrome constants to chase.
    static func recordSheetFrame(_ frame: CGRect) {
        guard isPlausibleLargeSheetFrame(frame) else { return }
        UserDefaults.standard.set(
            [frame.minX, frame.minY, frame.width, frame.height].map(Double.init),
            forKey: Self.recordedFrameKey
        )
    }

    private static var recordedSheetFrame: CGRect? {
        guard let values = UserDefaults.standard.array(forKey: recordedFrameKey) as? [Double],
              values.count == 4 else { return nil }
        let frame = CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
        //Validated on read as well, so a bad frame persisted by an older build is ignored.
        return isPlausibleLargeSheetFrame(frame) ? frame : nil
    }

    //Keyboard avoidance compresses the sheet CONTENT's frame the moment focus engages — a
    //recording taken then is hundreds of points short and the twin would fly in truncated.
    //Only a near-full-height frame can be the settled .large sheet.
    private static func isPlausibleLargeSheetFrame(_ frame: CGRect) -> Bool {
        guard let bounds = keyWindow?.bounds else { return false }
        return frame.width > bounds.width * 0.9 && frame.height > bounds.height * 0.75
    }

    private static let recordedFrameKey = "MapSheetFlight.largeSheetFrame"

    static var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 38, bottomLeadingRadius: 56,
            bottomTrailingRadius: 56, topTrailingRadius: 38
        )
    }
}

//Stand-in for the system sheet background: regular Liquid Glass reproduces the iOS 26 sheet
//platter pixel-identically (glass params auto-scale with size).
struct MapSheetPlatter: View {

    var body: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular, in: MapSheetFlight.sheetShape)
        } else {
            MapSheetFlight.sheetShape.fill(.regularMaterial)
        }
    }
}
