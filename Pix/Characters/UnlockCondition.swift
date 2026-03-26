import Foundation

enum UnlockCondition {
    case defaultUnlocked
    case chatCount(Int)
    case timeUsed(hours: Double)
    case easterEgg(String)

    func isMet(chatCount: Int, hoursUsed: Double, easterEggs: Set<String>) -> Bool {
        switch self {
        case .defaultUnlocked: return true
        case .chatCount(let n): return chatCount >= n
        case .timeUsed(let h): return hoursUsed >= h
        case .easterEgg(let keyword): return easterEggs.contains(keyword)
        }
    }
}
