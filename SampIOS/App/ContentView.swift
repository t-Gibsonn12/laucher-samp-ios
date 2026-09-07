import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = LauncherStore()
    @State private var probeState: ProbeState = .idle
    @State private var isLaunching = false
    @State private var showSavedServers = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case playerName
        case host
        case port
    }

    private enum ProbeState: Equatable {
        case idle
        case checking
        case online(SampServerInfo)
        case offline(String)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    clientStatus
                    connectionSection
                    probeCard
                    savedServersSection
                    launchButton
                    Text("SAMP iOS launcher • client game sẽ được tích hợp ở bước tiếp theo")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.38))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color.launcherBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSavedServers) {
                SavedServersView(store: store)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("Đóng", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.launcherBlue, .launcherPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 58, height: 58)
            .shadow(color: .launcherPurple.opacity(0.35), radius: 16, y: 7)

            VStack(alignment: .leading, spacing: 4) {
                Text("SAMP IOS")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .tracking(1.1)
                Text("Mobile multiplayer launcher")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var clientStatus: some View {
        HStack(spacing: 13) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.title2)
                .foregroundStyle(.launcherAmber)

            VStack(alignment: .leading, spacing: 3) {
                Text("CLIENT GAME")
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(.launcherAmber)
                Text("Launcher core đã sẵn sàng")
                    .font(.subheadline.weight(.semibold))
                Text("Đang chờ tích hợp binary SA-MP native")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
            Text("SETUP")
                .font(.caption2.weight(.black))
                .foregroundStyle(.launcherAmber)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.launcherAmber.opacity(0.13), in: Capsule())
        }
        .padding(16)
        .background(.launcherAmber.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.launcherAmber.opacity(0.25), lineWidth: 1)
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Kết nối máy chủ", subtitle: "Nhập thông tin để lưu và kiểm tra server")

            VStack(spacing: 0) {
                inputRow(
                    icon: "person.fill",
                    title: "Tên người chơi",
                    placeholder: "Ví dụ: NguyenDuy",
                    text: $store.playerName,
                    keyboard: .default,
                    focus: .playerName
                )

                Divider().overlay(.white.opacity(0.08))

                inputRow(
                    icon: "network",
                    title: "Địa chỉ IPv4",
                    placeholder: "127.0.0.1",
                    text: $store.serverHost,
                    keyboard: .numbersAndPunctuation,
                    focus: .host
                )

                Divider().overlay(.white.opacity(0.08))

                inputRow(
                    icon: "number",
                    title: "Port",
                    placeholder: "7777",
                    text: $store.serverPort,
                    keyboard: .numberPad,
                    focus: .port
                )
            }
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }

            HStack(spacing: 10) {
                Button {
                    saveServer()
                } label: {
                    Label("Lưu server", systemImage: "bookmark.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.7))

                Button {
                    showSavedServers = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.headline.weight(.bold))
                        .frame(width: 48, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.7))
                .accessibilityLabel("Server đã lưu")
            }
        }
    }

    private var probeCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("TRẠNG THÁI SERVER")
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Button {
                    checkServer()
                } label: {
                    if probeState == .checking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.75))
                .disabled(probeState == .checking)
            }

            switch probeState {
            case .idle:
                statusLine(icon: "dot.radiowaves.left.and.right", color: .white.opacity(0.45), title: "Chưa kiểm tra", detail: "Nhấn nút làm mới để gửi truy vấn SA-MP")
            case .checking:
                statusLine(icon: "antenna.radiowaves.left.and.right", color: .launcherBlue, title: "Đang kiểm tra...", detail: "Đang chờ phản hồi UDP từ server")
            case .online(let info):
                statusLine(
                    icon: "checkmark.circle.fill",
                    color: .launcherGreen,
                    title: info.name ?? "Server đang online",
                    detail: "\(info.players)/\(info.maxPlayers) người chơi"
                )
            case .offline(let message):
                statusLine(icon: "xmark.circle.fill", color: .launcherRed, title: "Không kết nối được", detail: message)
            }
        }
        .padding(16)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var savedServersSection: some View {
        if let profile = store.savedServers.first {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("GẦN ĐÂY")
                        .font(.caption.weight(.black))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button("Xem tất cả") {
                        showSavedServers = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.launcherBlue)
                }

                Button {
                    store.select(profile)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .foregroundStyle(.launcherBlue)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(profile.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(profile.endpointLabel)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(14)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var launchButton: some View {
        Button {
            launchGame()
        } label: {
            HStack(spacing: 10) {
                if isLaunching {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isLaunching ? "ĐANG CHUẨN BỊ..." : "VÀO GAME")
                    .font(.headline.weight(.black))
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
        }
        .buttonStyle(.borderedProminent)
        .tint(.launcherPurple)
        .disabled(isLaunching || !store.isFormValid)
        .opacity(store.isFormValid ? 1 : 0.5)
    }

    private func inputRow(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        focus: FocusField
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.launcherBlue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                TextField(placeholder, text: text)
                    .font(.body.weight(.semibold))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: focus)
                    .submitLabel(focus == .port ? .done : .next)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }

    private func statusLine(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
            }
            Spacer()
        }
    }

    private func saveServer() {
        guard store.saveCurrentServer() != nil else {
            presentAlert(title: "Chưa thể lưu", message: store.validationMessage() ?? "Thông tin server chưa hợp lệ.")
            return
        }

        presentAlert(title: "Đã lưu server", message: "Thông tin server đã được lưu trên thiết bị.")
    }

    private func checkServer() {
        guard let endpoint = store.currentEndpoint else {
            probeState = .offline(store.validationMessage() ?? "Địa chỉ server chưa hợp lệ.")
            return
        }

        probeState = .checking
        Task {
            do {
                let info = try await SampServerProbe().check(host: endpoint.host, port: endpoint.port)
                probeState = .online(info)
            } catch {
                probeState = .offline(error.localizedDescription)
            }
        }
    }

    private func launchGame() {
        guard let endpoint = store.currentEndpoint else {
            presentAlert(title: "Thiếu thông tin", message: store.validationMessage() ?? "Kiểm tra lại cấu hình server.")
            return
        }

        let name = store.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            presentAlert(title: "Thiếu tên người chơi", message: "Nhập tên trước khi vào game.")
            return
        }

        store.saveCurrentServer()
        isLaunching = true
        Task {
            defer { isLaunching = false }
            do {
                try await GameClientBridge().launch(
                    configuration: GameLaunchConfiguration(playerName: name, endpoint: endpoint)
                )
            } catch {
                presentAlert(title: "Chưa thể vào game", message: error.localizedDescription)
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.black))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.48))
        }
    }
}

private struct SavedServersView: View {
    @ObservedObject var store: LauncherStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.savedServers.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "server.rack")
                            .font(.largeTitle)
                        Text("Chưa có server")
                            .font(.headline)
                        Text("Lưu một server từ màn hình chính để truy cập nhanh.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(store.savedServers) { profile in
                        Button {
                            store.select(profile)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(profile.endpointLabel)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: store.remove)
                }
            }
            .navigationTitle("Server đã lưu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}

private extension Color {
    static let launcherBackground = Color(red: 0.035, green: 0.045, blue: 0.09)
    static let launcherBlue = Color(red: 0.25, green: 0.58, blue: 1.0)
    static let launcherPurple = Color(red: 0.48, green: 0.29, blue: 0.98)
    static let launcherAmber = Color(red: 1.0, green: 0.68, blue: 0.25)
    static let launcherGreen = Color(red: 0.25, green: 0.85, blue: 0.55)
    static let launcherRed = Color(red: 1.0, green: 0.35, blue: 0.35)
}
