import SwiftUI
import PhotosUI

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateListingViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    let onSuccess: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    sectionTitle("Новое объявление")

                    InputBase(
                        text: $viewModel.title,
                        placeholder: "Название",
                        textLabel: "Название",
                        helper: nil,
                        inputStyle: .outline,
                        stateStyle: .normal
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Описание")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextEditor(text: $viewModel.description)
                            .frame(height: 140)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }

                    InputBase(
                        text: $viewModel.city,
                        placeholder: "Город",
                        textLabel: "Город",
                        inputStyle: .shaded,
                        stateStyle: .normal
                    )

                    InputBase(
                        text: $viewModel.weight,
                        placeholder: "Вес в граммах",
                        textLabel: "Вес",
                        inputStyle: .shaded,
                        stateStyle: .normal,
                        keyboardType: .numberPad
                    )

                    categoryPicker
                    conditionPicker
                    transferTypePicker
                    transferMethodPicker

                    photoPickerSection

                    InputBase(
                        text: $viewModel.tagsText,
                        placeholder: "Теги через запятую",
                        textLabel: "Теги",
                        inputStyle: .outline,
                        stateStyle: .normal
                    )

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }

                    ButtonBase(
                        action: {
                            Task {
                                await submit()
                            }
                        },
                        color: .brand,
                        disabled: !viewModel.canSubmit || viewModel.isLoading
                    ) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Опубликовать")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Создать объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadCategories()
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Категория")
                .font(.subheadline)
                .fontWeight(.semibold)

            if viewModel.isLoading && viewModel.categories.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("Категория", selection: Binding(
                    get: { viewModel.selectedCategoryId ?? "" },
                    set: { viewModel.selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Выберите категорию").tag("")
                    ForEach(viewModel.categories, id: \.id) { category in
                        Text(category.name).tag(category.id)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var conditionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Состояние")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("Состояние", selection: $viewModel.condition) {
                ForEach(ListingCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Фотографии")
                .font(.subheadline)
                .fontWeight(.semibold)

            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 6, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Выберите до 6 фото")
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .onChange(of: selectedPhotoItems) { newItems in
                Task {
                    await viewModel.updateSelectedPhotos(from: newItems)
                }
            }

            if viewModel.selectedImages.isEmpty {
                Text("Обязательно добавьте хотя бы одно фото для объявления")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \ .offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(12)

                                Button(action: {
                                    viewModel.selectedImages.remove(at: index)
                                    selectedPhotoItems = Array(selectedPhotoItems.enumerated().filter { $0.offset != index }.map { $0.element })
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var transferTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тип передачи")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("Тип передачи", selection: $viewModel.transferType) {
                ForEach(ListingTransferType.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var transferMethodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Способ передачи")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("Способ передачи", selection: $viewModel.transferMethod) {
                ForEach(ListingTransferMethod.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
    }

    private func submit() async {
        do {
            try await viewModel.createListing()
            onSuccess()
            dismiss()
        } catch {
            // Ошибка уже показана в viewModel.errorMessage
        }
    }
}
