import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [MessageAPIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?

    private let conversationId: String
    private var pollTask: Task<Void, Never>?

    init(conversationId: String) {
        self.conversationId = conversationId
        loadCurrentUserId()
    }

    private func loadCurrentUserId() {
        Task {
            do {
                let profile = try await ProfileService.shared.fetchMyProfile()
                self.currentUserId = profile.id
            } catch {
                print("❌ ChatViewModel: Ошибка загрузки ID пользователя: \(error)")
            }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            messages = try await ChatService.shared.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func send(_ content: String) async throws {
        let sent = try await ChatService.shared.sendMessage(conversationId: conversationId, content: content)
        messages.append(sent)
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.load()
                do {
                    try await Task.sleep(nanoseconds: 8 * 1_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var conversations: [ConversationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    private var pollTask: Task<Void, Never>?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await ChatService.shared.fetchConversations()
            conversations = items
            unreadCount = items.reduce(0) { $0 + $1.unreadCount }
        } catch {
            errorMessage = error.localizedDescription
            conversations = []
            unreadCount = 0
        }
        isLoading = false
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.load()
                do {
                    try await Task.sleep(nanoseconds: 15 * 1_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
