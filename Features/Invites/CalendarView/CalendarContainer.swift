//
//  CalendarContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/09/2026.
//

import SwiftUI

struct CalendarContainer: View {
    
    @State var profileOpen: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventZoomHost = EventZoomHost()
    
    let vm: InvitesViewModel
    let onRespond: (EventProfile, ProfileResponse) -> Void //The Invites tab's own response flow
    
    var body: some View {
        ZoomNavigationStack(isDetailPresented: $profileOpen) {
            ScrollView {
                VStack {
                    heading
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.bottom, Spacing.clearance)
                .padding(.horizontal, 24)
                
                
                
                
            }
            .overlay { dismissButtonLayer }
            .eventZoomHost(eventZoomHost) //On the stack, not the ScrollView: the card and its backdrop also cover the large title
            .interactiveDismissDisabled()
            .task(id: vm.invites) { await loadInviteImages() }
            .scrollIndicators(.hidden)
            
        }
        
    }
}


extension CalendarContainer {
    
    
    private var heading: some View {
        VStack(spacing: 12) {
            Text("Calendar View")
                .font(.title(32, .bold))
            Text("See the days you've been invited to meet. Remember one invite can propose up to 3 different days.")
                .font(.body(13, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .kerning(0.312)
                .lineSpacing(6)
        }
        .padding(.top, 48)
        .ignoresSafeArea()
    }
    
    
    
    private var subHeading: some View {
        Text("See the days you've been invited to meet. Remember one invite can propose up to 3 different days.")
            .font(.body(14, .medium))
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .lineSpacing(6)
    }
    
    private var calendarView: some View {
        PendingCalendar(inviteDays: vm.invitedDays,
                        onOpen: { invite, day in vm.respondVM(for: invite).select(day: day) }) { invite in
            RespondToInviteContainer(vm: vm.respondVM(for: invite),
                                     images: vm.images(for: invite),
                                     respond: { respond(invite, $0) })
        }
        .padding(.horizontal, 16)
    }

    //The response cover draws at the app root, under this cover, so the calendar closes before the Invites tab responds
    private func respond(_ invite: EventProfile, _ response: ProfileResponse) {
        dismiss()
        onRespond(invite, response)
    }
    
    //Skips profiles already in the cache, so photos the invite cards loaded aren't fetched again
    private func loadInviteImages() async {
        for invite in vm.invites {
            await vm.ensureImagesLoaded(for: invite.profile)
        }
    }
}





//Dismiss Button logic
extension CalendarContainer {
        
    private var dismissButtonLayer: some View {
        GeometryReader { proxy in
            dismissButton
                .padding(.bottom, Spacing.xxl
                    + max(0, proxy.size.height + proxy.safeAreaInsets.top
                        + proxy.safeAreaInsets.bottom - UIScreen.main.bounds.height)) //Geometry: the library's canvas overgrowth, read from inside the safe-area frame
                .padding(.horizontal, Spacing.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
    
    private var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .xLarge, press: .grow) {
            dismiss()
        } label: {
            Image(systemName: "xmark") //"arrow.down.right.and.arrow.up.left"
                .foregroundStyle(.black)
                .font(.icon(18, .heavy))
        }
        .opacityPop(visible: chromeVisible)
        .allowsHitTesting(chromeVisible)
        .animation(.transition, value: chromeVisible)
    }

    private var chromeVisible: Bool { !eventZoomHost.chromeHidden }
}

/*
 //            NavigationStack {
 //                ScrollView {
 //                    VStack {
 //                        subHeading
 //                        calendarView
 //                            .padding(.top, 48)
 //                    }
 //                    .padding(.bottom, Spacing.clearance) //The last rows can scroll clear of the ✕
 //                }
 //                .scrollIndicators(.hidden)
 //                .navigationTitle("Calendar View")
 //                .background(Color.canvasSunken)
 //                .task(id: vm.invites) { await loadInviteImages() }
 //                .overlay { dismissButtonLayer }
 //            }
 //            .eventZoomHost(eventZoomHost) //On the stack, not the ScrollView: the card and its backdrop also cover the large title
 //            .interactiveDismissDisabled()
 //        }
 //        .ignoresSafeArea()
 */
