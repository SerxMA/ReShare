import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel: MessagesViewModel
    @StateObject private var locationService = LocationService()
    @State private var searchText: String = ""
    @State private var selectedConversation: ConversationResponse?

    init(viewModel: MessagesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var filteredConversations: [ConversationResponse] {
        guard !searchText.isEmpty else {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { conversation in
            let title = conversation.listing?.title ?? ""
            let user = conversation.counterparty?.fullName ?? ""
            let message = conversation.lastMessage?.content ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                user.localizedCaseInsensitiveContains(searchText) ||
                message.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Сообщения")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    InputBase(
                        text: $searchText,
                        placeholder: "Поиск по чату или объявлению",
                        leftIcon: Image(systemName: "magnifyingglass"),
                        rightIcon: Image(systemName: "slider.horizontal.3"),
                        inputStyle: .shaded
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)

                Divider()

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredConversations.isEmpty {
                    Text("У вас пока нет сообщений")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredConversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                viewModel.startPolling()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .navigationDestination(for: ConversationResponse.self) { conversation in
                ChatView(conversationId: conversation.id)
            }
        }
    }
}

private struct ConversationRow: View {
    let conversation: ConversationResponse

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 50, height: 50)
                Text(conversation.counterparty?.fullName.prefix(1) ?? "?")
                    .font(.title3)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(conversation.counterparty?.fullName ?? "Пользователь")
                    .font(.headline)
                if let listingTitle = conversation.listing?.title {
                    Text("По объявлению: \(listingTitle)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let lastMessage = conversation.lastMessage?.content {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let date = conversation.lastMessage?.sentDate {
                    Text(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}
