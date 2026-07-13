# Hướng dẫn cài đặt & Xử lý lỗi Gatekeeper trên macOS

[🇬🇧 English Version](INSTALLATION_EN.md)

Tài liệu này hướng dẫn cách cài đặt ứng dụng PasteHub và cách xử lý các cảnh báo bảo mật Gatekeeper của macOS đối với các ứng dụng chưa ký số.

## Yêu cầu hệ thống

Trước khi cài đặt, hãy đảm bảo máy tính Mac của bạn đáp ứng các yêu cầu sau:
- **macOS 13 Ventura trở lên** (bắt buộc để sử dụng API `SMAppService` phục vụ tính năng khởi chạy cùng hệ thống).
- **Khoảng 20 MB dung lượng ổ đĩa trống** (dung lượng thực tế có thể tăng lên tùy thuộc vào số lượng và dung lượng hình ảnh được lưu trong lịch sử clipboard).

---

## ⚠️ Mở ứng dụng PasteHub trên macOS (Cảnh báo chưa ký số)

PasteHub là ứng dụng **miễn phí và mã nguồn mở**, được biên dịch và phân phối mà không sử dụng chứng chỉ trả phí từ chương trình Apple Developer. Vì lý do này, trình bảo mật Gatekeeper của macOS sẽ chặn ứng dụng khi khởi chạy lần đầu tiên. Đây là cơ chế bảo mật bình thường của hệ điều hành và **không** đồng nghĩa với việc ứng dụng có chứa mã độc hại. Bạn có thể tự kiểm tra toàn bộ mã nguồn của dự án này.

Khi mở ứng dụng lần đầu, bạn có thể gặp các cảnh báo sau:
- *"PasteHub.app" bị lỗi và không thể mở. Bạn nên chuyển tệp này vào Thùng rác.*
- *"PasteHub.app" không thể mở vì nhà phát triển không thể được xác minh.*

Để mở PasteHub một cách an toàn, bạn có thể thực hiện theo một trong ba phương pháp dưới đây:

### Phương pháp 1: Nhấp chuột phải để mở (Khuyên dùng - Đơn giản nhất)
Đây là cách dễ thực hiện nhất và không cần mở Terminal:
1. Tìm tệp `PasteHub.app` trong Finder (thông thường nằm trong thư mục `/Applications`).
2. **Nhấp chuột phải** (hoặc nhấn giữ phím Control và click chuột) vào biểu tượng ứng dụng → Chọn **Open** (Mở).
3. Một hộp thoại xác nhận sẽ xuất hiện. Nhấp chọn nút **Open** (Mở) một lần nữa để xác nhận.
4. Bạn chỉ cần thực hiện việc này một lần duy nhất. Những lần khởi chạy sau, bạn có thể mở bình thường bằng cách nhấp đúp chuột.

### Phương pháp 2: Cho phép chạy từ Cấu hình Hệ thống
Nếu việc nhấp đúp chuột đã chặn ứng dụng, bạn có thể cấp quyền chạy ứng dụng trong phần Cấu hình Hệ thống:
1. Hãy thử nhấp đúp để mở PasteHub một lần để macOS ghi nhận lượt thử mở ứng dụng bị chặn.
2. Mở **System Settings** (Cấu hình Hệ thống) → Chọn mục **Privacy & Security** (Quyền riêng tư & Bảo mật).
3. Cuộn xuống phần *Security* (Bảo mật) và tìm dòng thông báo: *"PasteHub.app" was blocked from use because it is not from an identified developer*.
4. Nhấp chọn nút **Open Anyway** (Vẫn mở).

### Phương pháp 3: Xóa cờ kiểm duyệt (Quarantine flag) bằng Terminal
Nếu macOS báo tệp tin bị "hỏng/damaged" và các cách trên không hoạt động, đó là do trình duyệt web đã tự động gắn cờ kiểm duyệt vào tệp tin khi tải về. Bạn có thể gỡ bỏ cờ này bằng cách:
1. Mở ứng dụng **Terminal** trên macOS.
2. Chạy câu lệnh sau:
   ```bash
   xattr -cr /Applications/PasteHub.app
   ```
3. Khởi chạy lại PasteHub bình thường bằng cách nhấp đúp chuột.

---

## Câu hỏi thường gặp

### Tại sao ứng dụng PasteHub không được ký số/notarized?
Apple yêu cầu lập trình viên phải trả mức phí duy trì **$99/năm** cho tài khoản Apple Developer để được ký số và chứng thực ứng dụng tự động, giúp loại bỏ các thông báo cảnh báo bảo mật trên. Vì PasteHub là một dự án mã nguồn mở, phi thương mại phục vụ cộng đồng, chúng tôi hiện chưa đăng ký gói trả phí này.

Nếu bạn muốn đóng góp kinh phí để ký số ứng dụng hoặc phát triển tính năng, bạn có thể gửi Pull Request hoặc liên hệ qua GitHub của dự án.
