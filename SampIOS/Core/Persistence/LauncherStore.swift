import Combine
import Foundation

@MainActor
final class LauncherStore: ObservableObject {
    @Published var playerName: String {
        didSet { persist() }
    }

    @Published var serverHost: String {
        didSet { persist() }
    }

    @Published var serverPort: String {
        didSet { persist() }
    }

    @Published private(set) var savedServers: [ServerProfile] {
        didSet { persist() }
    }

    @Published private(set) var selectedServerID: UUID?

    private let defaults: UserDefaults
    private let storageKey = "samp-ios.launcher-state"

    private struct PersistedState: Codable {
        var playerName: String
        var serverHost: String
        var serverPort: String
        var savedServers: [ServerProfile]
        var selectedServerID: UUID?
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.playerName = ""
        self.serverHost = ""
        self.serverPort = "7777"
        self.savedServers = []
        self.selectedServerID = nil
        load()
    }

    var currentEndpoint: SampEndpoint? {
        SampEndpoint(host: serverHost, portText: serverPort)
    }

    var isFormValid: Bool {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= 24 && currentEndpoint != nil
    }

    func validationMessage() -> String? {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "Nhập tên người chơi trước."
        }
        if trimmedName.count > 24 {
            return "Tên người chơi tối đa 24 ký tự."
        }
        if currentEndpoint == nil {
            return "Địa chỉ server hoặc port chưa hợp lệ."
        }
        return nil
    }

    @discardableResult
    func saveCurrentServer() -> ServerProfile? {
        guard let endpoint = currentEndpoint else { return nil }

        let fallbackName = "Server \(endpoint.host)"
        let profileName = savedServers.first(where: {
            $0.host == endpoint.host && $0.port == endpoint.port
        })?.name ?? fallbackName

        let profile = ServerProfile(
            name: profileName,
            host: endpoint.host,
            port: endpoint.port,
            lastUsed: Date()
        )

        savedServers.removeAll { $0.host == profile.host && $0.port == profile.port }
        savedServers.insert(profile, at: 0)
        selectedServerID = profile.id
        persist()
        return profile
    }

    func select(_ profile: ServerProfile) {
        serverHost = profile.host
        serverPort = String(profile.port)
        selectedServerID = profile.id
        persist()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            savedServers.remove(at: index)
        }
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            return
        }

        playerName = state.playerName
        serverHost = state.serverHost
        serverPort = state.serverPort
        savedServers = state.savedServers
        selectedServerID = state.selectedServerID
    }

    private func persist() {
        let state = PersistedState(
            playerName: playerName,
            serverHost: serverHost,
            serverPort: serverPort,
            savedServers: savedServers,
            selectedServerID: selectedServerID
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
