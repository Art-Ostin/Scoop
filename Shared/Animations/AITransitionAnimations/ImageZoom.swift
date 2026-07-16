//
//  ImageZoom.swift
//  Scoop
//
//  Created by Art Ostin on 16/07/2026.
//

import SwiftUI
import UIKit

//The native Apple-Music zoom, wrapped so features never touch UIKit: a tapped
//image grows into a full screen and the screen shrinks back into it, with the
//system's interactive drag-down dismissal (finger-tracked shrink, spring-back
//on a short pull) for free. Built on UIKit's zoom transition because only it
//has `alignmentRectProvider` — the hook that glides the source image into the
//destination's hero rect (SwiftUI's `.navigationTransition(.zoom)` aligns to
//the full screen and double-exposes any inset hero).
//
//Wiring (all SwiftUI at the call sites):
//  1. Render the tappable image with a UIKit-backed source the transition can
//     hide/unhide during flight: `ScoopImage(image:, zoomSourceID: id)` — or
//     `ZoomSourceImage(id:image:cornerRadius:)` directly for custom spots.
//  2. Present any SwiftUI screen from it:
//     `ImageZoom.present(sourceID: id) { DetailScreen() }`
//  3. Mark the screen's hero image with `.zoomHero()` (optionally inset if the
//     visible image sits inside the measured container, like the profile pager).
//Dismissal: the drag is native; buttons call `ImageZoom.dismiss()`. The
//presented subtree reads `@Environment(\.zoomPresented)` to switch off any
//custom dismiss handling of its own (see ProfileContainer/ProfileGestures).
//
//One zoom presentation exists at a time (matching the profile overlay's rule);
//`present` while one is up is a no-op. The presented screen owns its own
//background — the hosting layer is clear, so nothing shifts color.

//MARK: - Public API

@MainActor
enum ImageZoom {

    static var isPresented: Bool { ZoomPresentation.current != nil }

    //Presents `content` full screen, zooming out of the source image registered
    //under `sourceID`. If that source isn't on screen, falls back to a plain
    //fullscreen presentation (no flight) rather than failing.
    static func present(sourceID: String, @ViewBuilder content: () -> some View) {
        guard ZoomPresentation.current == nil,
              let top = UIApplication.topmostViewController(),
              let window = top.viewIfLoaded?.window
        else { return }

        let presentation = ZoomPresentation()
        let host = ZoomHostingController(
            rootView: AnyView(content().environment(\.zoomPresented, true)),
            presentation: presentation
        )

        let options = UIViewController.Transition.ZoomOptions()
        options.alignmentRectProvider = { context in
            guard let host = context.zoomedViewController as? ZoomHostingController else { return nil }
            return host.heroAlignmentRect(fallbackSize: context.sourceView.window?.bounds.size)
        }
        host.preferredTransition = .zoom(options: options) { _ in
            ZoomSourceRegistry.view(for: sourceID)
        }
        host.modalPresentationStyle = .fullScreen

        //Pre-warm: one hidden in-window layout pass, so `.zoomHero()` reports
        //the exact final rect (real safe areas included) before the transition
        //asks for it. Forcing that first layout inside the alignment callback,
        //mid-transition, is both racy and safe-area-blind.
        host.view.frame = window.bounds
        host.view.isHidden = true
        window.addSubview(host.view)
        host.view.layoutIfNeeded()
        host.view.removeFromSuperview()
        host.view.isHidden = false

        ZoomPresentation.current = presentation
        //Next runloop turn: never start the transition from inside the tap's
        //gesture callout, and let the pre-warmed layout commit a frame first.
        DispatchQueue.main.async {
            top.present(host, animated: true)
        }
    }

    //Zooms back into the source (animated) or tears down instantly — e.g. under
    //a response cover. Safe to call when nothing is presented.
    static func dismiss(animated: Bool = true) {
        ZoomPresentation.current?.host?.dismiss(animated: animated)
    }
}

extension View {

