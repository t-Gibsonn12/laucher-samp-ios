import Foundation

struct SampEndpoint: Equatable {
    let host: String
    let port: UInt16

    init?(host: String, portText: String) {
        let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPort = portText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedHost.isEmpty,
              let port = UInt16(normalizedPort),
              port > 0 else {
            return nil
        }

        self.host = normalizedHost
        self.port = port
    }
}

struct GameLaunchConfiguration: Equatable {
    let playerName: String
    let endpoint: SampEndpoint
}
