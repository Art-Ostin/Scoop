//
//  RootView.swift
//  Scoop
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI
import MapKit

enum AppState {
    case booting, login, createAccount, app, frozen
}

struct RootView : View {

    //Injected
    @Environment(AppDependencies.self) private var dep

    //Local view state
    @State private var showSignUpSheet = false

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiHarnessWindDismiss") {
            WindDismissHarness() //Capture rig for the declined-card wind dismissal
        } else if ProcessInfo.processInfo.arguments.contains("-uiHarnessChatSend") {
            ChatSendHarness() //The real chat on an in-memory repository, for measuring the send flight
        } else {
            appBody
        }
        #else
        appBody
        #endif
    }

    private var appBody: some View {
        Group {
            switch dep.session.appState {
            case .booting: BootingScreen()
            case .login: SignUpView(showSignUpSheet: $showSignUpSheet)
            case .createAccount: OnboardingHomeView()
            case .app: AppContainer(dependencies: dep)
            case .frozen: FrozenContainer()
            }
        }
        .sheet(isPresented: $showSignUpSheet) {
            EnterEmailView(vm: VerifyEmailViewModel(session: dep.session, defaultsManager: dep.defaultsManager, authService: dep.authService, userRepo: dep.userRepo))
                .presentationBackground(Color(red: 1, green: 1, blue: 0.98))
        }
        .onChange(of: dep.session.appState) { _, newState in
            if newState != .login { showSignUpSheet = false }
        }
        .keyboardPrewarmed() //The session's first keyboard build happens invisibly at launch
    }
}

#if DEBUG
//MARK: - Chat send harness

//The real ChatContainer, ViewModel and bar on a stub event and an in-memory ChatRepository whose echoes
//arrive on Firestore's clock (local `.added` within milliseconds, the server stamp ~0.9 s later), so the
//send flight can be run and logged on a simulator that is signed out. Launch with `-uiHarnessChatSend`.
private struct ChatSendHarness: View {

    @Environment(AppDependencies.self) private var dep
    @State private var stage: (me: UserProfile, profile: EventProfile, repo: HarnessChatRepo)?
    @State private var failure: String?

    var body: some View {
        if let stage {
            NavigationStack {
                ChatContainer(defaults: dep.defaultsManager, session: dep.session, chatRepo: stage.repo,
                              imageLoader: dep.imageLoader, eventProfile: stage.profile, isEvent: false)
            }
        } else {
            Color.appCanvas
                .ignoresSafeArea()
                .overlay { if let failure { Text(failure).font(.body(14, .medium)).padding() } }
                .onAppear(perform: build)
        }
    }

    private func build() {
        guard let me = Self.profile(id: "harness-me", email: "arthur.harness@mail.mcgill.ca"),
              let other = Self.profile(id: "harness-other", email: "sophie.harness@mail.mcgill.ca") else {
            failure = "Harness: the stub profiles did not decode"
            return
        }
        var draft = EventFieldsDraft()
        draft.time = ProposedTimes(items: [ProposedTime(date: Date().addingTimeInterval(3 * 86_400))])
        draft.place = EventLocation(mapItem: .mcGill)
        guard var event = Event(draft: draft, initiatorId: me.id, recipientId: other.id) else {
            failure = "Harness: the stub event did not build"
            return
        }
        event._id = "harness-event"
        var userEvent = UserEvent(otherProfile: other, role: .sent, event: event)
        userEvent._id = event._id
        userEvent.status = .accepted
        userEvent.canText = true
        userEvent.acceptedTime = draft.time.dates.first?.date
        let profile = EventProfile(event: userEvent, profile: other, image: UIImage(named: "Demo1"))
        dep.session.setAuthStream(nil) //Launch's auth stream would start the real user's session over the stub on a signed-in simulator
        dep.session.setSessionUser(me)
        stage = (me, profile, HarnessChatRepo(me: me.id, other: other.id))
    }

