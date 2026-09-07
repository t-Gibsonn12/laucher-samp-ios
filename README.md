# SAMP iOS Launcher

Launcher native iPhone/iPad cho server SA-MP/open.mp bất kỳ. Người chơi nhập
IPv4 + port, lưu danh sách server và kiểm tra trạng thái UDP trước khi kết nối.
Không có IP nào bị hard-code.

## Trạng thái hiện tại

- Có project Xcode native và giao diện launcher dark mode.
- Lưu tên người chơi và danh sách server bằng `UserDefaults`.
- Nhập địa chỉ IPv4 + port SA-MP, không hardcode IP server.
- Gửi truy vấn `SAMP i` để kiểm tra server, đọc tên server, số người chơi và
  thời gian phản hồi UDP.
- Có unit test cho packet query, packet response và kiểm tra endpoint.
- GitHub Actions build test target, build IPA unsigned và kiểm tra cấu trúc IPA.

## Có thể test ngay

Sau khi ký IPA và cài lên iPhone, nhập một IPv4 + port server đang mở rồi bấm
biểu tượng làm mới trong mục **TRẠNG THÁI SERVER**.

- Hiện tên server, số người chơi và `UDP ... ms`: launcher đã liên lạc được với
  server từ chính iPhone.
- Hiện timeout: kiểm tra IP/port, UDP query của server, hoặc mạng điện thoại.
- Không dùng `127.0.0.1` trừ khi server chạy ngay trên iPhone đó.

Đây là test thực tế cho launcher, không phải ảnh demo.

## Ranh giới hiện tại: launcher và game client

`GameClientBridge` chưa có implementation vì repo không chứa GTA San Andreas
hoặc một SA-MP client iOS. Do đó nút **VÀO GAME** hiện phải báo rõ client chưa
được tích hợp; nó không giả vờ mở game.

Để chơi SA-MP thật trên iOS, cần một client native ARM64 có đủ ba phần:

1. runtime/render GTA có quyền sử dụng tài sản game;
2. networking SA-MP/open.mp (RakNet, RPC, sync, dialogs, TextDraw, input...);
3. adapter nhận player name, host, port từ launcher rồi mở game scene.

Không đưa file game/binary có bản quyền hoặc client không rõ nguồn vào repo.
Khi có một client iOS hợp pháp (mã nguồn hoặc framework được cấp quyền), thay
`GameClientBridge.launch` bằng adapter của client đó. Mọi server mà client hỗ
trợ đều sẽ nhận được host/port do người chơi nhập, không cần build IPA riêng.

## Mở và build trên Mac

1. Mở `SampIOS.xcodeproj` bằng Xcode.
2. Chọn scheme `SampIOS` và một thiết bị/simulator.
3. Đổi `PRODUCT_BUNDLE_IDENTIFIER` sang bundle ID của bạn.
4. Chọn Apple Team nếu muốn cài trực tiếp lên iPhone.
5. Build bằng `⌘B`.

## Build từ PC thông qua GitHub Actions

Vào tab **Actions** → workflow **Build iOS** → **Run workflow**. Runner macOS
trên GitHub sẽ build ra artifact `SampIOS-unsigned.ipa`.

IPA unsigned là artifact kiểm tra build; để cài lên iPhone cần ký app hợp lệ.
Không cần Mac để tải artifact hoặc ký bằng eSign trên iPhone.

## Điểm tích hợp client game khi đã có nguồn hợp pháp

`SampIOS/Core/Game/GameClientBridge.swift` là adapter tách khỏi UI. Khi có
client game thật, thay implementation `launch` bằng API của client và truyền
vào:

- tên người chơi;
- host server người chơi nhập;
- port server người chơi nhập;
- thư mục/data game đã được chuẩn bị trong sandbox.

Launcher chỉ quản lý cấu hình và điều hướng; phần render GTA, networking
SA-MP, input cảm ứng và lifecycle game phải nằm trong client game native.
