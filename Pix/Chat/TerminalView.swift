import AppKit

class TerminalView: NSView {
    let scrollView = NSScrollView()
    let textView = NSTextView()
    let inputField = NSTextField()
    var onSendMessage: ((String) -> Void)?
    var characterColor: NSColor?

    private var isStreaming = false
    private var currentAssistantText = ""

    // Pixel game font
    private static let pixelFont: NSFont = {
        // Try pixel-style fonts, fall back to monospaced
        if let f = NSFont(name: "Menlo", size: 12) { return f }
        return NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    }()
    private static let pixelFontBold: NSFont = {
        if let f = NSFont(name: "Menlo-Bold", size: 12) { return f }
        return NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    }()
    private static let pixelFontSmall: NSFont = {
        if let f = NSFont(name: "Menlo", size: 10) { return f }
        return NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    }()

    override init(frame: NSRect) { super.init(frame: frame); setupViews() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupViews() }

    // MARK: - Game UI Colors

    private var bgColor: NSColor { NSColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 1.0) }
    private var borderColor: NSColor { characterColor?.withAlphaComponent(0.6) ?? NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.6) }
    private var accentColor: NSColor { characterColor ?? NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0) }
    private var textColor: NSColor { NSColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1.0) }
    private var dimColor: NSColor { NSColor(red: 0.45, green: 0.5, blue: 0.55, alpha: 1.0) }
    private var userColor: NSColor { NSColor(red: 0.4, green: 0.85, blue: 1.0, alpha: 1.0) }
    private var errorRed: NSColor { NSColor(red: 1.0, green: 0.35, blue: 0.3, alpha: 1.0) }
    private var successGreen: NSColor { NSColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0) }
    private var inputBgColor: NSColor { NSColor(red: 0.1, green: 0.1, blue: 0.16, alpha: 1.0) }

    // MARK: - Setup

    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = bgColor.cgColor

        let inputH: CGFloat = 32
        let pad: CGFloat = 8

        // --- Scroll + Text ---
        scrollView.frame = NSRect(x: pad, y: inputH + pad + 4, width: frame.width - pad * 2, height: frame.height - inputH - pad - 8)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        textView.frame = scrollView.contentView.bounds
        textView.autoresizingMask = [.width]
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = textColor
        textView.font = Self.pixelFont
        textView.isRichText = true
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true

        scrollView.documentView = textView
        addSubview(scrollView)

        // --- Input field (pixel style) ---
        let inputBg = NSView(frame: NSRect(x: pad, y: 4, width: frame.width - pad * 2, height: inputH))
        inputBg.wantsLayer = true
        inputBg.layer?.backgroundColor = inputBgColor.cgColor
        inputBg.layer?.cornerRadius = 4
        inputBg.layer?.borderWidth = 1.5
        inputBg.layer?.borderColor = borderColor.cgColor
        inputBg.autoresizingMask = [.width]
        addSubview(inputBg)

        // Prompt indicator
        let prompt = NSTextField(labelWithString: "▸")
        prompt.font = Self.pixelFont
        prompt.textColor = accentColor
        prompt.frame = NSRect(x: pad + 6, y: 8, width: 16, height: inputH - 8)
        prompt.drawsBackground = false
        prompt.isBordered = false
        addSubview(prompt)

        inputField.frame = NSRect(x: pad + 20, y: 6, width: frame.width - pad * 2 - 24, height: inputH - 4)
        inputField.autoresizingMask = [.width]
        inputField.focusRingType = .none
        inputField.drawsBackground = false
        inputField.isBordered = false
        inputField.font = Self.pixelFont
        inputField.textColor = textColor
        inputField.placeholderAttributedString = NSAttributedString(
            string: "say something...",
            attributes: [.font: Self.pixelFont, .foregroundColor: dimColor]
        )
        if let cell = inputField.cell as? NSTextFieldCell {
            cell.focusRingType = .none
        }
        inputField.target = self
        inputField.action = #selector(inputSubmitted)
        addSubview(inputField)

        // Welcome message
        appendSystem("[ PIX TERMINAL v1.0 ]")
        appendSystem("click the mushroom. ask anything.")
    }

    @objc private func inputSubmitted() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputField.stringValue = ""

        if text.lowercased() == "boo" { CharacterRegistry.shared.addEasterEgg("boo") }

        appendUser(text)
        isStreaming = true
        currentAssistantText = ""
        onSendMessage?(text)
    }

    // MARK: - Append Methods

    private func appendSystem(_ text: String) {
        let attr = NSAttributedString(string: "\(text)\n", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: dimColor
        ])
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    func appendUser(_ text: String) {
        ensureNewline()
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "YOU ", attributes: [
            .font: Self.pixelFontBold, .foregroundColor: userColor
        ]))
        attr.append(NSAttributedString(string: "▸ ", attributes: [
            .font: Self.pixelFont, .foregroundColor: userColor.withAlphaComponent(0.5)
        ]))
        attr.append(NSAttributedString(string: "\(text)\n", attributes: [
            .font: Self.pixelFont, .foregroundColor: textColor
        ]))
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    func appendStreamingText(_ text: String) {
        var cleaned = text
        if currentAssistantText.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: "^\n+", with: "", options: .regularExpression)
            if !cleaned.isEmpty {
                // Add AI prefix for first chunk
                let prefix = NSMutableAttributedString()
                prefix.append(NSAttributedString(string: "PIX ", attributes: [
                    .font: Self.pixelFontBold, .foregroundColor: accentColor
                ]))
                prefix.append(NSAttributedString(string: "▸ ", attributes: [
                    .font: Self.pixelFont, .foregroundColor: accentColor.withAlphaComponent(0.5)
                ]))
                textView.textStorage?.append(prefix)
            }
        }
        currentAssistantText += cleaned
        if !cleaned.isEmpty {
            textView.textStorage?.append(renderMarkdown(cleaned))
            scrollToBottom()
        }
    }

    func endStreaming() {
        if isStreaming {
            isStreaming = false
            // Ensure newline after response
            ensureNewline()
        }
    }

    func appendError(_ text: String) {
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "ERR ", attributes: [
            .font: Self.pixelFontBold, .foregroundColor: errorRed
        ]))
        attr.append(NSAttributedString(string: "\(text)\n", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: errorRed.withAlphaComponent(0.8)
        ]))
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    func appendToolUse(toolName: String, summary: String) {
        endStreaming()
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: " ⚡ ", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: accentColor
        ]))
        attr.append(NSAttributedString(string: "\(toolName.lowercased()) ", attributes: [
            .font: Self.pixelFontBold, .foregroundColor: accentColor.withAlphaComponent(0.8)
        ]))
        let shortSummary = summary.count > 50 ? String(summary.prefix(47)) + "..." : summary
        attr.append(NSAttributedString(string: "\(shortSummary)\n", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: dimColor
        ]))
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    func appendToolResult(summary: String, isError: Bool) {
        let color = isError ? errorRed : successGreen
        let icon = isError ? "✗" : "✓"
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: " \(icon) ", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: color
        ]))
        if !summary.isEmpty {
            let short = summary.count > 60 ? String(summary.prefix(57)) + "..." : summary
            attr.append(NSAttributedString(string: "\(short)\n", attributes: [
                .font: Self.pixelFontSmall, .foregroundColor: dimColor
            ]))
        } else {
            attr.append(NSAttributedString(string: "\n", attributes: [:]))
        }
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    /// Append ambient chat (from cheap model)
    func appendAmbient(_ text: String) {
        ensureNewline()
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "💭 ", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: accentColor.withAlphaComponent(0.6)
        ]))
        attr.append(NSAttributedString(string: "\(text)\n", attributes: [
            .font: Self.pixelFontSmall, .foregroundColor: dimColor
        ]))
        textView.textStorage?.append(attr)
        scrollToBottom()
    }

    func replayHistory(_ messages: [ClaudeSession.Message]) {
        textView.textStorage?.setAttributedString(NSAttributedString(string: ""))
        appendSystem("[ PIX TERMINAL v1.0 ]")
        for msg in messages {
            switch msg.role {
            case .user: appendUser(msg.text)
            case .assistant:
                let prefix = NSMutableAttributedString()
                prefix.append(NSAttributedString(string: "PIX ", attributes: [.font: Self.pixelFontBold, .foregroundColor: accentColor]))
                prefix.append(NSAttributedString(string: "▸ ", attributes: [.font: Self.pixelFont, .foregroundColor: accentColor.withAlphaComponent(0.5)]))
                textView.textStorage?.append(prefix)
                textView.textStorage?.append(renderMarkdown(msg.text + "\n"))
            case .error: appendError(msg.text)
            case .toolUse:
                textView.textStorage?.append(NSAttributedString(string: " ⚡ \(msg.text)\n", attributes: [.font: Self.pixelFontSmall, .foregroundColor: accentColor.withAlphaComponent(0.7)]))
            case .toolResult:
                let isErr = msg.text.hasPrefix("ERROR:")
                textView.textStorage?.append(NSAttributedString(string: " \(isErr ? "✗" : "✓") \(msg.text)\n", attributes: [.font: Self.pixelFontSmall, .foregroundColor: isErr ? errorRed : successGreen]))
            }
        }
        scrollToBottom()
    }

    // MARK: - Helpers

    private func ensureNewline() {
        if let s = textView.textStorage, s.length > 0, !s.string.hasSuffix("\n") {
            s.append(NSAttributedString(string: "\n"))
        }
    }

    private func scrollToBottom() { textView.scrollToEndOfDocument(nil) }

    // MARK: - Markdown (simplified pixel style)

    private func renderMarkdown(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        var inCode = false
        var codeLines: [String] = []

        for (i, line) in lines.enumerated() {
            let suffix = i < lines.count - 1 ? "\n" : ""

            if line.hasPrefix("```") {
                if inCode {
                    let code = codeLines.joined(separator: "\n")
                    result.append(NSAttributedString(string: code + "\n", attributes: [
                        .font: Self.pixelFontSmall,
                        .foregroundColor: accentColor.withAlphaComponent(0.9),
                        .backgroundColor: NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
                    ]))
                    inCode = false; codeLines = []
                } else { inCode = true }
                continue
            }
            if inCode { codeLines.append(line); continue }

            if line.hasPrefix("# ") {
                result.append(NSAttributedString(string: "━━ \(line.dropFirst(2))\(suffix)", attributes: [.font: Self.pixelFontBold, .foregroundColor: accentColor]))
            } else if line.hasPrefix("## ") || line.hasPrefix("### ") {
                let clean = line.replacingOccurrences(of: "^#{1,3} ", with: "", options: .regularExpression)
                result.append(NSAttributedString(string: "── \(clean)\(suffix)", attributes: [.font: Self.pixelFontBold, .foregroundColor: accentColor.withAlphaComponent(0.85)]))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                result.append(NSAttributedString(string: "  ◆ ", attributes: [.font: Self.pixelFontSmall, .foregroundColor: accentColor.withAlphaComponent(0.6)]))
                result.append(renderInline(String(line.dropFirst(2)) + suffix))
            } else {
                result.append(renderInline(line + suffix))
            }
        }

        if inCode && !codeLines.isEmpty {
            result.append(NSAttributedString(string: codeLines.joined(separator: "\n") + "\n", attributes: [
                .font: Self.pixelFontSmall, .foregroundColor: accentColor.withAlphaComponent(0.9),
                .backgroundColor: NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
            ]))
        }
        return result
    }

    private func renderInline(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "`" {
                let after = text.index(after: i)
                if after < text.endIndex, let close = text[after...].firstIndex(of: "`") {
                    result.append(NSAttributedString(string: String(text[after..<close]), attributes: [
                        .font: Self.pixelFontSmall, .foregroundColor: accentColor,
                        .backgroundColor: NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
                    ]))
                    i = text.index(after: close); continue
                }
            }
            if text[i] == "*", text.index(after: i) < text.endIndex, text[text.index(after: i)] == "*" {
                let start = text.index(i, offsetBy: 2)
                if start < text.endIndex, let range = text.range(of: "**", range: start..<text.endIndex) {
                    result.append(NSAttributedString(string: String(text[start..<range.lowerBound]), attributes: [
                        .font: Self.pixelFontBold, .foregroundColor: textColor
                    ]))
                    i = range.upperBound; continue
                }
            }
            result.append(NSAttributedString(string: String(text[i]), attributes: [.font: Self.pixelFont, .foregroundColor: textColor]))
            i = text.index(after: i)
        }
        return result
    }
}
