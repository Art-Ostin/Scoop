import SwiftUI

struct SendInviteContainer: View {
    
    static let screenMargin: CGFloat = 26
        
    @State var ui = TimeAndPlaceUIState()

    @Binding var draft: EventFieldsDraft
    @Binding var showConfirm: Bool
    
    let name: String
    let isInviteResponse: Bool
    let defaults: DefaultsManaging

    let onClearDraft: () -> Void
    let onSendInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) { //Each row has 32 vertical padding
            title
            
            InviteRowContainer(ui: ui, draft: $draft)
            
            sendButton
                .padding(.top, 4)
        }
        .overlay(alignment: .topTrailing) {optionsMenu}
        .modifier(InviteCardBackground(screenMargin: SendInviteContainer.screenMargin))

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
         }
         .offset(x: 4, y: -1)
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

struct InviteCardBackground: ViewModifier {
    @Environment(\.inviteCardTint) private var tint
    let screenMargin: CGFloat
    
    private var cardColor: Color { .tintedCanvas(tint) }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)
        
            .background {
                if #available(iOS 26.0, *) {
                    Color.clear
                        .glassEffect(.regular.tint(cardColor), in: .rect(cornerRadius: 36, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .fill(cardColor.opacity(0.3))   // ← the transparency dial
                        }
                } else {
                    RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color.appCanvas)
                }
            }
            .padding(.horizontal, screenMargin)
            .padding(.top, 60)
            .compositingGroup()
            .morphCardAnchor()
    }
}


struct SheetBackground: ViewModifier {
    var cornerRadius: CGFloat = 36
    let tint: Color
    
    private var cardColor: Color { .tintedCanvas(tint) }
    
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

extension Color {
    /// `tint` at `strength` composited over an opaque white base, flattened to one color.
    /// Respects the tint's own alpha — a `.clear` tint yields pure white. //0.0025
    static func tintedCanvas(_ tint: Color, strength: CGFloat = 0.0015) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(tint).getRed(&r, green: &g, blue: &b, alpha: &a)
        let e = strength * a
        return Color(red: (1 - e) + e * r,
                     green: (1 - e) + e * g,
                     blue: (1 - e) + e * b)
    }
}
