import SwiftUI

enum ButtonSize {
    case large
}

enum ButtonColor {
    case transparent
    case filled
    case shaded
    case brand
    case outline
    case destructive
}

enum ButtonStateStyle {
    case normal
    case error
}

enum InputStyle {
    case outline
    case shaded
}

enum InputStateStyle {
    case normal
    case error
    case success
    case warning
}

enum TagColor {
    case white
    case green
    case blue
    case red
    case yellow
    case purple
    case teal
    case orange
    case gray
    case black
}

enum TagSize {
    case large
    case medium
    case small
}

enum TagStyle {
    case subtle
    case filled
    case outline
}

enum AvatarSize {
    case huge
    case extraLarge
    case large
    case medium
    case small
    case tiny
}

enum AvatarShape {
    case square
    case circle
}

enum RatingSize {
    case large
    case medium
    case small
}

enum DividerPosition {
    case left
    case middle
    case right
}

enum AuthFormType {
    case login
    case register
}

struct AuthFormData {
    var login: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
}
