import XCTest
@testable import SampIOS

final class SampProtocolTests: XCTestCase {
    func testInfoQueryContainsRequiredHeaderAddressPortAndOpcode() {
        let packet = SampProtocol.makeInfoQuery(ipv4: [192, 168, 1, 10], port: 7777)

        XCTAssertEqual(
            [UInt8](packet),
            [0x53, 0x41, 0x4D, 0x50, 192, 168, 1, 10, 0x61, 0x1E, 0x69]
        )
    }

    func testInfoResponseParsesServerNameAndPlayerCount() {
        let name = Array("LSRP Test Server".utf8)
        var response = Data([0x53, 0x41, 0x4D, 0x50, 127, 0, 0, 1, 0x61, 0x1E, 0x69])
        response.append(0) // password flag
        response.append(contentsOf: [42, 0])
        response.append(contentsOf: [100, 0])
        response.append(UInt8(name.count))
        response.append(contentsOf: [0, 0, 0])
        response.append(contentsOf: name)

        let info = SampProtocol.parseInfoResponse(response)

        XCTAssertEqual(info?.name, "LSRP Test Server")
        XCTAssertEqual(info?.players, 42)
        XCTAssertEqual(info?.maxPlayers, 100)
    }

    func testRejectsTruncatedOrNonSampResponse() {
        XCTAssertNil(SampProtocol.parseInfoResponse(Data([0x53, 0x41, 0x4D, 0x50])))
        XCTAssertNil(SampProtocol.parseInfoResponse(Data(repeating: 0, count: 20)))
    }

    func testEndpointOnlyAcceptsIPv4AndValidPort() {
        XCTAssertNotNil(SampEndpoint(host: "104.234.180.152", portText: "7777"))
        XCTAssertNil(SampEndpoint(host: "server.example.com", portText: "7777"))
        XCTAssertNil(SampEndpoint(host: "300.1.1.1", portText: "7777"))
        XCTAssertNil(SampEndpoint(host: "104.234.180.152", portText: "0"))
    }
}
