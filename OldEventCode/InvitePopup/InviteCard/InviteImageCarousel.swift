//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.


/*
 import SwiftUI
 struct InviteImageCarousel: View {

     //Injected Properties
     let screen: InviteScreen
     let name: String
     let images: [UIImage]

     //Only offer 'Clear Invite' in the options menu once the draft has something to clear
     let inviteHasChanges: Bool

     //A menu owns the card below: the top row and the page indicator pop away for it
     let isPopupOpen: Bool

     //The back button leaves the confirm screen & Options Menu opens Info Screen
     @Binding var showConfirmScreen: Bool?
     @Binding var showInfoScreen: Bool

     //Respond screens only — the toggle swaps between their invite and one of your own
     var responseType: Binding<ResponseType>? = nil

     //The invite flight frames this carousel itself instead of letting it self-size
     var fillsFrame: Bool = false

     //The flight owns the page position when it needs the cover dissolve on close
     var scrollProgress: Binding<Double>? = nil

     //…and snaps the pager home under that cover before the collapse resizes it
     var pagerPosition: Binding<ScrollPosition>? = nil

     //Flipped as the open flight launches, so the chrome pops in over the flying image and grows with it
     var chromeVisible: Bool = true

     //The flight defers the heavy pager until the card lands — its static covers stand in
     //beneath this view meanwhile, so only the chrome overlays render during the flight
     var showsPager: Bool = true

     //The landing crossfade: the pager fades in over the flight's held sharp cover, so the
     //pages' bottom blur arrives smoothly instead of snapping in with the mount
     var pagerFade: Double = 1

     //…and stays inert until that cover drops — paging a semi-transparent pager over a held
     //cover double-exposes two photos
     var pagerInteractive: Bool = true

     //Continuous multiplier over ALL image chrome (title, halo, options, dots, back button):
     //the dismiss drag dissolves the dressing proportionally as the card travels, restored by
     //the snap-back spring on a cancelled release
     var chromeOpacity: Double = 1

     //The invite flight flies the name as its own hero text: the title's name renders as a
     //layout ghost (measured, invisible) while true, and reports its slot through the binding.
     //The slot is published as FLIGHT-INVARIANT offsets (x: leading inset to the name, y:
     //bottom inset, size: the 22pt text) — identical at any carousel size, so a measurement
     //taken at the collapsed model size can never stomp an in-flight lerp target
     //([[measured-frames-dont-track-animation]]: position measurements hold model values only).
     var nameFlying: Bool = false
     var titleNameSlot: Binding<CGRect>? = nil

     //Shared with the flight's slot maths — literals here and there must be the same numbers
     static let titleInset: CGFloat = 20 //Geometry: as the back button — one shared inset from the artwork edge
     static let titleWordGap: CGFloat = 6 //Geometry: tighter than a word space, so the pair reads as one line of display type
     static let titleBottomInset: CGFloat = Spacing.sm
     static let answeringTitleScale: CGFloat = 0.85 //The accept title's shrink — shared with the quick-invite flight's hero maths

     //Both offered by the options menu
     let declineProfile: () -> Void
     let clearInvite: () -> Void

     //Local view state
     @State private var internalScrollProgress: Double = 0

     //Measured so the blur halo can lift just behind the overlay text
     @State private var nameFrame: CGRect = .zero
     @State private var inviteFrame: CGRect = .zero

     //LAYOUT sizes for the name slot — the getRect frames above pass through chromeItem's
     //opacityPop, so while the title chrome is hidden they carry its 0.4 shrunk scale;
     //GeometryProxy.size is transform-independent and truly flight-invariant
     @State private var inviteWordWidth: CGFloat = 0
     @State private var titleNameSize: CGSize = .zero

     private var chrome: InviteScreen.Overlays { screen.chrome }

     private var progressBinding: Binding<Double> { scrollProgress ?? $internalScrollProgress }
     private var progress: Double { progressBinding.wrappedValue }

     //The invite's own page shape — the carousel is shared, so this screen names its ratio
     private var pagerRatio: CGFloat {
         (chrome.compactImage ? AspectRatio.confirmInviteImage : .invitedImage).ratio
     }

     var body: some View {
         ZStack {
             if showsPager {
                 InviteCarousel(images: images, ratio: pagerRatio, blursBottom: screen.blursBottom, fillsFrame: fillsFrame, position: pagerPosition, scrollProgress: progressBinding)
                     .opacity(pagerFade)
                     .allowsHitTesting(pagerInteractive)
                     .scrollDisabled(!pagerInteractive) //Hit-testing alone doesn't stop a pan the scroll view is already tracking — the dismiss drag must truly own the gesture
             } else {
                 Color.clear //The flight frames this carousel before the pager mounts; without a filled base the corner-pinned overlays collapse to a zero-size centre
             }
         }
             .overlay { backgroundBlur }
             .overlay(alignment: .topLeading) { backButton }
             .overlay(alignment: .topTrailing) { topRow }
             .overlay(alignment: .bottomLeading) { inviteTitle }
             .overlay(alignment: .bottomTrailing) { pageIndicator }
             .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
     }
 }

 //The overlays
 extension InviteImageCarousel {

     //Top Right to Bottom Left, the Four different visible Screens
     private var backButton: some View {
         ScoopButton(style: .clearGlass, shape: Circle(), action: { showConfirmScreen = false }) {
             Image(systemName: "chevron.left")
                 .font(.body(17))
                 .fontWeight(.heavy)
                 .foregroundStyle(Color.black)
                 .frame(width: 38, height: 38)
         }
         .chromeItem(visible: chrome.backButton && chromeVisible, fade: chromeOpacity)
         .padding(.horizontal, 20) //Geometry: as the title — one shared inset from the artwork edge
         .padding(.top, Spacing.sm)
     }

     private var topRow: some View {
         HStack(alignment: .top, spacing: Spacing.md) {
             if chrome.toggle, let responseType {
                 ChangeButton(responseType: responseType, showConfirmScreen: $showConfirmScreen)
             }

             if chrome.options {
                 OptionsMenu(
                     hasChanges: inviteHasChanges,
                     onInfo: { showInfoScreen = true },
                     onClear: clearInvite,
                     onDecline: declineProfile
                 )
             }
         }
         .padding(Spacing.sm)
         .chromeItem(visible: !isPopupOpen && chromeVisible, fade: chromeOpacity)
         .animation(.transition, value: screen) //Its two buttons mount and unmount as the screen changes
     }

     @ViewBuilder
     private var inviteTitle: some View {
         let answering = screen == .accept

         Group {
             if answering {
                 //One Text carrying the CARD's exact copy (InviteCardTitle) — the quick-invite
                 //flight morphs the card title into this line, so the words must be identical
                 Text(InviteCardTitle.text(name: name))
                     .getRect($nameFrame, coordSpace: "InviteImageCarousel")
                     .opacity(nameFlying ? 0 : 1) //Layout ghost while the flight's hero text owns the line
                     //LAYOUT size, scaled by the answering shrink ourselves: GeometryProxy.size
                     //is transform-independent, so the published slot is flight-invariant
                     .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                         titleNameSize = size
                         publishAcceptNameSlot()
                     }
             } else {
                 HStack(spacing: Self.titleWordGap) {
                     Text("Invite")
                         .getRect($nameFrame, coordSpace: "InviteImageCarousel")
                         .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { inviteWordWidth = $0; publishNameSlot() }

                     Text(name)
                         .getRect($inviteFrame, coordSpace: "InviteImageCarousel")
                         .opacity(nameFlying ? 0 : 1) //Layout ghost while the flight's hero text owns the word
                         .onGeometryChange(for: CGSize.self) { $0.size } action: { titleNameSize = $0; publishNameSlot() }
                 }
             }
         }
         .font(.title(22))
         .scaleEffect(answering ? Self.answeringTitleScale : 1, anchor: .bottomLeading) //Their name runs longer than "Invite"
         .foregroundStyle(Color.white)
         .padding(.horizontal, Self.titleInset)
         .padding(.bottom, Self.titleBottomInset)
         .chromeItem(visible: chrome.title && chromeVisible, fade: chromeOpacity)
     }

     static func titleFrames(name: String, in size: CGSize) -> [CGRect] {
         let font = UIFont.title(22)
         let inviteSize = ("Invite" as NSString).size(withAttributes: [.font: font])
         let nameSize = (name as NSString).size(withAttributes: [.font: font])
         let top = size.height - titleBottomInset - inviteSize.height
         return [
             CGRect(x: titleInset, y: top, width: inviteSize.width, height: inviteSize.height),
             CGRect(x: titleInset + inviteSize.width + titleWordGap, y: top,
                    width: nameSize.width, height: nameSize.height),
         ]
     }

     //The name's slot from LAYOUT sizes + the title's own constants — never from measured
     private func publishNameSlot() {
         guard let titleNameSlot, titleNameSize.width > 0, inviteWordWidth > 0 else { return }
         titleNameSlot.wrappedValue = CGRect(
             x: Self.titleInset + inviteWordWidth + Self.titleWordGap,
             y: Self.titleBottomInset,
             width: titleNameSize.width, height: titleNameSize.height
         )
     }

     //The accept title's slot: one line at the artwork's corner, worn at the answering scale
     //(anchored bottomLeading, so inset and bottom hold and only the size shrinks)
     private func publishAcceptNameSlot() {
         guard let titleNameSlot, titleNameSize.width > 0 else { return }
         let scale = Self.answeringTitleScale
         titleNameSlot.wrappedValue = CGRect(
             x: Self.titleInset,
             y: Self.titleBottomInset,
             width: titleNameSize.width * scale, height: titleNameSize.height * scale
         )
     }

     private var pageIndicator: some View {
         ImagePageIndicator(count: images.count, progress: progress, activeColor: .white)
             .scaleEffect(0.7, anchor: .trailing)
             .padding(.horizontal, Spacing.lg)
             .padding(.bottom, Spacing.xs)
             .chromeItem(visible: chrome.pageIndicator && !isPopupOpen && chromeVisible, fade: chromeOpacity)
     }

     //Apply background blur where necessary under the content.
     //Gated STRUCTURALLY on the pager: the halo is a live 40pt blur over a card-sized photo
     //copy, and it must not be resident on the flight's animating rect even at opacity 0. It
     //mounts with the pager at land() — at rest, never mid-flight — and arrives by riding
     //pagerFade, which is already animating in land()'s transaction (a value-scoped .animation
     //on a freshly inserted subtree has no prior state and would pop instead).
     //A gallery can legitimately arrive empty — ImageLoader drops every photo it fails to fetch —
     //and the clamp below inverts on one: `count - 1` is -1, so the ceiling beats the floor and
     //`page` lands at -1. There is no halo to draw without artwork anyway.
     @ViewBuilder
     private var backgroundBlur: some View {
         if showsPager, !images.isEmpty {
             let clamped = min(max(progress, 0), Double(images.count - 1))
             let page = Int(clamped)
             let next = min(page + 1, images.count - 1)
             let fraction = clamped - Double(page)
             let visible = chrome.title && chromeVisible
             //The accept title is ONE Text (only nameFrame is live) — a stale inviteFrame from
             //a new-invite visit would leave a phantom halo where that layout's name word sat
             let frames = screen == .accept ? [nameFrame] : [nameFrame, inviteFrame]

             ZStack {
                 BackgroundBlur(image: images[page], frames: frames)
                     .opacity(1 - fraction)
                 if next != page && fraction > 0 {
                     BackgroundBlur(image: images[next], frames: frames)
                         .opacity(fraction)
                 }
             }
             //A full-bleed wash has no corner to pop from — scaling it drags both halos toward
             //the middle. BackgroundBlur already refuses hits, so a plain fade is all it needs.
             //chromeOpacity rides along: a halo without its fading title is a stray smudge.
             .opacity((visible ? pagerFade : 0) * chromeOpacity)
             .animation(.transition, value: visible)
         }
     }
 }

 //All Overlay Items are shown and hidden in exactly the same way. So convenience modifier created here
 private extension View {
     //anchor: the corner the overlay is pinned to, so it pops from there rather than drifting to its own centre.
     //fade: the drag's continuous dissolve, multiplied over the pop (unanimated — it tracks the finger)
     func chromeItem(visible: Bool, fade: Double = 1, anchor: UnitPoint = .center) -> some View {
         opacityPop(visible: visible, anchor: anchor)
             .opacity(fade)
             .allowsHitTesting(visible)
             .animation(.transition, value: visible)
     }
 }
 */

