import SwiftUI

struct ListingDetailView: View {
    let listingId: String

    @StateObject private var viewModel: ListingDetailViewModel
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var chatId: String?
    @State private var navigateToChat = false
    @State private var myUserId: String?
    @State private var isCreatingConversation = false

    init(listingId: String) {
        self.listingId = listingId
        _viewModel = StateObject(wrappedValue: ListingDetailViewModel(listingId: listingId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Не удалось загрузить объявление")
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(spacing: 20) {
                        photosView(detail)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(detail.title)
                                            .font(.title)
                                            .fontWeight(.semibold)
                                            .fixedSize(horizontal: false, vertical: true)

                                        HStack(spacing: 10) {
                                            TagView(detail.status, color: .gray, size: .small, style: .filled)
                                            TagView(detail.conditionName, color: .orange, size: .small, style: .outline)
                                            TagView(detail.transferTypeName, color: .blue, size: .small, style: .outline)
                                        }
                                    }

                                    Spacer()

                                    Text(detail.createdAtDisplay)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.secondary)
                                    Text((detail.district.map { "\($0), " } ?? "") + detail.city)
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)

                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "scalemass")
                                                .foregroundColor(.blue)
                                            Text("Вес")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        Text("\(detail.weightGrams) г")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "leaf.fill")
                                                .foregroundColor(.green)
                                            Text("Экология")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        Text(detail.ecoKg.map { "\($0) кг CO₂" } ?? "—")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Описание")
                                        .font(.headline)
                                    Text(detail.description)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)

                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 52, height: 52)
                                        Text(detail.userName.prefix(1))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(detail.userName)
                                            .font(.headline)
                                        Text("Владелец объявления")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                if !detail.tags.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Теги")
                                            .font(.headline)
                                        FlexibleTagList(tags: detail.tags)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)

                            if let ownerId = detail.userId, ownerId != myUserId {
                                Button(action: {
                                    guard !isCreatingConversation else { return }
                                    isCreatingConversation = true
                                    Task {
                                        do {
                                            let conv = try await ChatService.shared.createConversation(recipientId: ownerId, listingId: detail.apiId)
                                            chatId = conv
                                            navigateToChat = true
                                        } catch {
                                            print("Ошибка создания беседы: \(error)")
                                        }
                                        isCreatingConversation = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                        Text("Написать владельцу")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Загрузка данных объявления...")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Объявление")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let detail = viewModel.detail {
                    Button(action: {
                        favoritesManager.toggleFavorite(listing: Listing(detail: detail))
                    }) {
                        Image(systemName: favoritesManager.isFavorite(listingId: detail.apiId) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesManager.isFavorite(listingId: detail.apiId) ? .red : .primary)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
            Task {
                do {
                    let profile = try await ProfileService.shared.fetchMyProfile()
                    myUserId = profile.id
                } catch {
                    print("Не удалось загрузить профиль: \(error)")
                }
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let id = chatId {
                        ChatView(conversationId: id)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $navigateToChat,
                label: { EmptyView() }
            )
        )
    }

    @ViewBuilder
    private func photosView(_ detail: ListingDetail) -> some View {
        if detail.photos.isEmpty {
            Color(.systemGray5)
                .frame(height: 260)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                )
                .cornerRadius(16)
                .padding(.horizontal)
        } else {
            TabView {
                ForEach(detail.photos) { photo in
                    AsyncImage(url: photo.url) { phase in
                        switch phase {
                        case .empty:
                            Color(.systemGray5)
                                .overlay(ProgressView())
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color(.systemGray5)
                                .overlay(Image(systemName: "xmark.octagon").foregroundColor(.secondary))
                        @unknown default:
                            Color(.systemGray5)
                        }
                    }
                    .frame(height: 260)
                    .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 260)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

private struct FlexibleTagList: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
}
