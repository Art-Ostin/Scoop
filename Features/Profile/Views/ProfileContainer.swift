import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void, onDecline: () -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

struct ProfileView: View {
    
    @Environment(\.dismiss) var dismiss
    @State var vm: ProfileViewModel
    
    @State var ui = ProfileUIState()
    
    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?
    
    let mode: ProfileMode
    let profileImages: [UIImage]
    
    var isUserProfile: Bool {
        if case .ownProfile = mode { return true }
        return false
    }
    
    @State var isSheetTopAtTarget: Bool = false
    @State var isScrolling: Bool = false
    @State var stopTask: Task<Void, Never>? = nil
    
    
    @State var imageBottom: CGFloat = 0
    
    var showBackground: Bool {
        isSheetTopAtTarget && !isScrolling
    }
    
    @State var profileOffset: CGFloat = 0
    @State var detailsOffset: CGFloat = 0
    @State var profileOffsetEnabled: Bool = true
    
    @State var detailsOpen: Bool = false
    
    
    @State var enlargeBackground: Bool = false
    
    var displayProfile: UserProfile {
        if case .ownProfile(let draft) = mode { return draft }
        return vm.profile
    }
    
    init(
        vm: ProfileViewModel,
        profileImages: [UIImage],
        selectedProfile: Binding<UserProfile?>,
        dismissOffset: Binding<CGFloat?>,
        mode: ProfileMode
    ) {
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
        _dismissOffset = dismissOffset
        self.mode = mode
    }
    
    var body: some View {
        GeometryReader { geo in
            ZoomContainer {
                ZStack(alignment: .top) {
                    VStack(spacing: 24) {
//                        if !detailsOpen {
                            profileTitle(geo: geo)
                                .padding(.top, 36)
//                        }
                        ProfileImageView(ui: ui, vm: vm, importedImages: profileImages, imageBottom: $imageBottom)
//                            .padding(.top, detailsOpen ? -6 : 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    detailsCard
                }
                .coordinateSpace(name: "profileZStack")
                //Screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(profileBackground)
                
                //Views appearing above the screen
                .overlay(alignment: .bottomTrailing) { inviteButton }
                .overlay(alignment: .bottomLeading) { declineButton }
                .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                .overlay(alignment: .top) { if showBackground {sheetBackground}}
                .offset(y: profileOffset)
                .simultaneousGesture(profileDrag)
            }
        }
        .overlay { if ui.showPopup { invitePopup } }
        .offset(y: isUserProfile ? 0 : (dismissOffset ?? 0))
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .hideTabBar()
    }

    func dismissProfile(using geo: GeometryProxy) {
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        withAnimation(.snappy(duration: ui.dismissDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissDuration) {
            selectedProfile = nil
        }
    }
    
    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
            .shadow(color: profileOffset > 0 ? .black.opacity(0.25) : .clear, radius: 12, y: 6)
    }
    
    private var detailsCard: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: vm.profile, event: vm.event)
            .offset(y: detailsOffset)
            .offset(y: detailsOpen ? -236 : 0)
            .highPriorityGesture (
                detailsDrag
            )
            .padding(.top, imageBottom + 16)
    }
}


struct ImageBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/*
 //                .sheet(isPresented: .constant(true)) { detailsSheet }
 //        .toolbar(.hidden, for: .navigationBar)

 */

/*
 func handleSheetDragLogic(newY: CGFloat) {

     //Logic to deal with if its at top position
     let target: CGFloat = 370.21
     let topSheetAtTarget = abs(newY - target) <= 0.01
     isSheetTopAtTarget = topSheetAtTarget

     //Logic to ensure it is not scrolling
     isScrolling = true
     stopTask?.cancel()
     stopTask = Task {
         try? await Task.sleep(for: .milliseconds(100))
         guard !Task.isCancelled else { return }
         isScrolling = false
     }
 }
 
 
 
 private var detailsSheet: some View {
     ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, event: vm.event)
         .onGeometryChange(for: CGFloat.self) { proxy in
             proxy.frame(in: .global).minY
         } action: { _, newValue in
             handleSheetDragLogic(newY: newValue)
         }
         .presentationDetents([.fraction(0.26), .fraction(0.62)], selection: $ui.selectedDetent)
         .presentationBackgroundInteraction(.enabled)
         .interactiveDismissDisabled(true)
         .presentationCompactAdaptation(.sheet)
         .presentationBackground(Color.clear)
         .presentationDragIndicator(.hidden)
 }

*/
