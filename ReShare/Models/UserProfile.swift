import Foundation

struct UserEcoStats: Codable {
    let itemsGifted: Int
    let itemsReceived: Int
    let co2SavedKg: Double
    let wasteSavedKg: Double
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let bio: String?
    let city: String?
    let rating: Double
    let reviewCount: Int
    let ecoStats: UserEcoStats
    let createdAt: String

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var joinedYear: String {
        String(createdAt.prefix(4))
    }
}
