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
    case error(message: String, nonce: UUID = UUID()) //A user-initiated write that failed; the nonce keeps two identical failures two banners

    var id: String {
        switch self {
        case .newMessage(let p): "message-\(p.eventId)"
        case .error(_, let nonce): "error-\(nonce.uuidString)"
        }
    }

    var eventId: String? {
        switch self {
        case .newMessage(let p): p.eventId
        case .error: nil
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
            case .error(let message, _):
                ErrorBannerView(message: message, onDismiss: { dep.notifications.dismiss() })
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

//The banner's card and its dismissal, one copy for every banner kind: a tap acts, an upward flick dismisses
private struct BannerCard: ViewModifier {

    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCanvas, in: .rect(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.gutter)
            .shadow(.softFloating)
            .offset(y: dragOffset)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = min(0, value.translation.height)
                    }
                    .onEnded { value in
                        if value.translation.height < -20 { //Geometry: the upward travel that commits a dismissal
                            dragOffset = 0
                            onDismiss()
                        } else {
                            withAnimation(.move) { dragOffset = 0 }
                        }
                    }
            )
    }
}

//A failure instead of a message, on the same card: a tap or an upward flick dismisses it
private struct ErrorBannerView: View {

    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.icon(16))
                .foregroundStyle(Color.dangerRed)

            Text(message)
                .font(.body(14, .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .modifier(BannerCard(onTap: onDismiss, onDismiss: onDismiss))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

private struct MessageBannerView: View {

    let model: MessagePopup
    let imageLoader: ImageLoading
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                HStack(spacing: Spacing.md) {
                    SmallImage(image: image, size: 40, isCircle: true)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
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
                .padding(.trailing, Spacing.md)
                .padding(.leading, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .modifier(BannerCard(onTap: onTap, onDismiss: onDismiss))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task(id: model.image) {
            image = nil
            guard let url = URL(string: model.image) else { return }
            image = try? await imageLoader.fetchImage(for: url)
        }
    }
}
