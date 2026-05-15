import SwiftUI

struct ChatView: View {
    let conversationId: String

    @StateObject private var viewModel: ChatViewModel
    @State private var inputText: String = ""

    init(conversationId: String) {
        self.conversationId = conversationId
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.messages.sorted { ($0.sentDate ?? Date.distantPast) < ($1.sentDate ?? Date.distantPast) }) { msg in
                                let isCurrentUser = msg.senderId == viewModel.currentUserId
                                HStack(alignment: .top, spacing: 8) {
                                    if isCurrentUser {
                                        Spacer()
                                    }
                                    VStack(alignment: isCurrentUser ? .trailing : .leading) {
                                        Text(msg.content)
                                            .padding(12)
                                            .background(isCurrentUser ? Color.blue : Color(.systemGray6))
                                            .foregroundColor(isCurrentUser ? .white : .primary)
                                            .cornerRadius(12)
                                        if let date = msg.sentDate {
                                            Text(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if !isCurrentUser {
                                        Spacer()
                                    }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Введите сообщение...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task {
                        do {
                            try await viewModel.send(text)
                            inputText = ""
                        } catch {
                            print("Ошибка отправки: \(error)")
                        }
                    }
                }) {
                    Text("Отправить")
                }
            }
            .padding()
        }
        .navigationTitle("Чат")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
