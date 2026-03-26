import AppKit

struct PopoverTheme {
    let name: String
    let popoverBg: NSColor
    let popoverBorder: NSColor
    let popoverBorderWidth: CGFloat
    let popoverCornerRadius: CGFloat
    let titleBarBg: NSColor
    let titleText: NSColor
    let titleFont: NSFont
    let titleString: String
    let separatorColor: NSColor
    let font: NSFont
    let fontBold: NSFont
    let textPrimary: NSColor
    let textDim: NSColor
    let accentColor: NSColor
    let errorColor: NSColor
    let successColor: NSColor
    let inputBg: NSColor
    let inputCornerRadius: CGFloat
    let bubbleBg: NSColor
    let bubbleBorder: NSColor
    let bubbleText: NSColor
    let bubbleCompletionBorder: NSColor
    let bubbleCompletionText: NSColor
    let bubbleFont: NSFont
    let bubbleCornerRadius: CGFloat

    // MARK: - Themes

    static let peach = PopoverTheme(
        name: "Peach",
        popoverBg: NSColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 0.97),
        popoverBorder: NSColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 0.8),
        popoverBorderWidth: 2.5, popoverCornerRadius: 24,
        titleBarBg: NSColor(red: 0.98, green: 0.93, blue: 0.88, alpha: 1.0),
        titleText: NSColor(red: 0.85, green: 0.35, blue: 0.45, alpha: 1.0),
        titleFont: .systemFont(ofSize: 12, weight: .heavy), titleString: "pix ~",
        separatorColor: NSColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 0.25),
        font: .systemFont(ofSize: 12, weight: .regular),
        fontBold: .systemFont(ofSize: 12, weight: .semibold),
        textPrimary: NSColor(red: 0.2, green: 0.18, blue: 0.22, alpha: 1.0),
        textDim: NSColor(red: 0.5, green: 0.47, blue: 0.52, alpha: 1.0),
        accentColor: NSColor(red: 0.85, green: 0.35, blue: 0.45, alpha: 1.0),
        errorColor: NSColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0),
        successColor: NSColor(red: 0.3, green: 0.72, blue: 0.5, alpha: 1.0),
        inputBg: NSColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0), inputCornerRadius: 14,
        bubbleBg: NSColor(red: 1.0, green: 0.95, blue: 0.90, alpha: 0.95),
        bubbleBorder: NSColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 0.6),
        bubbleText: NSColor(red: 0.55, green: 0.5, blue: 0.52, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.3, green: 0.75, blue: 0.5, alpha: 0.7),
        bubbleCompletionText: NSColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1.0),
        bubbleFont: .systemFont(ofSize: 11, weight: .semibold), bubbleCornerRadius: 14
    )

    static let midnight = PopoverTheme(
        name: "Midnight",
        popoverBg: NSColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 0.96),
        popoverBorder: NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.7),
        popoverBorderWidth: 1.5, popoverCornerRadius: 12,
        titleBarBg: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
        titleText: NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0),
        titleFont: .monospacedSystemFont(ofSize: 10, weight: .bold), titleString: "PIX",
        separatorColor: NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.3),
        font: .monospacedSystemFont(ofSize: 11.5, weight: .regular),
        fontBold: .monospacedSystemFont(ofSize: 11.5, weight: .medium),
        textPrimary: .white, textDim: NSColor(white: 0.6, alpha: 1.0),
        accentColor: NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0),
        errorColor: NSColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0),
        successColor: NSColor(red: 0.4, green: 0.65, blue: 0.4, alpha: 1.0),
        inputBg: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0), inputCornerRadius: 4,
        bubbleBg: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.92),
        bubbleBorder: NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.6),
        bubbleText: NSColor(white: 0.7, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.7),
        bubbleCompletionText: NSColor(red: 0.3, green: 0.85, blue: 0.3, alpha: 1.0),
        bubbleFont: .monospacedSystemFont(ofSize: 10, weight: .medium), bubbleCornerRadius: 12
    )

    static let cloud = PopoverTheme(
        name: "Cloud",
        popoverBg: NSColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 0.98),
        popoverBorder: NSColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 0.6),
        popoverBorderWidth: 1, popoverCornerRadius: 16,
        titleBarBg: NSColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1.0),
        titleText: NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0),
        titleFont: .systemFont(ofSize: 12, weight: .semibold), titleString: "pix ~",
        separatorColor: NSColor(red: 0.8, green: 0.82, blue: 0.85, alpha: 0.4),
        font: .systemFont(ofSize: 12, weight: .regular),
        fontBold: .systemFont(ofSize: 12, weight: .semibold),
        textPrimary: NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0),
        textDim: NSColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0),
        accentColor: NSColor(red: 0.0, green: 0.47, blue: 0.84, alpha: 1.0),
        errorColor: NSColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 1.0),
        successColor: NSColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1.0),
        inputBg: .white, inputCornerRadius: 8,
        bubbleBg: NSColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 0.95),
        bubbleBorder: NSColor(red: 0.0, green: 0.47, blue: 0.84, alpha: 0.4),
        bubbleText: NSColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 0.6),
        bubbleCompletionText: NSColor(red: 0.15, green: 0.55, blue: 0.2, alpha: 1.0),
        bubbleFont: .systemFont(ofSize: 10, weight: .semibold), bubbleCornerRadius: 12
    )

    static let moss = PopoverTheme(
        name: "Moss",
        popoverBg: NSColor(red: 0.82, green: 0.84, blue: 0.78, alpha: 0.98),
        popoverBorder: NSColor(red: 0.55, green: 0.58, blue: 0.50, alpha: 0.8),
        popoverBorderWidth: 2, popoverCornerRadius: 10,
        titleBarBg: NSColor(red: 0.72, green: 0.75, blue: 0.68, alpha: 1.0),
        titleText: NSColor(red: 0.15, green: 0.17, blue: 0.12, alpha: 1.0),
        titleFont: .systemFont(ofSize: 11, weight: .bold), titleString: "Pix",
        separatorColor: NSColor(red: 0.55, green: 0.58, blue: 0.50, alpha: 0.5),
        font: .monospacedSystemFont(ofSize: 11, weight: .regular),
        fontBold: .monospacedSystemFont(ofSize: 11, weight: .bold),
        textPrimary: NSColor(red: 0.1, green: 0.12, blue: 0.08, alpha: 1.0),
        textDim: NSColor(red: 0.35, green: 0.38, blue: 0.30, alpha: 1.0),
        accentColor: NSColor(red: 0.2, green: 0.22, blue: 0.15, alpha: 1.0),
        errorColor: NSColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 1.0),
        successColor: NSColor(red: 0.15, green: 0.4, blue: 0.15, alpha: 1.0),
        inputBg: NSColor(red: 0.88, green: 0.90, blue: 0.84, alpha: 1.0), inputCornerRadius: 3,
        bubbleBg: NSColor(red: 0.82, green: 0.84, blue: 0.78, alpha: 0.95),
        bubbleBorder: NSColor(red: 0.55, green: 0.58, blue: 0.50, alpha: 0.7),
        bubbleText: NSColor(red: 0.4, green: 0.42, blue: 0.38, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 0.7),
        bubbleCompletionText: NSColor(red: 0.15, green: 0.4, blue: 0.15, alpha: 1.0),
        bubbleFont: .monospacedSystemFont(ofSize: 10, weight: .medium), bubbleCornerRadius: 8
    )

    static let ember = PopoverTheme(
        name: "Ember",
        popoverBg: NSColor(red: 0.08, green: 0.06, blue: 0.04, alpha: 0.96),
        popoverBorder: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.7),
        popoverBorderWidth: 1.5, popoverCornerRadius: 14,
        titleBarBg: NSColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 1.0),
        titleText: NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0),
        titleFont: .systemFont(ofSize: 11, weight: .bold), titleString: "pix ✦",
        separatorColor: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.25),
        font: .systemFont(ofSize: 12, weight: .regular),
        fontBold: .systemFont(ofSize: 12, weight: .semibold),
        textPrimary: NSColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0),
        textDim: NSColor(red: 0.65, green: 0.55, blue: 0.4, alpha: 1.0),
        accentColor: NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0),
        errorColor: NSColor(red: 1.0, green: 0.35, blue: 0.2, alpha: 1.0),
        successColor: NSColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1.0),
        inputBg: NSColor(red: 0.15, green: 0.1, blue: 0.07, alpha: 1.0), inputCornerRadius: 8,
        bubbleBg: NSColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 0.95),
        bubbleBorder: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.5),
        bubbleText: NSColor(red: 0.8, green: 0.65, blue: 0.45, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 0.6),
        bubbleCompletionText: NSColor(red: 0.5, green: 0.85, blue: 0.3, alpha: 1.0),
        bubbleFont: .systemFont(ofSize: 10, weight: .semibold), bubbleCornerRadius: 12
    )

    static let aurora = PopoverTheme(
        name: "Aurora",
        popoverBg: NSColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 0.96),
        popoverBorder: NSColor(red: 0.3, green: 0.8, blue: 0.7, alpha: 0.6),
        popoverBorderWidth: 1.5, popoverCornerRadius: 16,
        titleBarBg: NSColor(red: 0.07, green: 0.1, blue: 0.15, alpha: 1.0),
        titleText: NSColor(red: 0.4, green: 0.9, blue: 0.8, alpha: 1.0),
        titleFont: .systemFont(ofSize: 12, weight: .semibold), titleString: "pix ◆",
        separatorColor: NSColor(red: 0.3, green: 0.8, blue: 0.7, alpha: 0.2),
        font: .systemFont(ofSize: 12, weight: .regular),
        fontBold: .systemFont(ofSize: 12, weight: .semibold),
        textPrimary: NSColor(red: 0.9, green: 0.95, blue: 0.95, alpha: 1.0),
        textDim: NSColor(red: 0.5, green: 0.6, blue: 0.6, alpha: 1.0),
        accentColor: NSColor(red: 0.4, green: 0.9, blue: 0.8, alpha: 1.0),
        errorColor: NSColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1.0),
        successColor: NSColor(red: 0.4, green: 0.85, blue: 0.5, alpha: 1.0),
        inputBg: NSColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0), inputCornerRadius: 10,
        bubbleBg: NSColor(red: 0.07, green: 0.1, blue: 0.15, alpha: 0.95),
        bubbleBorder: NSColor(red: 0.3, green: 0.8, blue: 0.7, alpha: 0.4),
        bubbleText: NSColor(red: 0.5, green: 0.7, blue: 0.7, alpha: 1.0),
        bubbleCompletionBorder: NSColor(red: 0.4, green: 0.85, blue: 0.5, alpha: 0.6),
        bubbleCompletionText: NSColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0),
        bubbleFont: .systemFont(ofSize: 10, weight: .semibold), bubbleCornerRadius: 14
    )

    static let allThemes: [PopoverTheme] = [.peach, .midnight, .cloud, .moss, .ember, .aurora]
    static var current: PopoverTheme = .ember

    func withCharacterColor(_ color: NSColor) -> PopoverTheme {
        // Only customize accent for Peach and Ember themes
        guard name == "Peach" || name == "Ember" else { return self }
        return PopoverTheme(
            name: name, popoverBg: popoverBg,
            popoverBorder: NSColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.6),
            popoverBorderWidth: popoverBorderWidth, popoverCornerRadius: popoverCornerRadius,
            titleBarBg: titleBarBg, titleText: color, titleFont: titleFont, titleString: titleString,
            separatorColor: separatorColor, font: font, fontBold: fontBold,
            textPrimary: textPrimary, textDim: textDim, accentColor: color,
            errorColor: errorColor, successColor: successColor,
            inputBg: inputBg, inputCornerRadius: inputCornerRadius,
            bubbleBg: bubbleBg, bubbleBorder: NSColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.5),
            bubbleText: bubbleText,
            bubbleCompletionBorder: bubbleCompletionBorder, bubbleCompletionText: bubbleCompletionText,
            bubbleFont: bubbleFont, bubbleCornerRadius: bubbleCornerRadius
        )
    }
}
