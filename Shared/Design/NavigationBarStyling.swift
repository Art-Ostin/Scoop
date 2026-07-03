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
