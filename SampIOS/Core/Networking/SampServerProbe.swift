import Foundation
import Network

struct SampServerInfo: Equatable {
    let players: Int
    let maxPlayers: Int
    let name: String?
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
        guard let ipBytes = Self.ipv4Bytes(from: host) else {
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
        let packet = Self.makeInfoQuery(ipBytes: ipBytes, port: port)

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
                                } else if let data, let info = Self.parseInfoResponse(data) {
                                    finish(.success(info))
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

    private static func makeInfoQuery(ipBytes: [UInt8], port: UInt16) -> Data {
        var packet = Data([0x53, 0x41, 0x4D, 0x50]) // SAMP
        packet.append(contentsOf: ipBytes)
        packet.append(UInt8(port & 0xFF))
        packet.append(UInt8((port >> 8) & 0xFF))
        packet.append(0x69) // i = server info
        return packet
    }

    private static func parseInfoResponse(_ data: Data) -> SampServerInfo? {
        let bytes = [UInt8](data)
        guard bytes.count >= 16,
              Array(bytes.prefix(4)) == [0x53, 0x41, 0x4D, 0x50],
              bytes[10] == 0x69 else {
            return nil
        }

        let players = Int(UInt16(bytes[12]) | (UInt16(bytes[13]) << 8))
        let maxPlayers = Int(UInt16(bytes[14]) | (UInt16(bytes[15]) << 8))

        var serverName: String?
        if bytes.count >= 20 {
            let nameLength = Int(bytes[16])
                | (Int(bytes[17]) << 8)
                | (Int(bytes[18]) << 16)
                | (Int(bytes[19]) << 24)
            let nameStart = 20
            let nameEnd = nameStart + nameLength

            if nameLength >= 0, nameEnd <= bytes.count {
                serverName = String(bytes: bytes[nameStart..<nameEnd], encoding: .utf8)
            }
        }

        return SampServerInfo(players: players, maxPlayers: maxPlayers, name: serverName)
    }

    private static func ipv4Bytes(from host: String) -> [UInt8]? {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }

        let values = parts.compactMap { UInt8($0) }
        return values.count == 4 ? values : nil
    }
}
