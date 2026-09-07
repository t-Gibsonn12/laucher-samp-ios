import Foundation
import Network

struct SampServerInfo: Equatable {
    let players: Int
    let maxPlayers: Int
    let name: String?
    let latencyMilliseconds: Int?

    init(players: Int, maxPlayers: Int, name: String?, latencyMilliseconds: Int? = nil) {
        self.players = players
        self.maxPlayers = maxPlayers
        self.name = name
        self.latencyMilliseconds = latencyMilliseconds
    }
}

enum SampProbeError: LocalizedError {
    case invalidIPv4
    case timeout
    case connectionFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidIPv4:
            return "Kiểm tra server hiện cần địa chỉ IPv4, ví dụ 127.0.0.1."
        case .timeout:
            return "Không nhận được phản hồi từ server trong 3 giây."
        case .connectionFailed(let message):
            return "Không thể gửi truy vấn UDP: \(message)"
        case .invalidResponse:
            return "Server có phản hồi nhưng không đúng định dạng SA-MP."
        }
    }
}

final class SampServerProbe {
    private let queue = DispatchQueue(label: "samp-ios.server-probe")

    func check(host: String, port: UInt16) async throws -> SampServerInfo {
        guard let ipBytes = SampEndpoint.ipv4Octets(from: host) else {
            throw SampProbeError.invalidIPv4
        }

        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw SampProbeError.connectionFailed("port không hợp lệ")
        }

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: endpointPort,
            using: .udp
        )
        let packet = SampProtocol.makeInfoQuery(ipv4: ipBytes, port: port)
        let requestStartedAt = Date()

        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let lock = NSLock()
                var finished = false

                let finish: (Result<SampServerInfo, Error>) -> Void = { result in
                    lock.lock()
                    guard !finished else {
                        lock.unlock()
                        return
                    }
                    finished = true
                    lock.unlock()

                    connection.cancel()
                    continuation.resume(with: result)
                }

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        connection.send(content: packet, completion: .contentProcessed { error in
                            if let error {
                                finish(.failure(SampProbeError.connectionFailed(error.localizedDescription)))
                                return
                            }

                            connection.receiveMessage { data, _, _, error in
                                if let error {
                                    finish(.failure(SampProbeError.connectionFailed(error.localizedDescription)))
                                } else if let data, let info = SampProtocol.parseInfoResponse(data) {
                                    let elapsed = Date().timeIntervalSince(requestStartedAt)
                                    let measuredInfo = SampServerInfo(
                                        players: info.players,
                                        maxPlayers: info.maxPlayers,
                                        name: info.name,
                                        latencyMilliseconds: max(0, Int((elapsed * 1_000).rounded()))
                                    )
                                    finish(.success(measuredInfo))
                                } else {
                                    finish(.failure(SampProbeError.invalidResponse))
                                }
                            }
                        })
                    case .failed(let error):
                        finish(.failure(SampProbeError.connectionFailed(error.localizedDescription)))
                    default:
                        break
                    }
                }

                connection.start(queue: queue)
                queue.asyncAfter(deadline: .now() + 3) {
                    finish(.failure(SampProbeError.timeout))
                }
            }
        }, onCancel: {
            connection.cancel()
        })
    }

}
