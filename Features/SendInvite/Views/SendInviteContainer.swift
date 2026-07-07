import SwiftUI

struct SendInviteContainer: View {
    @Environment(\.inviteCardTint) private var tint

    static let screenMargin: CGFloat = 8
        
    @State var ui = TimeAndPlaceUIState()

    @Binding var draft: EventFieldsDraft
    
    let name: String
    let isInviteResponse: Bool
    let defaults: DefaultsManaging

    let onClearDraft: () -> Void
    let hideInvite: () -> Void
    let onSendInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            title
            
            InviteRowContainer(ui: ui, draft: $draft)
            
            sendButton
        }
        .overlay(alignment: .topTrailing) {optionsMenu}
        .task(id: ui.activePopup) { await ui.syncDelayedPopup() }
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {
            NavigationStack {
                AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
            }
        }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

//Key Components
extension SendInviteContainer {
    private var title: some View {
        Text(isInviteResponse ? "Send New Invite" : "Meet \(name)")
            .font(.title(26))
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(ui.isPopupOpen(.time) ? 0.1 : 1)
            .animation(.snappy(duration: 0.2), value: ui.isPopupOpen(.time))
    }
    
    private var optionsMenu: some View {
         Menu {
             if draft.hasChanges {
                 Button("Clear Draft", systemImage: "trash", role: .destructive) {
                     // One animation owns the whole clear so every row cross-fades together.
                     withAnimation(.easeInOut(duration: 0.2)) { onClearDraft() }
                 }
             }
             Button("How Invites Work", systemImage: "info.circle") {
                 ui.showInfoScreen = true
             }
         } label: {
             Image(systemName: "ellipsis")
                 .font(.body(16, .bold))
                 .foregroundStyle(Color.textSecondary)
                 .frame(width: 30, height: 30)
                 .background(Color.fillGray, in: .circle)
                 .scaleEffect(0.9, anchor: .top)
         }
         .offset(x: 5, y: -2)
     }
    
    private var sendButton: some View {
        ScoopButton(style: .tinted(draft.isComplete ? .accent : .accent, shadow: nil),
                    shape: Capsule(),
                    action: { print("hello") }) {
            Text("Send Invite")
                .font(.body(18, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .opacity(ui.isPopupOpenDelayed() ? 0.4 : 1)
        .padding(.top, 4)
        .allowsHitTesting(draft.isComplete)
    }
}
