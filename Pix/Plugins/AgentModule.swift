import Foundation

protocol AgentModule: AnyObject {
    var id: String { get }
    var name: String { get }
    var isTickable: Bool { get }
    var isActive: Bool { get set }

    func onActivate(character: FireflyCharacter)
    func onDeactivate()
    func onTick(deltaTime: CFTimeInterval)
    func onChatMessage(message: String) -> String?
}

extension AgentModule {
    var isTickable: Bool { false }
    func onTick(deltaTime: CFTimeInterval) {}
    func onChatMessage(message: String) -> String? { nil }
}

class AgentModuleRegistry {
    private(set) var modules: [AgentModule] = []

    var activeModules: [AgentModule] {
        modules.filter { $0.isActive }
    }

    func register(_ module: AgentModule) {
        modules.append(module)
    }

    func toggle(moduleId: String) {
        guard let mod = modules.first(where: { $0.id == moduleId }) else { return }
        mod.isActive.toggle()
        if !mod.isActive { mod.onDeactivate() }
    }
}
