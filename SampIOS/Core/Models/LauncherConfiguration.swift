import Foundation

struct SampEndpoint: Equatable {
    let host: String
    let port: UInt16

    init?(host: String, portText: String) {
        let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPort = portText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedHost.isEmpty,
              Self.ipv4Octets(from: normalizedHost) != nil,
              let port = UInt16(normalizedPort),
              port > 0 else {
            return nil
        }

        self.host = normalizedHost
        self.port = port
    }

    static func ipv4Octets(from host: String) -> [UInt8]? {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }

        let values = parts.compactMap { UInt8($0) }
        return values.count == 4 ? values : nil
    }
}

struct GameLaunchConfiguration: Equatable {
    let playerName: String
    let endpoint: SampEndpoint
}
