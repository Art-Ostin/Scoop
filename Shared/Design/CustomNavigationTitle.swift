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

    let title: String
    let largeTitleSize: CGFloat

    func makeUIViewController(context: Context) -> EnforcerController {
        let controller = EnforcerController()
        controller.update(title: title, largeTitleSize: largeTitleSize)
        return controller
    }

    func updateUIViewController(_ vc: EnforcerController, context: Context) {
        vc.update(title: title, largeTitleSize: largeTitleSize)
    }

    final class EnforcerController: UIViewController {

        ///`.navigationTitle` hands its string to UIKit, so no SwiftUI `.transition` can reach the
        ///label — UIKit swaps the text dead. This dissolves the swap instead, on the `.transition`
        ///role's clock; it is Core Animation, so it can't wear the role itself.
        private static let titleFadeDuration: CFTimeInterval = 0.25

        private var observations: [NSKeyValueObservation] = []
        private var ticker: Timer?
        private weak var ownerItem: UINavigationItem?
        private var barTitle: String?
        private var largeTitleSize: CGFloat = 32
        private var scoopAppearance = UINavigationBar.scoopAppearance()

        func update(title: String, largeTitleSize: CGFloat) {
            if barTitle != title {
                if barTitle != nil { crossfadeTitle() } //Nothing to dissolve from on the first title
                barTitle = title
            }
            guard self.largeTitleSize != largeTitleSize else { return }
            self.largeTitleSize = largeTitleSize
            scoopAppearance = UINavigationBar.scoopAppearance(largeTitleSize: largeTitleSize)
            enforce()
        }

        ///SwiftUI writes the new title into the bar in this same update pass, so the transition is
        ///already on the labels when Core Animation commits the change — either order works.
        ///
        ///Rooted at the CONTROLLER's view, never at the bar. iOS 26 moved the large title out of
        ///`UINavigationBar` — it now hangs off the hosting scroll view, so it can scroll and
        ///collapse with the content, and the bar keeps a same-frame but empty decoy. Rooted at the
        ///bar this reaches only the inline label, which sits at alpha 0 until the title collapses:
        ///the dissolve then runs perfectly on something invisible while the big title cuts.
        ///(Sim-verified 2026-08-10 — bar-rooted: 0 blended frames; nav-rooted: 16.)
        private func crossfadeTitle() {
            guard let nav = navigationController else { return }
            let fade = CATransition()
            fade.type = .fade
            fade.duration = Self.titleFadeDuration
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            for label in nav.view.largeTitleLabels {
                label.layer.add(fade, forKey: kCATransition) //CA files it under this key whatever we pass
            }
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

private extension UIView {

    ///The large title's label, and deliberately not the inline one. A CATransition re-anchors the
    ///outgoing bitmap to the layer's NEW bounds, so a CENTRED label redraws the old text at the
    ///incoming text's origin and it slides sideways before it fades — 40pt for "Meeting Bo" →
    ///"Meeting Bartholomew" (sim-measured 2026-08-10: 76.6pt of ink displacement in a single
    ///frame, absent with the fade off). The large title is immune: its origin is pinned at the
    ///leading margin whatever the name's width, which is also why the shared "Meeting " prefix
    ///registers exactly through the dissolve. Collapsed, the title keeps its old hard cut.
    ///
    ///Scoped at all because `crossfadeTitle` searches from the navigation controller's view, and
    ///an unfiltered walk reaches the screen below: any UIKit-backed label there would fade along
    ///with the title. (MapKit is not one — it draws its POI text into a Metal layer, not labels.)
    var largeTitleLabels: [UILabel] {
        descendantLabels.filter { label in
            sequence(first: label as UIView, next: \.superview).contains(where: \.hostsLargeTitle)
        }
    }

    var descendantLabels: [UILabel] {
        subviews.reduce(into: []) { found, view in
            if let label = view as? UILabel { found.append(label) }
            else { found.append(contentsOf: view.descendantLabels) }
        }
    }

    ///UIKit's large-title host is not a public type, so it can only be matched by name. A miss
    ///costs the dissolve and nothing else — the title still swaps, just hard.
    var hostsLargeTitle: Bool {
        String(describing: type(of: self)).contains("LargeTitle")
    }
}

extension View {
    //Apply inside a NavigationStack's root content (a sibling outside the stack
    //cannot reach the navigation controller).
    //`title:` is what the bar is showing — the enforcer needs it to dissolve one title into the next.
    func scoopNavigationBarFonts(title: String = "", largeTitleSize: CGFloat = 32) -> some View {
        background(NavigationBarFontEnforcer(title: title, largeTitleSize: largeTitleSize))
    }
}
