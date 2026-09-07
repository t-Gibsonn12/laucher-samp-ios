import Foundation

/// Binary helpers for the public SA-MP/open.mp UDP query protocol.
///
/// This component intentionally contains only read-only server queries. It is
/// separate from the game client protocol so it can be tested without a GTA
/// runtime or a connected game server.
enum SampProtocol {
    static func makeInfoQuery(ipv4: [UInt8], port: UInt16) -> Data {
        precondition(ipv4.count == 4, "A SA-MP query requires four IPv4 octets.")

        var packet = Data([0x53, 0x41, 0x4D, 0x50]) // SAMP
        packet.append(contentsOf: ipv4)
        packet.append(UInt8(port & 0xFF))
        packet.append(UInt8((port >> 8) & 0xFF))
        packet.append(0x69) // i = server information
        return packet
    }

    static func parseInfoResponse(_ data: Data) -> SampServerInfo? {
        let bytes = [UInt8](data)

        // SAMP + IPv4 + port + opcode + password + players + maxPlayers.
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

            guard nameLength >= 0, nameEnd <= bytes.count else {
                return nil
            }

            serverName = String(bytes: bytes[nameStart..<nameEnd], encoding: .utf8)
        }

        return SampServerInfo(players: players, maxPlayers: maxPlayers, name: serverName)
    }
}
