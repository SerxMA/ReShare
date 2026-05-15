import SwiftUI
import Combine

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    
    init(profile: UserProfile) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(profile: profile))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Имя", text: $viewModel.firstName)
                    TextField("Фамилия", text: $viewModel.lastName)
                }
                
                Section(header: Text("Контакты")) {
                    TextField("Номер телефона", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("О себе")) {
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else {
                    Section {
                        Button(action: saveTapped) {
                            HStack {
                                Spacer()
                                Text("Сохранить")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .navigationTitle("Редактирование профиля")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveTapped() {
        Task {
            let success = await viewModel.updateProfile()
            if success {
                dismiss()
            }
        }
    }
}

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phoneNumber: String = ""
    @Published var bio: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let originalProfile: UserProfile

    init(profile: UserProfile) {
        self.originalProfile = profile
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.phoneNumber = ""
        self.bio = profile.bio ?? ""
    }

    func updateProfile() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateProfileRequest(
                firstName: firstName,
                lastName: lastName,
                phoneNumber: phoneNumber,
                bio: bio
            )
            try await ProfileService.shared.updateProfile(request: request)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
