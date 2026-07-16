import SwiftUI

struct SelectTimeAndPlace: View {

    static let screenMargin: CGFloat = 8
    static let contentPadding: CGFloat = 24

    //Injected — `ui` is owned by InviteSectionContainer so the persistent pill can read its popup state.
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var draft: EventFieldsDraft
    @Binding var showMessageScreen: Bool
    let defaults: DefaultsManaging
    var onPopupOpenChange: (Bool) -> Void = { _ in }

    var body: some View {
        InviteRowContainer(ui: ui, draft: $draft, showMessageScreen: $showMessageScreen)
            .task(id: ui.activePopup) { await ui.syncDelayedPopup() }
            .task(id: ui.activePopup) { await ui.syncDelayedTimePopup() }
            .onChange(of: ui.activePopup, initial: true) { _, popup in
                onPopupOpenChange(popup != nil)
            }
            .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: defaults, eventLocation: $draft.place) }
            .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
            .padding(.horizontal, Self.contentPadding)
    }
}