    //Marks the destination's hero image: the rect the source glides into. Apply
    //to the view whose on-screen frame IS the visible image; pass `insetX` when
    //the measured container is wider than the image it shows (the profile pager
    //pages sit 6pt inside their full-width container).
    func zoomHero(insetX: CGFloat = 0) -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
            ZoomPresentation.current?.heroRect = rect.insetBy(dx: insetX, dy: 0)
        }
    }
}

extension EnvironmentValues {
    //True inside a zoom-presented subtree: the native drag owns dismissal there.
    @Entry var zoomPresented: Bool = false
}

//MARK: - Source image (UIKit-backed)

//An aspect-fill image the transition can use as its source: the system hides
//the real UIImageView while the zoom is in flight and unhides it on landing,
//which is what guarantees exactly one copy of the image on screen. A plain
//SwiftUI Image can't be handed to UIKit, so zoomable spots render this instead
//(visually identical: fill, clipped, continuous corners).
struct ZoomSourceImage: UIViewRepresentable {

    //Injected
    let id: String
    let image: UIImage
    var cornerRadius: CGFloat = 0

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        //SwiftUI dictates the size; never let the image's intrinsic size win.
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.image = image
        view.layer.cornerRadius = cornerRadius
        if context.coordinator.registeredID != id {
            if let old = context.coordinator.registeredID {
                ZoomSourceRegistry.unregister(id: old, view: view)
            }
            ZoomSourceRegistry.register(view, id: id)
            context.coordinator.registeredID = id
        }
    }

    final class Coordinator {
        var registeredID: String?
    }
}

//MARK: - UIKit internals

//id → source view lookup at present-time. Weak by design: a scrolled-away or
//torn-down source simply stops resolving and `present` falls back to a flat
//presentation.
@MainActor
private enum ZoomSourceRegistry {

    private final class WeakView {
        weak var view: UIImageView?
        init(_ view: UIImageView) { self.view = view }
    }

    private static var sources: [String: WeakView] = [:]

    static func register(_ view: UIImageView, id: String) {
        sources[id] = WeakView(view)
    }

    static func unregister(id: String, view: UIImageView) {
        if sources[id]?.view === view { sources[id] = nil }
    }

    static func view(for id: String) -> UIImageView? {
        sources[id]?.view
    }
}

//The live presentation: holds the hero rect that `.zoomHero()` reports (in
//global/window coordinates) and the host so `dismiss` can find it. `current`
//is weak — the host owns the strong reference, so state can never outlive the
//presentation it describes.
@MainActor
private final class ZoomPresentation {

    static weak var current: ZoomPresentation?

    weak var host: UIViewController?
    var heroRect: CGRect = .null
}

//Hosts the presented SwiftUI screen and answers the transition's questions.
private final class ZoomHostingController: UIHostingController<AnyView> {

    private let presentation: ZoomPresentation

    init(rootView: AnyView, presentation: ZoomPresentation) {
        self.presentation = presentation
        super.init(rootView: rootView)
        presentation.host = self
    }

    @available(*, unavailable)
    required dynamic init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        //The screen paints its own background; a clear host can't shift colors.
        view.backgroundColor = .clear
    }

    //The rect (in this view's coordinates) the source glides into. The provider
    //can fire before the first layout pass, so size the view and lay out first —
    //SwiftUI runs its pass inside layoutIfNeeded, which fires `.zoomHero()`.
    func heroAlignmentRect(fallbackSize: CGSize?) -> CGRect? {
        if view.bounds.isEmpty, let size = fallbackSize {
            view.frame = CGRect(origin: .zero, size: size)
        }
        view.layoutIfNeeded()
        let rect = presentation.heroRect
        guard !rect.isNull, rect.width > 1 else { return nil } //No hero marked: zoom to full screen.
        //Reported in global (window) coordinates; pre-presentation the view has
        //no window yet, but it is framed at the window's origin so they match.
        return view.window.map { _ in view.convert(rect, from: nil) } ?? rect
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed, ZoomPresentation.current === presentation {
            ZoomPresentation.current = nil
        }
    }
}

private extension UIApplication {
    //Where to present from: the key window's topmost presented controller.
    static func topmostViewController() -> UIViewController? {
        let scenes = shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
