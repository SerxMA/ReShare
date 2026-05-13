import SwiftUI

struct ListingDetailView: View {
    let listingId: String

    @StateObject private var viewModel: ListingDetailViewModel
    @EnvironmentObject private var favoritesManager: FavoritesManager

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
                    VStack(alignment: .leading, spacing: 16) {
                        photosView(detail)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(detail.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack(spacing: 12) {
                                TagView(detail.status, color: .gray, size: .small, style: .filled)
                                TagView(detail.conditionName, color: .orange, size: .small, style: .outline)
                                TagView(detail.transferTypeName, color: .blue, size: .small, style: .outline)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                Text((detail.district.map { "\($0), " } ?? "") + detail.city)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)

                            Text(detail.description)
                                .foregroundColor(.primary)
                                .lineLimit(nil)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label(detail.userName, systemImage: "person.circle")
                                    Spacer()
                                    Text(detail.createdAt)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }

                                HStack {
                                    Label("Вес: \(detail.weightGrams) г", systemImage: "scalemass")
                                    Spacer()
                                    if let eco = detail.ecoKg {
                                        Label("\(eco) кг CO₂", systemImage: "leaf.fill")
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                                if !detail.tags.isEmpty {
                                    HStack {
                                        Text("Теги:")
                                            .fontWeight(.semibold)
                                        FlexibleTagList(tags: detail.tags)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                EmptyView()
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
        }
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
            ForEach(tags, id: \ .self) { tag in
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
