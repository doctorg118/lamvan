LAM VÂN — WEBSITE KẾT NỐI SUPABASE

CÁC FILE
- index.html: cửa hàng khách hàng; đọc sản phẩm từ Supabase, giỏ hàng lưu cục bộ, tạo đơn qua RPC.
- login.html: đăng nhập bằng Supabase Auth và kiểm tra quyền admin_users.
- admin.html: quản trị sản phẩm, ảnh, tồn kho, trạng thái đơn hàng.
- supabase-config.js: điền Project URL và anon/publishable key. Không đưa service_role/secret key vào trình duyệt.
- supabase_order_rpc.sql: SQL bổ sung bắt buộc để tạo đơn hàng an toàn và cấu hình Storage ảnh.

CÀI ĐẶT
1. Mở supabase-config.js, thay YOUR_PROJECT_ID bằng Project ID (URL dạng https://PROJECT_ID.supabase.co) và thay YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY bằng anon/publishable key của dự án. Có thể tìm ở Supabase > Project Settings > API Keys. Không dùng service_role/secret key.
2. Nếu chưa chạy SQL schema cơ bản ở bước trước, chạy schema đó trước. Sau đó mở Supabase > SQL Editor, tạo query mới, dán toàn bộ supabase_order_rpc.sql và Run.
3. Trong Supabase > Authentication > Users, tạo tài khoản quản trị bằng email/mật khẩu.
4. Sao chép UUID của user vừa tạo. Trong SQL Editor chạy (thay UUID):
   insert into public.admin_users (user_id) values ('UUID-TAI-KHOAN');
   Nếu tài khoản đã có trong bảng, không cần chèn lại.
5. Chạy website qua web server/hosting (ví dụ VS Code Live Server, Netlify, Vercel hoặc hosting hiện có). Tránh mở bằng file:// nếu Auth redirect không hoạt động ổn định. Tất cả 4 file HTML/JS cần cùng thư mục.
6. Mở index.html để kiểm tra sản phẩm. Mở login.html để đăng nhập; sau khi được cấp quyền sẽ vào admin.html.

LƯU Ý
- Chỉ dùng anon/publishable key trên frontend; không bao giờ nhúng service_role/secret key.
- Nếu thêm redirect URLs trong Supabase Auth, hãy thêm URL của website/hosting của bạn tại Authentication > URL Configuration.
- SQL schema cơ bản đã tạo các bảng products, orders, admin_users và RLS. File SQL bổ sung này tạo RPC place_lamvan_order và bucket product-images cần thiết cho website.
- Tồn kho trong schema hiện là tồn kho tổng theo sản phẩm, chưa tách theo size/màu.
- Nếu website đã có dữ liệu localStorage cũ, dữ liệu đó không tự nhập vào Supabase; cần thêm sản phẩm trong trang quản trị hoặc import thủ công qua SQL.
