import Foundation

struct ConversationCreatedResponse: Decodable {
    let conversationId: String
}

struct MessageAPIModel: Decodable, Identifiable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let sentAt: String
    let isRead: Bool

    var sentDate: Date? {
        ISO8601DateFormatter().date(from: sentAt)
    }
}

struct MessageListResponse: Decodable {
    let items: [MessageAPIModel]
}

struct ParticipantSummary: Decodable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ListingSummary: Decodable, Hashable {
    let id: String
    let title: String
}

struct ConversationResponse: Decodable, Identifiable, Hashable {
    let id: String
    let participants: [ParticipantSummary]
    let counterparty: ParticipantSummary?
    let listingId: String?
    let listing: ListingSummary?
    let lastMessage: MessageAPIModel?
    let unreadCount: Int
    let createdAt: String
    let lastMessageAt: String?
}

struct ConversationListResponse: Decodable {
    let items: [ConversationResponse]
    let totalCount: Int
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
}

final class ChatService {
    static let shared = ChatService()
    private init() {}

    func fetchConversations(pageNumber: Int = 1, pageSize: Int = 50) async throws -> [ConversationResponse] {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        print("🔍 ChatService: Загружаем список бесед /messaging/conversations")
        let response: ConversationListResponse = try await NetworkClient.shared.request(path: "/messaging/conversations", queryItems: queryItems)
        print("✅ ChatService: Получено бесед: \(response.items.count)")
        return response.items
    }

    func createConversation(recipientId: String, listingId: String?) async throws -> String {
        struct CreateConversationRequest: Encodable {
            let recipientId: String
            let listingId: String?
            let initialMessage: String? = nil
        }

        let body = try JSONEncoder().encode(CreateConversationRequest(recipientId: recipientId, listingId: listingId))
        print("🔍 ChatService: Создаём беседу с пользователем \(recipientId)")
        let response: ConversationCreatedResponse = try await NetworkClient.shared.request(path: "/messaging/conversations", method: .post, body: body)
        print("✅ ChatService: Беседа создана: \(response.conversationId)")
        return response.conversationId
    }

    func fetchMessages(conversationId: String, pageNumber: Int = 1, pageSize: Int = 50) async throws -> [MessageAPIModel] {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        print("🔍 ChatService: Загружаем сообщения беседы /messaging/conversations/\(conversationId)/messages")
        let response: MessageListResponse = try await NetworkClient.shared.request(path: "/messaging/conversations/\(conversationId)/messages", queryItems: queryItems)
        print("✅ ChatService: Получено сообщений: \(response.items.count)")
        return response.items
    }

    func sendMessage(conversationId: String, content: String) async throws -> MessageAPIModel {
        struct SendMessageRequest: Encodable {
            let content: String
        }

        let body = try JSONEncoder().encode(SendMessageRequest(content: content))
        print("🔍 ChatService: Отправляем сообщение в беседу \(conversationId)")
        let response: MessageAPIModel = try await NetworkClient.shared.request(path: "/messaging/conversations/\(conversationId)/messages", method: .post, body: body)
        print("✅ ChatService: Сообщение отправлено: \(response.id)")
        return response
    }
}
