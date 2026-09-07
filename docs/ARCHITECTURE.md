# Kiến trúc và tiêu chí hoàn thiện

## Mục tiêu sản phẩm

Một IPA generic: người chơi chọn hoặc nhập IPv4 + port của bất kỳ server
SA-MP/open.mp nào mà client tương thích, xem trạng thái và vào game. Launcher
không được gắn với một server cụ thể.

## Ba lớp bắt buộc

| Lớp | Trách nhiệm | Trạng thái |
| --- | --- | --- |
| Launcher | cấu hình người chơi, server list, UDP query, chẩn đoán | đang triển khai và test được |
| Client adapter | chuyển `playerName`, `host`, `port`, data directory vào game runtime | cần client iOS hợp pháp |
| Game client | render GTA, cảm ứng, âm thanh, RakNet, SA-MP RPC/sync/UI | chưa có trong repo |

## Vì sao build xanh chưa phải chơi được

Build xanh chỉ xác minh Swift/Xcode tạo được một app ARM64 và IPA có cấu trúc
hợp lệ. Nó không thể xác minh render thế giới GTA, kết nối RakNet hay xử lý
SA-MP RPC khi không có game client. Bản cũ gây nhầm lẫn vì có nút vào game dù
bridge được để trống; từ mốc này, trạng thái đó được nêu rõ và có test riêng
cho phần launcher.

## Tiêu chí nghiệm thu launcher

1. Cài IPA đã ký, app mở trên iOS 16 trở lên.
2. Nhập IPv4/port hợp lệ; app chặn host không phải IPv4 và port 0.
3. Một server SA-MP/open.mp online phản hồi `SAMP i`; app hiển thị tên, người
   chơi và thời gian UDP.
4. Server bị tắt/sai port phản hồi bằng lỗi timeout, không treo app.
5. Server đã lưu còn tồn tại sau khi tắt/mở app.
6. CI build packet test target, build release, kiểm tra `Info.plist` và `Payload/*.app`
   trong IPA trước khi phát artifact.

## Điều kiện để bắt đầu lớp game client

Chỉ bắt đầu tích hợp khi có một trong hai đầu vào:

- mã nguồn iOS/Unity/Unreal có giấy phép rõ ràng, hỗ trợ build ARM64 iOS; hoặc
- framework `.xcframework`/static library ARM64 hợp pháp cùng tài liệu API,
  quyền dùng và cách chuẩn bị game data của người sở hữu.

Không dùng IPA/binary trôi nổi, mã nguồn bị rò rỉ, hoặc đóng gói tài sản GTA vào
repo. Khi đầu vào có sẵn, adapter là nơi nhận cấu hình từ launcher; sau đó mới
lập ma trận tương thích server 0.3.7, 0.3.DL và open.mp.
