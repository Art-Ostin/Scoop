import SwiftUI
import MapKit



struct SendInvitePopup: View {
    
    
    @State var vm: InviteViewModel
    @State var showAlert: Bool = false
    @FocusState var isFocused: Bool
    
    let onDismiss: () -> Void

    init(vm: InviteViewModel, onDismiss: @escaping () -> Void) {
        _vm = State(initialValue: vm)
        self.onDismiss = onDismiss
    }
        
    var body: some View {
        ZStack {
            sendInviteScreen
            
            if vm.showTypePopup {
                SelectTypeView(vm: $vm)
                    .offset(y: 96)
            }
            if vm.showTimePopup {
                SelectTimeView(vm: $vm)
                    .offset(y: 164)
            }
        }
        .sheet(isPresented: $vm.showMessageScreen) {
            InviteAddMessageView(vm: $vm)
        }
        .fullScreenCover(isPresented: $vm.showMapView) {
            MapView(vm2: $vm)
        }
        .alert("Event Commitment", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button ("I Understand") {
                Task {
                    try? await vm.sendInvite()
                    onDismiss()
                }
            }
        } message : {
            Text("If you don't show, you'll be blocked from Scoop")
        }.tint(.blue)
    }
    private var InviteIsValid: Bool {
        return (vm.event.type != nil || vm.event.message != nil) && vm.event.time != nil && vm.event.location != nil
    }
}

extension SendInvitePopup {

    private var sendInviteScreen: some View {
        VStack(spacing: 32) {
            HStack {
                CirclePhoto(image: vm.profileModel.image ?? UIImage())
                
                Text("Meet \(vm.profileModel.profile.name ?? "")")
                    .font(.title(24))
            }
            InviteTypeRow
            Divider()
            InviteTimeRow
            Divider()
            InvitePlaceRow
            ActionButton(isValid: InviteIsValid, text: "Confirm & Send") {
                showAlert.toggle()
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
            
            if let type = event.type, let message = event.message {
                (
                    Text((event.type == "Write a message") ? "" : "\(type): ")
                        .font(.body(16, .bold))
                    + Text(" " + message)
                        .font(.body(12, .italic))
                        .foregroundStyle(Color.grayText)
                )
            } else if let type = event.type {
                VStack(alignment: .leading, spacing: 6) {
                    Text(type).font(.body(18))
                    Text("Add a Message").foregroundStyle(.accent).font(.body(14))
                        .onTapGesture {
                            vm.showTypePopup = false
                            vm.showMessageScreen.toggle()
                        }
                }
            } else {
                Text("Type").font(.body(20, .bold))
            }
            
            Spacer()
            
            Image((event.type == nil) && event.message == nil ? "InviteType" : "EditButton")
                .onTapGesture {vm.showTypePopup.toggle()}
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
