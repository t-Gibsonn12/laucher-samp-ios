# SAMP iOS Launcher

Nền tảng launcher native cho SA-MP trên iPhone/iPad, viết bằng SwiftUI.

Launcher này không gắn với một server cố định. Người chơi tự nhập địa chỉ
IPv4 và port của bất kỳ server SA-MP nào, sau đó có thể lưu nhiều server để
truy cập nhanh.

## Trạng thái hiện tại

- Có project Xcode native và giao diện launcher dark mode.
- Lưu tên người chơi và danh sách server bằng `UserDefaults`.
- Nhập địa chỉ IPv4 + port SA-MP, không hardcode IP server.
- Gửi truy vấn `SAMP i` để kiểm tra server và đọc số người chơi.
- Có luồng khởi chạy và điểm tích hợp `GameClientBridge`.
- Có GitHub Actions để build unsigned app trên macOS runner.

> **Quan trọng:** Repo hiện chưa chứa GTA San Andreas hoặc binary SA-MP client.
> Launcher quản lý cấu hình và kết nối generic; để vào game thật cần tích hợp
> một client game iOS đã được build thành framework/static library hoặc đưa mã
> nguồn client vào target này. Không commit file GTA hoặc tài sản có bản quyền
> vào repo.

## Mở và build trên Mac

1. Mở `SampIOS.xcodeproj` bằng Xcode.
2. Chọn scheme `SampIOS` và một thiết bị/simulator.
3. Đổi `PRODUCT_BUNDLE_IDENTIFIER` sang bundle ID của bạn.
4. Chọn Apple Team nếu muốn cài trực tiếp lên iPhone.
5. Build bằng `⌘B`.

## Build từ PC thông qua GitHub Actions

Vào tab **Actions** → workflow **Build iOS** → **Run workflow**. Runner macOS
trên GitHub sẽ build ra artifact `SampIOS-unsigned.ipa`.

IPA unsigned chỉ là artifact kiểm tra build; để cài lên iPhone cần một quy
trình sideload/ký app hợp lệ. Không cần Apple Developer để tiếp tục viết
launcher, nhưng việc cài app lên thiết bị thật vẫn phụ thuộc vào phương thức
ký mà bạn chọn.

## Điểm tích hợp client game

`SampIOS/Core/Game/GameClientBridge.swift` là adapter tách khỏi UI. Khi có
client game thật, thay implementation `launch` bằng API của client và truyền
vào:

- tên người chơi;
- host server người chơi nhập;
- port server người chơi nhập;
- thư mục/data game đã được chuẩn bị trong sandbox.

Launcher chỉ quản lý cấu hình và điều hướng; phần render GTA, networking
SA-MP, input cảm ứng và lifecycle game phải nằm trong client game native.
