import SwiftUI

struct SendInviteContainer: View {
    
    static let screenMargin: CGFloat = 18
        
    @State var ui = TimeAndPlaceUIState()

    @Binding var draft: EventFieldsDraft
    @Binding var showConfirm: Bool
    
    let name: String
    let isInviteResponse: Bool
    let defaults: DefaultsManaging

    let onClearDraft: () -> Void
    let onSendInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            title
            
            InviteRowContainer(ui: ui, draft: $draft)
            
            sendButton
        }
        .modifier(InviteCardBackground(screenMargin: SendInviteContainer.screenMargin))
        .overlay(alignment: .topTrailing) {optionsMenu}

        .task(id: ui.activePopup) { await ui.syncDelayedPopup() }
        
        .morphPopupOpen(ui.isPopupOpen())   // hide the morph's floating Hide button while a popup is open
        .hideTabBar(hideBar: isInviteResponse)
        
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
            .offset(y: 6)
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
                 .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.56))
                 .frame(width: 30, height: 30)
                 .background(Color(red: 0.92, green: 0.92, blue: 0.94), in: .circle)
         }
         .offset(x: 2, y: 6)
     }
    
    private var sendButton: some View {
        ScoopButton(style: .tinted(draft.isComplete ? .accent : .grayBackground, shadow: nil),
                    shape: Capsule(),
                    action: { print("hello") }) {
            Text("Send Invite")
                .font(.body(18, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .opacity(ui.isPopopOpenDelayed() ? 0.4 : 1)
        .padding(.top, 4)
        .allowsHitTesting(draft.isComplete)
    }
}

struct InviteCardBackground: ViewModifier {
    @Environment(\.inviteCardTint) private var tint
    let screenMargin: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 20)
        
            .background(Color.appCanvas, in: .rect(cornerRadius: 36, style: .continuous))
        
            .padding(.horizontal, screenMargin)
            .padding(.top, 60)
            .compositingGroup()
            .morphCardAnchor()
    }
}










struct SheetBackground: ViewModifier {
    var cornerRadius: CGFloat = 36
    let tint: Color
    
    func body(content: Content) -> some View {
        content
            .background {
                if #available(iOS 26.0, *) {
                    Color.clear
                        .glassEffect(
                            .regular.tint(tint.opacity(0.2)), in: .rect(cornerRadius: cornerRadius, style: .continuous)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tint.opacity(0.2))
                        .fill(Color.white)
                }
            }
    }
}
