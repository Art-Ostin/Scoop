import SwiftUI
import MapKit

@MainActor
@Observable class TimeAndPlaceViewModel {
    
    let text: String
    var event: EventDraft
    var profile: ProfileModel?

    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    var showAlert: Bool = false
    var isMessageTap: Bool = false
    

    init(text: String, profile: ProfileModel? = nil) {
        self.text = text
        self.profile = profile
        self.event = EventDraft()
    }
}

struct SelectTimeAndPlace: View {
    
    @State var vm: TimeAndPlaceViewModel
    let onDismiss: () -> Void
    let onSubmit: @Sendable (EventDraft) async -> Void
    @State var showInfoScreen: Bool = false
    
    let rowHeight = CGFloat(60)
    
    init(profile: ProfileModel? = nil, text: String = "Confirm & Send", onDismiss: @escaping () -> Void, onSubmit: @escaping (EventDraft) async -> ()) {
        _vm = .init(initialValue: .init(text: text, profile: profile))
        self.onDismiss = onDismiss
        self.onSubmit = onSubmit
    }

    
    var body: some View {
        
        ZStack {
            CustomScreenCover {onDismiss()}
            sendInviteScreen
                .overlay(alignment: .topTrailing) {
                    TabInfoButton(showScreen: $showInfoScreen)
                        .scaleEffect(0.9)
                        .offset(x: -12, y: -48)
                }
            
            if vm.showTimePopup {
                SelectTimeView(vm: $vm)
                    .offset(y: 164)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .toolbar(.hidden, for: .tabBar)
        .tabBarHidden(true) // This is custom Tool bar hidden
        .sheet(isPresented: $vm.showMessageScreen) {InviteAddMessageView(vm: $vm)}
        .fullScreenCover(isPresented: $vm.showMapView) {MapView(vm2: $vm)}
        .animation(.easeInOut(duration: 0.2), value: vm.showTypePopup)
        .alert("Event Commitment", isPresented: $vm.showAlert) {
            Button("Cancel", role: .cancel) { }
            Button ("I Understand") {
                onDismiss()
                Task { await onSubmit(vm.event)}
            }
        } message : {
            Text("If you don't show, you'll be blocked from Scoop")
        }
        .tint(.blue)
        .onAppear {
            if vm.event.type == nil {
                vm.event.type = .drink
            }
        }
        .sheet(isPresented: $showInfoScreen) {
            Text("Info screen here")
        }
    }
    private var InviteIsValid: Bool {
        return (vm.event.type != nil || vm.event.message != nil) && vm.event.time != nil && vm.event.location != nil
    }
}

extension SelectTimeAndPlace {
    
    
    private var sendInviteScreen: some View {
        VStack(spacing: 24) {
            if vm.text == "Confirm & Send" {
                HStack(spacing: 16) {
                    CirclePhoto(image: vm.profile?.image ?? UIImage())
                    
                    
                    if let name = vm.profile?.profile.name {
                        Text("Meet \(name)")
                            .font(.custom("SFProRounded-Bold", size: 24))
                    }
                }
            } else {
                Text ("Your Time & Place")
                    .font(.title(24))
            }

            VStack(spacing: 12) {
                DropDownView(showOptions: $vm.showTypePopup) {
                    InviteTypeRow
                } dropDown: {
                    SelectTypeView(vm: vm, selectedType: vm.event.type)
                }

                Divider()
                InviteTimeRow
                    .frame(height: rowHeight)
                Divider()
                InvitePlaceRow
                    .frame(height: rowHeight)
            }
            .zIndex(vm.showTypePopup ? 1 : 0)
            ActionButton(isValid: InviteIsValid, text: vm.text) {
                if vm.text == "Confirm & Send" {
                    vm.showAlert.toggle()
                } else {
                    Task { await onSubmit(vm.event) }
                }
            }
        }
        .frame(alignment: .top)
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom], 32)
        .frame(width: 365)
        .background(Color.background)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        )
    }
    
    private var InviteTypeRow: some View {
        let event = vm.event
        return HStack {
            
            //If there is a response in place
            if let type = event.type, let message = event.message {
                let title = Text(verbatim: " \(type.description.emoji ?? "") \(type.description.label): ")
                    .font(.body(16, .bold))

                let body = Text(verbatim: " " + message)
                    .font(.body(12, .italic))
                    .foregroundStyle(vm.isMessageTap ? Color.grayPlaceholder : Color.grayText)
                
                let newText = Text("  edit")
                    .font(.body(12, .italic))
                    .foregroundStyle(vm.isMessageTap ? Color.grayPlaceholder : Color.accent)

                (title + body + newText)
                    .lineSpacing(6)
                    .contentShape(.rect)
                    .onTapGesture {
                        vm.isMessageTap = true
                        vm.showTypePopup = false
                        vm.showMessageScreen.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            vm.isMessageTap = false
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.1,
                                        pressing: { vm.isMessageTap = $0 },
                                        perform: {})
                }
            //Otherwise have this placeholder
            else if let type = event.type?.description.label, let emoji = event.type?.description.emoji {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(emoji) \(type)")
                        .font(.body(18))
                    Text("Add a Message")
                        .foregroundStyle(.accent).font(.body(14))
                        .onTapGesture {
                            vm.showTypePopup = false
                            vm.showMessageScreen.toggle()
                        }
                }
            } else {
                Text("Type").font(.body(20, .bold))
            }
            
            Spacer()
            
            DropDownButton(isExpanded: $vm.showTypePopup)
        }  
    }
    
    private var InviteTimeRow: some View {

        let time = vm.event.time
        
        return HStack {
            if time != nil { Text(formatTime(date: time)).font(.body(18))
            } else {Text("Time").font(.body(20, .bold))}
            
            Spacer()
            
            if vm.showTimePopup {
                Image(systemName: "chevron.down")
                    .onTapGesture {vm.showTimePopup.toggle() }
            } else {
                Image(time == nil ? "InviteTime" : "EditButton")
                    .onTapGesture {vm.showTimePopup.toggle() }
            }
        }
    }
    
    private var InvitePlaceRow: some View {
        HStack {
            if let location = vm.event.location {
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(18, .bold))
                    Text(location.address ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            } else {
                Text("Place")
                    .font(.body(20, .bold))
            }
            Spacer()
            Image(vm.event.location == nil ? "InvitePlace" : "EditButton")
                .onTapGesture { vm.showMapView.toggle() }
        }
    }
}

/*
 //            if event.type == nil && event.message == nil {
 //                Image("InviteType")
 //            }
 //
 //            Image((event.type == nil) && event.message == nil ? "InviteType" : "EditButton")
 //                .onTapGesture {vm.showTypePopup.toggle()}

 */

/*
 if vm.showTypePopup {
     SelectTypeView(vm: vm, selectedType: vm.event.type)
//                    .transition(.dropDownExpand)
         .zIndex(1)
         .offset(y: 48)
 }
 */

/*
 (
     Text(verbatim: " \(type.description.emoji ?? "") \(type.description.label): ")
         .font(.body(16, .bold))
     + Text(verbatim: " " + message)
         .font(.body(12, .italic))
         .foregroundStyle(Color.grayText)
 )
 .overlay(alignment: .bottomTrailing) {
     Image("EditButton")
         .resizable()
         .scaledToFit()
         .frame(width: 10, height: 10)
         .offset(x: -10, y: 12)
 }
 */
