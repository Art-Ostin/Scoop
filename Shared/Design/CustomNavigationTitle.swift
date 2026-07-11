//
//  ColorMenu.swift
//  Scoop
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

//The custom navigationTitle

extension UINavigationBar {

    static func scoopAppearance(largeTitleSize: CGFloat = 32) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: UIFont.title(largeTitleSize, .bold)]
        appearance.titleTextAttributes      = [.font: UIFont.title(17, .semibold)]
        return appearance
    }

    static func applyScoopAppearance() {
        let appearance = scoopAppearance()
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

private struct NavigationBarFontEnforcer: UIViewControllerRepresentable {

    let largeTitleSize: CGFloat

    func makeUIViewController(context: Context) -> EnforcerController {
        let controller = EnforcerController()
        controller.update(largeTitleSize: largeTitleSize)
        return controller
    }

    func updateUIViewController(_ vc: EnforcerController, context: Context) {
        vc.update(largeTitleSize: largeTitleSize)
    }

    final class EnforcerController: UIViewController {

        private var observations: [NSKeyValueObservation] = []
        private var ticker: Timer?
        private weak var ownerItem: UINavigationItem?
        private var largeTitleSize: CGFloat = 32
        private var scoopAppearance = UINavigationBar.scoopAppearance()

        func update(largeTitleSize: CGFloat) {
            guard self.largeTitleSize != largeTitleSize else { return }
            self.largeTitleSize = largeTitleSize
            scoopAppearance = UINavigationBar.scoopAppearance(largeTitleSize: largeTitleSize)
            enforce()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if ownerItem == nil {
                ownerItem = navigationController?.topViewController?.navigationItem
            }
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
            let barAppearance = UINavigationBar.scoopAppearance()
            let barTarget = barAppearance.largeTitleTextAttributes[.font] as? UIFont

            let bar = nav.navigationBar
            if (bar.standardAppearance.largeTitleTextAttributes[.font] as? UIFont) != barTarget {
                bar.standardAppearance   = barAppearance
                bar.scrollEdgeAppearance = barAppearance
                bar.compactAppearance    = barAppearance
            }

            //Keep this override on the owning screen so pushed destinations use the default size.
            guard let item = ownerItem else { return }
            let itemAppearance = scoopAppearance
            let itemTarget = itemAppearance.largeTitleTextAttributes[.font] as? UIFont

            if (item.standardAppearance?.largeTitleTextAttributes[.font] as? UIFont) != itemTarget {
                item.standardAppearance = itemAppearance
            }
            if (item.scrollEdgeAppearance?.largeTitleTextAttributes[.font] as? UIFont) != itemTarget {
                item.scrollEdgeAppearance = itemAppearance
            }
            if (item.compactAppearance?.largeTitleTextAttributes[.font] as? UIFont) != itemTarget {
                item.compactAppearance = itemAppearance
            }
        }
    }
}

extension View {
    //Apply inside a NavigationStack's root content (a sibling outside the stack
    //cannot reach the navigation controller).
    func scoopNavigationBarFonts(largeTitleSize: CGFloat = 32) -> some View {
        background(NavigationBarFontEnforcer(largeTitleSize: largeTitleSize))
    }
}
