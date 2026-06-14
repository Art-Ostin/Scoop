//
//  ColorMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//


// Default UI for The App


import SwiftUI
import UIKit





extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}

extension Color {
    static let appBackground = Color(red: 0.42, green: 0.40, blue: 0.30)
        
    static let appCanvas = Color(red: 0.99, green: 0.98, blue: 0.97)

    static let grayBackground = Color (red: 0.93, green: 0.93, blue: 0.93)
    
    static let grayText = Color (red: 0.6, green: 0.6, blue: 0.6)
    
    static let grayPlaceholder = Color (red: 0.85, green: 0.85, blue: 0.85)
    
    static let secondary = Color (red: 0, green: 0.6, blue: 0.52)
    
    static let appGreen =   Color(red: 0, green: 0.47, blue: 0.41)
    
    static let appRed = Color(red: 0.86, green: 0.21, blue: 0.27)
    
    static let dangerRed = Color(red: 0.94, green: 0.08, blue: 0.24)
    
    static let warningYellow = Color(red: 1, green: 0.75, blue: 0.03)
    
    static let appColorTint = Color(red: 0.78, green: 0, blue: 0.35)
}



extension UIColor {
    static let appBackground = UIColor(red: 0.42, green: 0.40, blue: 0.30, alpha: 1)
}

extension Font {
    
    enum bodyFontWeight: String {
        case regular = "ModernEra-Regular"
        case medium = "ModernEra-Medium"
        case bold = "ModernEra-Bold"
        case italic = "ModernEra-MediumItalic"
    }
    
    enum titleFontWeight: String {
        case bold = "SFProRounded-Bold"
        case semibold = "SFProRounded-Semibold"
        case medium = "SFProRounded-Medium"
    }

    static func body(_ size: CGFloat = 16, _ weight: bodyFontWeight = .medium) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func body(_ weight: bodyFontWeight) -> Font {
        .custom(weight.rawValue, size: 16)
    }

    static func title(_ size: CGFloat = 32, _ weight: titleFontWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func title(_ weight: titleFontWeight) -> Font {
        .custom(weight.rawValue, size: 32)
    }
}

extension UIFont {
    static func body(_ size: CGFloat = 16, _ weight: Font.bodyFontWeight = .medium) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size)
    }

    static func title(_ size: CGFloat = 32, _ weight: Font.titleFontWeight = .bold) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}

//The custom navigationTitle

extension UINavigationBar {

    static let scoopAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: UIFont.title(32, .bold)]
        appearance.titleTextAttributes      = [.font: UIFont.title(17, .semibold)]
        return appearance
    }()

    static func applyScoopAppearance() {
        UINavigationBar.appearance().standardAppearance   = scoopAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scoopAppearance
    }
}

//Newer iOS 26 builds have SwiftUI re-assert the navigation bar's appearance
//objects after content/tab transitions — both bar-level and per-item (a
//UINavigationItem appearance overrides the bar AND the proxy) — so the title
//silently falls back to the system font. A one-shot fix loses that race; this
//enforcer keeps watching the enclosing bar and restores the Scoop appearance
//whenever anything overwrites it. Every pass is guarded by a font check, so
//it settles immediately and never loops.
private struct NavigationBarFontEnforcer: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> EnforcerController { EnforcerController() }
    func updateUIViewController(_ vc: EnforcerController, context: Context) {}

    final class EnforcerController: UIViewController {

        private var observations: [NSKeyValueObservation] = []
        private var ticker: Timer?

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            enforce()
        }

        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            enforce()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            enforce()
            startWatching()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stopWatching()
        }

        private func startWatching() {
            guard let bar = navigationController?.navigationBar, observations.isEmpty else { return }
            //Catches bar-level overwrites the moment they happen.
            observations = [
                bar.observe(\.standardAppearance)   { [weak self] _, _ in self?.enforceAsync() },
                bar.observe(\.scrollEdgeAppearance) { [weak self] _, _ in self?.enforceAsync() },
            ]
            //Item-level overwrites aren't observable from the bar: sweep them up.
            let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.enforceAsync()
            }
            RunLoop.main.add(timer, forMode: .common)
            ticker = timer
        }

        private func stopWatching() {
            observations = []
            ticker?.invalidate()
            ticker = nil
        }

        private nonisolated func enforceAsync() {
            DispatchQueue.main.async { [weak self] in self?.enforce() }
        }

        private func enforce() {
            guard let nav = navigationController else { return }
            let scoop = UINavigationBar.scoopAppearance
            let target = scoop.largeTitleTextAttributes[.font] as? UIFont

            let bar = nav.navigationBar
            if (bar.standardAppearance.largeTitleTextAttributes[.font] as? UIFont) != target {
                bar.standardAppearance   = scoop
                bar.scrollEdgeAppearance = scoop
                bar.compactAppearance    = scoop
            }

            //Per-item appearances beat the bar's — restyle any the system installed.
            guard let item = nav.topViewController?.navigationItem else { return }
            if let installed = item.standardAppearance,
               (installed.largeTitleTextAttributes[.font] as? UIFont) != target {
                item.standardAppearance = scoop
            }
            if let installed = item.scrollEdgeAppearance,
               (installed.largeTitleTextAttributes[.font] as? UIFont) != target {
                item.scrollEdgeAppearance = scoop
            }
            if let installed = item.compactAppearance,
               (installed.largeTitleTextAttributes[.font] as? UIFont) != target {
                item.compactAppearance = scoop
            }
        }
    }
}

extension View {
    //Apply inside a NavigationStack's root content (a sibling outside the stack
    //cannot reach the navigation controller).
    func scoopNavigationBarFonts() -> some View {
        background(NavigationBarFontEnforcer())
    }
}
