import Foundation

enum GameClientError: LocalizedError {
    case clientNotIntegrated

    var errorDescription: String? {
        switch self {
        case .clientNotIntegrated:
            return "Launcher đã sẵn sàng, nhưng repo chưa có binary/source của SA-MP client để khởi chạy game."
        }
    }
}

@MainActor
final class GameClientBridge {
    func launch(configuration: GameLaunchConfiguration) async throws {
        _ = configuration

        // TODO: thay đoạn này bằng adapter của client game native.
        // Client thật phải được build/link vào target trước khi gọi API này.
        throw GameClientError.clientNotIntegrated
    }
}
