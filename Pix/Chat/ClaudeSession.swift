import Foundation

class ClaudeSession {
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var lineBuffer = ""
    private(set) var isRunning = false
    private(set) var isBusy = false
    private static var claudePath: String?
    private static var shellEnvironment: [String: String]?

    var workingDirectory: URL?

    var onText: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onToolUse: ((String, [String: Any]) -> Void)?
    var onToolResult: ((String, Bool) -> Void)?
    var onSessionReady: (() -> Void)?
    var onTurnComplete: (() -> Void)?
    var onProcessExit: (() -> Void)?

    struct Message {
        enum Role { case user, assistant, error, toolUse, toolResult }
        let role: Role
        let text: String
    }
    private static let maxHistory = 200
    var history: [Message] = []

    private func appendHistory(_ msg: Message) {
        history.append(msg)
        if history.count > Self.maxHistory {
            history.removeFirst()
        }
    }

    // MARK: - Process Lifecycle

    static func resolveClaudePath(completion: @escaping (String?) -> Void) {
        if let cached = claudePath, shellEnvironment != nil {
            completion(cached)
            return
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-l", "-i", "-c", "echo '---ENV_START---' && env && echo '---ENV_END---'"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        proc.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                if let startRange = output.range(of: "---ENV_START---\n"),
                   let endRange = output.range(of: "\n---ENV_END---") {
                    let envString = String(output[startRange.upperBound..<endRange.lowerBound])
                    var env: [String: String] = [:]
                    for line in envString.components(separatedBy: "\n") {
                        if let eqRange = line.range(of: "=") {
                            let key = String(line[line.startIndex..<eqRange.lowerBound])
                            let value = String(line[eqRange.upperBound...])
                            env[key] = value
                        }
                    }
                    shellEnvironment = env
                }

                let home = FileManager.default.homeDirectoryForCurrentUser.path
                let searchPaths = [
                    "\(home)/.local/bin/claude",
                    "\(home)/.claude/local/bin/claude",
                    "/usr/local/bin/claude",
                    "/opt/homebrew/bin/claude"
                ]

                if let shellPath = shellEnvironment?["PATH"] {
                    for dir in shellPath.components(separatedBy: ":") {
                        let candidate = "\(dir)/claude"
                        if FileManager.default.isExecutableFile(atPath: candidate) {
                            claudePath = candidate
                            completion(candidate)
                            return
                        }
                    }
                }

                for fallback in searchPaths {
                    if FileManager.default.isExecutableFile(atPath: fallback) {
                        claudePath = fallback
                        completion(fallback)
                        return
                    }
                }
                completion(nil)
            }
        }
        do { try proc.run() } catch {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let fallbacks = ["\(home)/.local/bin/claude", "\(home)/.claude/local/bin/claude", "/usr/local/bin/claude", "/opt/homebrew/bin/claude"]
            for fb in fallbacks {
                if FileManager.default.isExecutableFile(atPath: fb) {
                    claudePath = fb; completion(fb); return
                }
            }
            completion(nil)
        }
    }

    func start() {
        ClaudeSession.resolveClaudePath { [weak self] path in
            guard let self = self, let claudePath = path else {
                let msg = "Claude CLI not found.\n\nInstall: curl -fsSL https://claude.ai/install.sh | sh"
                self?.onError?(msg)
                self?.appendHistory(Message(role: .error, text: msg))
                return
            }
            self.launchProcess(claudePath: claudePath)
        }
    }

    private func launchProcess(claudePath: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: claudePath)
        proc.arguments = [
            "-p",
            "--output-format", "stream-json",
            "--input-format", "stream-json",
            "--verbose",
            "--model", "claude-sonnet-4-6",
            "--dangerously-skip-permissions"
        ]
        proc.currentDirectoryURL = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser

        var env = ClaudeSession.shellEnvironment ?? ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let essentialPaths = ["\(home)/.local/bin", "\(home)/.local/share/claude/versions", "/usr/local/bin", "/opt/homebrew/bin"]
        let currentPath = env["PATH"] ?? "/usr/bin:/bin"
        let missing = essentialPaths.filter { !currentPath.contains($0) }
        if !missing.isEmpty { env["PATH"] = (missing + [currentPath]).joined(separator: ":") }
        env["TERM"] = "dumb"
        proc.environment = env

        let inPipe = Pipe(); let outPipe = Pipe(); let errPipe = Pipe()
        proc.standardInput = inPipe; proc.standardOutput = outPipe; proc.standardError = errPipe

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false; self?.isBusy = false; self?.onProcessExit?()
            }
        }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { self?.processOutput(text) }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { self?.onError?(text) }
        }

        do {
            try proc.run()
            process = proc; inputPipe = inPipe; outputPipe = outPipe; errorPipe = errPipe; isRunning = true
        } catch {
            let msg = "Failed to launch Claude CLI: \(error.localizedDescription)"
            onError?(msg); appendHistory(Message(role: .error, text: msg))
        }
    }

    func send(message: String) {
        guard isRunning, let pipe = inputPipe else { return }
        isBusy = true
        appendHistory(Message(role: .user, text: message))
        let payload: [String: Any] = ["type": "user", "message": ["role": "user", "content": message]]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonStr = String(data: data, encoding: .utf8) else { return }
        pipe.fileHandleForWriting.write((jsonStr + "\n").data(using: .utf8)!)
    }

    func terminate() {
        process?.terminate(); isRunning = false
    }

    // MARK: - NDJSON Parsing

    private func processOutput(_ text: String) {
        lineBuffer += text
        while let range = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[lineBuffer.startIndex..<range.lowerBound])
            lineBuffer = String(lineBuffer[range.upperBound...])
            if !line.isEmpty { parseLine(line) }
        }
    }

    private func parseLine(_ line: String) {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let type = json["type"] as? String ?? ""

        switch type {
        case "system":
            if (json["subtype"] as? String) == "init" { onSessionReady?() }

        case "assistant":
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    let bt = block["type"] as? String ?? ""
                    if bt == "text", let text = block["text"] as? String {
                        onText?(text)
                    } else if bt == "tool_use" {
                        let toolName = block["name"] as? String ?? "Tool"
                        let input = block["input"] as? [String: Any] ?? [:]
                        appendHistory(Message(role: .toolUse, text: "\(toolName)"))
                        onToolUse?(toolName, input)
                    }
                }
            }

        case "user":
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content where block["type"] as? String == "tool_result" {
                    let isError = block["is_error"] as? Bool ?? false
                    var summary = ""
                    if let ri = json["tool_use_result"] as? [String: Any],
                       let file = ri["file"] as? [String: Any],
                       let path = file["filePath"] as? String {
                        summary = path
                    } else if let s = block["content"] as? String {
                        summary = String(s.prefix(80))
                    }
                    appendHistory(Message(role: .toolResult, text: isError ? "ERROR: \(summary)" : summary))
                    onToolResult?(summary, isError)
                }
            }

        case "result":
            isBusy = false
            if let result = json["result"] as? String, !result.isEmpty {
                appendHistory(Message(role: .assistant, text: result))
            }
            onTurnComplete?()

        default: break
        }
    }
}
