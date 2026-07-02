//
//  InAppNotifications.swift
//  Scoop
//
//  Created by Art Ostin on 26/05/2026.
//

import SwiftUI

//Do later
enum InAppNotification: Identifiable, Equatable {
    case newMessage(MessagePopup)

    var id: String {
        switch self {
        case .newMessage(let p): return "message-\(p.eventId)"
        }
    }

    var eventId: String? {
        switch self {
        case .newMessage(let p): return p.eventId
        }
    }
}

@MainActor
@Observable
final class InAppNotificationCenter {

    private(set) var current: InAppNotification?
    private var queue: [InAppNotification] = []
    private var autoDismissTask: Task<Void, Never>?

    func push(_ notification: InAppNotification) {
        if current == nil {
            present(notification)
        } else {
            queue.append(notification)
        }
    }

    func dismiss() {
        autoDismissTask?.cancel()
        if !queue.isEmpty {
            present(queue.removeFirst())
        } else {
            current = nil
        }
    }

    func dismiss(where predicate: (InAppNotification) -> Bool) {
        queue.removeAll(where: predicate)
        if let c = current, predicate(c) { dismiss() }
    }

    func clearAll() {
        autoDismissTask?.cancel()
        queue.removeAll()
        current = nil
    }

    private func present(_ notification: InAppNotification) {
        current = notification
        autoDismissTask?.cancel()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }
}

// MARK: - InAppNotificationOverlay

struct InAppNotificationOverlay: View {

    @Environment(AppDependencies.self) private var dep
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            switch dep.notifications.current {
            case .newMessage(let model):
                MessageBannerView(
                    model: model,
                    imageLoader: dep.imageLoader,
                    onTap: { route(.newMessage(model)) },
                    onDismiss: { dep.notifications.dismiss() }
                )
            case .none:
                EmptyView()
            }
        }
        .animation(.spring(duration: 0.4), value: dep.notifications.current?.id)
    }

    private func route(_ notification: InAppNotification) {
        dep.notifications.dismiss()
        router.handle(notification, session: dep.session)
    }
}

private struct MessageBannerView: View {

    let model: MessagePopup
    let imageLoader: ImageLoading
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var image: UIImage?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Group {
            if let image {
                HStack(spacing: 16) {
                    CirclePhoto(image: image, showShadow: false, height: 40)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.authorName)
                            .font(.body(16, .bold))

                        Text(model.message)
                            .font(.body(14, .regular))
                            .foregroundStyle(Color.black.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2.5)
                    }
                }
                .padding(.trailing, 16)
                .padding(.leading, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCanvas, in: .rect(cornerRadius: 16))
                .padding(.horizontal, 16)
                .customShadow(.floating, strength: 0.5)
                .offset(y: dragOffset)
                .transition(.move(edge: .top).combined(with: .opacity))
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = min(0, value.translation.height)
                        }
                        .onEnded { value in
                            if value.translation.height < -20 {
                                dragOffset = 0
                                onDismiss()
                            } else {
                                withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                            }
                        }
                )
            }
        }
        .task(id: model.image) {
            image = nil
            guard let url = URL(string: model.image) else { return }
            image = try? await imageLoader.fetchImage(for: url)
        }
    }
}
