//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import AVFoundation
import SwiftUI
import os

enum ProfileResponse: Identifiable {
    case accepted
    case newTime
    case newInvite
    case decline
    var id: Self { self }
}

struct RespondedToProfileCover: View {
    let responseType: ProfileResponse
    var visible: Bool = true

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                Image("DancingCats")
                Text("Accepted")
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.successGreen)
            case .newTime:
                Image("DancingCats")
                Text("NEW TIME SENT")
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.accent)
            case .newInvite:
                Image("CoolGuys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            case .decline:
                DeclineTest()
            }
        }
        .colorBackground()
        .opacity(visible ? 1 : 0) //Outside colorBackground so the canvas fades too, not just the contents
        .animation(.transition, value: visible)
        .zIndex(10)
    }
}


struct TransparentVideoView: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.isOpaque = false
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

struct DeclineTest: View {

    private static let log = Logger(subsystem: "com.Arthur.ScoopTest", category: "DeclineTest")

    private static let crossBottomFraction: CGFloat = 419.0 / 852.0

    private static let bounceImpacts: [(time: Double, fill: Double)] = [
        (0.483, 0.47),
        (0.817, 0.76),
        (1.033, 0.85)
    ]

    @State private var player = DeclineTest.loadedPlayer()
    @State private var fill: Double = 0
    @State private var bounceObserver: Any?

    var body: some View {
        GeometryReader { geo in
            TransparentVideoView(player: player)
                .overlay(alignment: .top) {
                    Text("Declined")
                        .foregroundStyle(Color.textPrimary.mix(with: .declineRed, by: fill))
                        .font(.title(36))
                        .padding(.top, geo.size.height * Self.crossBottomFraction + Spacing.xxxl)
                }
        }
        .ignoresSafeArea()
        .colorBackground()
        .onAppear { replay() }
        .onDisappear { teardown() }
    }

    private func replay() {
        observeBounces()
        fill = 0
        player.seek(to: .zero)
        player.play()
    }

    private func observeBounces() {
        guard bounceObserver == nil else { return }
        let times = Self.bounceImpacts.map {
            NSValue(time: CMTime(seconds: $0.time, preferredTimescale: 600))
        }
        bounceObserver = player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
            let reached = player.currentTime().seconds + 0.02
            let target = Self.bounceImpacts.last { reached >= $0.time }?.fill ?? 0
            withAnimation(.toggle) { fill = target }
        }
    }

    private func teardown() {
        player.pause()
        if let bounceObserver { player.removeTimeObserver(bounceObserver) }
        bounceObserver = nil
    }

    private static func loadedPlayer() -> AVPlayer {
        guard let url = Bundle.main.url(forResource: "declined", withExtension: "mov") else {
            log.error("declined.mov missing from the bundle — check Copy Bundle Resources")
            return AVPlayer()
        }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }
}

#Preview {
    DeclineTest()
}