    //A profile through its own draft decoder: every non-optional field of the draft, nothing else
    private static func profile(id: String, email: String) -> UserProfile? {
        let json = """
        {"id":"\(id)","email":"\(email)","sex":"Female","attractedTo":"Male","year":"U2","height":"170",
         "interests":[],"degree":"Arts","hometown":"Montreal","nationality":["Canada"],"lookingFor":"Friends",
         "imagePath":[],"imagePathURL":[],"drinking":"Sometimes","smoking":"Never","marijuana":"Never","drugs":"Never",
         "prompt1":{"prompt":"","response":""},"prompt2":{"prompt":"","response":""}}
        """
        guard let data = json.data(using: .utf8), let draft = try? JSONDecoder().decode(DraftProfile.self, from: data) else { return nil }
        return UserProfile(draft: draft)
    }
}

//In-memory chat: a seeded thread, and sends that echo back the way Firestore's listener does
private final class HarnessChatRepo: ChatRepository {

    private let me: String
    private let other: String
    private var continuation: AsyncThrowingStream<FSCollectionEvent<ChatMessage>, Error>.Continuation?

    init(me: String, other: String) {
        self.me = me
        self.other = other
    }

    //Oldest first, as the chat shows them
    private var seed: [ChatMessage] {
        func message(_ id: String, from: String, to: String, _ content: String, minutesAgo: Double) -> ChatMessage {
            var m = ChatMessage(authorId: from, recipientId: to, content: content)
            m.id = id
            m.dateCreated = Date().addingTimeInterval(-minutesAgo * 60)
            return m
        }
        //Enough to overflow the screen, so the list is bottom-anchored and a send shifts it as a real thread does
        var thread: [ChatMessage] = []
        let lines = [
            "brother alyosha and now i see it does not weep beyond three days", "Hello", "How was your week?",
            "Long. Two midterms back to back and a lab report due the same day", "Oof. Coffee after the last one?",
            "Yes please. Thursday?", "Thursday works. Where?", "The place on Milton with the good pastries",
            "Perfect, 3pm?", "3 is good", "See you there", "Bringing the notes from the seminar too",
            "Great, I missed that one", "Ok", "Hello",
        ]
        //`-uiHarnessChatNewDay` ends the thread yesterday, so a send opens a new day and grows its divider in
        let dayShift: Double = ProcessInfo.processInfo.arguments.contains("-uiHarnessChatNewDay") ? 24 * 60 : 0
        for (i, line) in lines.enumerated() {
            let mine = i % 2 == 1
            thread.append(message("seed-\(i)", from: mine ? me : other, to: mine ? other : me, line, minutesAgo: Double(60 - i * 3) + dayShift))
        }
        return thread
    }

    func newMessageId(eventId: String) -> String { "harness-\(UUID().uuidString)" }

    func sendMessage(id: String, text: String, eventId: String, userId: String, recipientId: String) async throws {
        var echo = ChatMessage(authorId: userId, recipientId: recipientId, content: text)
        echo.id = id
        try? await Task.sleep(for: .milliseconds(5))
        continuation?.yield(.added(echo)) //The local write's echo: the pending server stamp decodes nil
        //`-uiHarnessAckDelay <ms>` moves the server's confirmation, e.g. to land it mid-flight (default: just after the flight)
        let ack = UserDefaults.standard.integer(forKey: "uiHarnessAckDelay")
        try? await Task.sleep(for: .milliseconds(ack > 0 ? ack : 900))
        var stamped = echo
        stamped.dateCreated = Date()
        continuation?.yield(.modified(stamped)) //The server's acknowledgement
    }

    func fetchMessages(eventId: String) async throws -> [ChatMessage] { seed }

    func chatsTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatThread>, Error> {
        AsyncThrowingStream { _ in }
    }

    //Newest first, as the real query is ordered — the ViewModel reverses `.initial`
    func messagesTracker(eventId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatMessage>, Error> {
        AsyncThrowingStream { cont in
            self.continuation = cont
            cont.yield(.initial(self.seed.reversed()))
        }
    }
}
#endif
