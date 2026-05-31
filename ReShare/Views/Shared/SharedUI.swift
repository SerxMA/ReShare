import SwiftUI

struct ButtonBase<Label: View>: View {
    let action: () -> Void
    let label: Label
    let size: ButtonSize
    let color: ButtonColor
    let stateStyle: ButtonStateStyle
    let withBorder: Bool
    let disabled: Bool

    init(
        action: @escaping () -> Void,
        size: ButtonSize = .large,
        color: ButtonColor = .transparent,
        stateStyle: ButtonStateStyle = .normal,
        withBorder: Bool = false,
        disabled: Bool = false,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
        self.size = size
        self.color = color
        self.stateStyle = stateStyle
        self.withBorder = withBorder
        self.disabled = disabled
    }

    var body: some View {
        Button(action: action) {
            label
                .font(font)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }

    private var height: CGFloat {
        switch size {
        case .large:
            return 52
        }
    }

    private var font: Font {
        switch size {
        case .large:
            return .headline
        }
    }

    private var backgroundColor: Color {
        switch color {
        case .transparent:
            return .clear
        case .filled:
            return Color.accentColor
        case .shaded:
            return Color(.systemGray6)
        case .brand:
            return Color.blue
        case .outline:
            return .clear
        case .destructive:
            return Color.red
        }
    }

    private var foregroundColor: Color {
        switch color {
        case .transparent, .outline, .shaded:
            return stateStyle == .error ? .red : .primary
        default:
            return .white
        }
    }

    private var borderColor: Color {
        if withBorder {
            return stateStyle == .error ? .red : Color(.systemGray4)
        }

        switch color {
        case .outline:
            return stateStyle == .error ? .red : Color(.systemGray4)
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        withBorder || color == .outline ? 1 : 0
    }
}

struct InputBase: View {
    @Binding var text: String
    let textLabel: String?
    let helper: String?
    let placeholder: String
    let leftIcon: Image?
    let rightIcon: Image?
    let rightIconAction: (() -> Void)?
    let inputStyle: InputStyle
    let stateStyle: InputStateStyle
    let keyboardType: UIKeyboardType
    let disabled: Bool

    init(
        text: Binding<String>,
        placeholder: String = "",
        textLabel: String? = nil,
        helper: String? = nil,
        leftIcon: Image? = nil,
        rightIcon: Image? = nil,
        rightIconAction: (() -> Void)? = nil,
        inputStyle: InputStyle = .outline,
        stateStyle: InputStateStyle = .normal,
        keyboardType: UIKeyboardType = .default,
        disabled: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.textLabel = textLabel
        self.helper = helper
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.rightIconAction = rightIconAction
        self.inputStyle = inputStyle
        self.stateStyle = stateStyle
        self.keyboardType = keyboardType
        self.disabled = disabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let textLabel {
                Text(textLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 10) {
                if let leftIcon {
                    leftIcon
                        .foregroundColor(.gray)
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .disabled(disabled)
                    .foregroundColor(disabled ? .gray : .primary)

                if let rightIcon {
                    if let rightIconAction {
                        Button(action: rightIconAction) {
                            rightIcon
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    } else {
                        rightIcon
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(14)
            .background(inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(14)

            if let helper {
                Text(helper)
                    .font(.caption)
                    .foregroundColor(helperColor)
            }
        }
    }

    private var inputBackground: Color {
        switch inputStyle {
        case .outline:
            return .clear
        case .shaded:
            return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        switch stateStyle {
        case .normal:
            return Color(.systemGray4)
        case .error:
            return .red
        case .success:
            return .green
        case .warning:
            return .yellow
        }
    }

    private var helperColor: Color {
        switch stateStyle {
        case .normal:
            return .gray
        case .error:
            return .red
        case .success:
            return .green
        case .warning:
            return .orange
        }
    }
}

struct TagView: View {
    let text: String
    let color: TagColor
    let size: TagSize
    let style: TagStyle
    let withBorder: Bool

    init(
        _ text: String,
        color: TagColor = .green,
        size: TagSize = .small,
        style: TagStyle = .filled,
        withBorder: Bool = false
    ) {
        self.text = text
        self.color = color
        self.size = size
        self.style = style
        self.withBorder = withBorder
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: withBorder || style == .outline ? 1 : 0)
            )
            .cornerRadius(12)
    }

    private var font: Font {
        switch size {
        case .large:
            return .callout.bold()
        case .medium:
            return .caption.bold()
        case .small:
            return .caption2.bold()
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .large:
            return 14
        case .medium:
            return 10
        case .small:
            return 8
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .large:
            return 8
        case .medium:
            return 6
        case .small:
            return 4
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return badgeColor
        case .subtle:
            return badgeColor.opacity(0.12)
        case .outline:
            return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return color == .white ? .black : .white
        default:
            return badgeColor
        }
    }

    private var badgeColor: Color {
        switch color {
        case .white:
            return .white
        case .green:
            return .green
        case .blue:
            return .blue
        case .red:
            return .red
        case .yellow:
            return .yellow
        case .purple:
            return .purple
        case .teal:
            return .teal
        case .orange:
            return .orange
        case .gray:
            return .gray
        case .black:
            return .black
        }
    }

    private var borderColor: Color {
        style == .outline ? badgeColor : .clear
    }
}

struct AvatarView: View {
    let imageName: String
    let systemImage: Bool
    let size: AvatarSize
    let shape: AvatarShape
    let statusDot: Bool

    init(
        imageName: String,
        systemImage: Bool = false,
        size: AvatarSize = .medium,
        shape: AvatarShape = .circle,
        statusDot: Bool = false
    ) {
        self.imageName = imageName
        self.systemImage = systemImage
        self.size = size
        self.shape = shape
        self.statusDot = statusDot
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: diameter, height: diameter)
                .clipShape(clipShape)
                .overlay(
                    clipShape
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            if statusDot {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var image: Image {
        if systemImage {
            return Image(systemName: imageName)
        } else {
            return Image(imageName)
        }
    }

    private var diameter: CGFloat {
        switch size {
        case .huge:
            return 80
        case .extraLarge:
            return 64
        case .large:
            return 52
        case .medium:
            return 40
        case .small:
            return 32
        case .tiny:
            return 24
        }
    }

    private var clipShape: some Shape {
        switch shape {
        case .circle:
            return AnyShape(Circle())
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct RatingView: View {
    let rating: Double
    let size: RatingSize
    let showValue: Bool

    init(rating: Double, size: RatingSize = .large, showValue: Bool = true) {
        self.rating = rating
        self.size = size
        self.showValue = showValue
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: rating >= Double(index) ? "star.fill" : "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(rating >= Double(index) ? .yellow : .gray)
            }

            if showValue {
                Text(String(format: "%.1f", rating))
                    .font(ratingFont)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var starSize: CGFloat {
        switch size {
        case .large:
            return 18
        case .medium:
            return 14
        case .small:
            return 12
        }
    }

    private var ratingFont: Font {
        switch size {
        case .large:
            return .subheadline.bold()
        case .medium:
            return .caption.bold()
        case .small:
            return .caption2.bold()
        }
    }
}

struct TextDividerView: View {
    let label: String?
    let position: DividerPosition

    init(_ label: String? = nil, position: DividerPosition = .middle) {
        self.label = label
        self.position = position
    }

    var body: some View {
        HStack(spacing: 8) {
            if position != .left { divider }
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if position != .right { divider }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(height: 1)
    }
}

struct UniListView<Data, Content>: View where Data: RandomAccessCollection, Content: View, Data.Element: Identifiable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

struct AuthFormView: View {
    @Binding var formType: AuthFormType
    @Binding var formData: AuthFormData
    let onSubmit: () -> Void
    let isLoading: Bool
    let errors: [String: String]

    var body: some View {
        VStack(spacing: 16) {
            Text(formTitle)
                .font(.title2)
                .fontWeight(.bold)

            if formType == .register {
                InputBase(
                    text: $formData.firstName,
                    placeholder: "Имя",
                    textLabel: "Имя",
                    helper: errors["firstName"],
                    inputStyle: .outline,
                    stateStyle: errorState(for: "firstName")
                )
            }

            InputBase(
                text: $formData.email,
                placeholder: "Email",
                textLabel: "Email",
                helper: errors["email"],
                inputStyle: .outline,
                stateStyle: errorState(for: "email")
            )

            InputBase(
                text: $formData.password,
                placeholder: "Пароль",
                textLabel: "Пароль",
                helper: errors["password"],
                inputStyle: .outline,
                stateStyle: errorState(for: "password")
            )

            ButtonBase(
                action: onSubmit,
                color: .filled,
                disabled: isLoading
            ) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text(formButtonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var formTitle: String {
        switch formType {
        case .login:
            return "Вход"
        case .register:
            return "Регистрация"
        }
    }

    private var formButtonTitle: String {
        switch formType {
        case .login:
            return "Войти"
        case .register:
            return "Зарегистрироваться"
        }
    }

    private func errorState(for field: String) -> InputStateStyle {
        errors[field] != nil ? .error : .normal
    }
}

private struct AnyShape: Shape {
    private let path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}
