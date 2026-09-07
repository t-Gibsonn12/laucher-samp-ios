import Foundation

struct ServerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var host: String
    var port: UInt16
    var lastUsed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: UInt16,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.lastUsed = lastUsed
    }

    var endpointLabel: String {
        "\(host):\(port)"
    }
}
