import SwiftUI

struct SelectTimeAndPlace: View {

    static let screenMargin: CGFloat = 8
    static let contentPadding: CGFloat = 24

    //Injected
    @Binding var draft: EventFieldsDraft
    @Binding var showConfirmScreen: Bool
    @Binding var showMessageScreen: Bool
    let name: String
    let isInviteResponse: Bool
    let defaults: DefaultsManaging
    var onPopupOpenChange: (Bool) -> Void = { _ in }

    //Local view state
    @State private var ui = TimeAndPlaceUIState()

    var body: some View {
        VStack(spacing: 0) {
            InviteRowContainer(ui: ui, draft: $draft, showMessageScreen: $showMessageScreen) 
            sendButton
        }
        .task(id: ui.activePopup) { await ui.syncDelayedPopup() }
        .onChange(of: ui.activePopup, initial: true) { _, popup in
            onPopupOpenChange(popup != nil)
        }
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .padding(.horizontal, Self.contentPadding)
    }
}

//Key Components
extension SelectTimeAndPlace {
    
    private var sendButton: some View {
        let label = Text("Invite \(name)")
            .font(.body(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)

        let color = Color(red: 0.55, green: 0, blue: 0.25)

        return Group {
            if draft.isComplete {
                ScoopButton(style: .tinted( ui.isPopupOpenDelayed() ? .fillGray : color, shadow: nil), shape: Capsule(), action: {showConfirmScreen = true}) {
                    label
                }
            } else {
                label
                    .background(Color.fillGray, in: Capsule())
            }
        }
        .animation(.smooth, value: ui.isPopupOpenDelayed())
        .opacity(ui.isPopupOpenDelayed() ? 0.4 : 1)
        .allowsHitTesting(draft.isComplete)
        .padding(.top, Spacing.xxs)
    }
}
