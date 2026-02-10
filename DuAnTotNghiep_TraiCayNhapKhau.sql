
CREATE DATABASE DuAnTotNghiep_WebsiteTraiCayNhapKhau;
GO


USE DuAnTotNghiep_WebsiteTraiCayNhapKhau;
GO




-- 2. TẠO BẢNG & RÀNG BUỘC (TABLES & CONSTRAINTS)


-- 1. Bảng ROLE (Quyền hạn)
-- Ý nghĩa: Định nghĩa các vai trò (phân quyền) trong hệ thống (VD: Admin, User, Staff, Shipper).
CREATE TABLE Role (
    id INT PRIMARY KEY IDENTITY(1,1),   -- Mã quyền (Tự động tăng)
    name VARCHAR(50) UNIQUE NOT NULL    -- Tên quyền (VD: 'ROLE_ADMIN') - Bắt buộc duy nhất.
);

-- 2. Bảng ACCOUNT (Tài khoản người dùng)
-- Ý nghĩa: Lưu thông tin đăng nhập và hồ sơ cá nhân cơ bản (trừ địa chỉ đã tách riêng).
CREATE TABLE Account (
    username VARCHAR(50) PRIMARY KEY,               -- Tên đăng nhập (Khóa chính, định danh duy nhất)
    password VARCHAR(255) NOT NULL,                 -- Mật khẩu (Lưu chuỗi mã hóa BCrypt, tuyệt đối không lưu text thường)
    fullname NVARCHAR(100) NOT NULL,                -- Họ và tên đầy đủ
    email VARCHAR(100) UNIQUE NOT NULL,             -- Email (Duy nhất, dùng để khôi phục mật khẩu)
    phone VARCHAR(20),                              -- Số điện thoại chính
    enabled BIT NOT NULL DEFAULT 1,                 -- Trạng thái (1: Hoạt động, 0: Bị khóa)
    role_id INT NOT NULL,                           -- Tài khoản này thuộc quyền nào
    FOREIGN KEY (role_id) REFERENCES Role(id)       -- Liên kết khóa ngoại tới bảng Role
);

-- 3. Bảng ADDRESS (Sổ địa chỉ) 
-- Ý nghĩa: Cho phép một người dùng lưu nhiều địa chỉ nhận hàng khác nhau (Nhà riêng, Cơ quan...).
CREATE TABLE Address (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã địa chỉ (Tự tăng)
    username VARCHAR(50) NOT NULL,                  -- Địa chỉ này thuộc về tài khoản nào
    fullname NVARCHAR(100) NOT NULL,                -- Tên người nhận hàng tại địa chỉ này
    phone VARCHAR(20) NOT NULL,                     -- Số điện thoại người nhận tại địa chỉ này
    
    -- Chia nhỏ địa chỉ để dễ quản lý phí ship hoặc thống kê vùng miền
    address_line NVARCHAR(255) NOT NULL,            -- Số nhà, tên đường cụ thể
    province NVARCHAR(100),                         -- Tỉnh/Thành phố
    district NVARCHAR(100),                         -- Quận/Huyện
    ward NVARCHAR(100),                             -- Phường/Xã
    
    is_default BIT DEFAULT 0,                       -- 1: Là địa chỉ mặc định (ưu tiên hiển thị), 0: Địa chỉ phụ
    
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE -- Xóa tài khoản thì xóa luôn danh sách địa chỉ của họ
);

-- 4. Bảng CATEGORY (Danh mục sản phẩm)
-- Ý nghĩa: Phân loại nhóm trái cây để khách hàng dễ tìm kiếm (VD: Táo, Nho, Cam quýt...).
CREATE TABLE Category (
    id INT PRIMARY KEY IDENTITY(1,1),   -- Mã danh mục (Tự tăng)
    name NVARCHAR(100) UNIQUE NOT NULL  -- Tên danh mục (Duy nhất, không trùng lặp)
);

-- 5. Bảng PRODUCT (Sản phẩm)
-- Ý nghĩa: Lưu trữ toàn bộ thông tin chi tiết về sản phẩm đang kinh doanh.
CREATE TABLE Product (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã sản phẩm (Tự tăng)
    name NVARCHAR(150) NOT NULL,                            -- Tên sản phẩm (VD: Táo Envy Mỹ)
    price DECIMAL(18, 2) CHECK (price >= 0) NOT NULL,       -- Giá bán niêm yết cho khách hàng
    description NVARCHAR(MAX) DEFAULT N'Mô tả...',          -- Bài viết mô tả chi tiết (HTML/Text)
    image VARCHAR(255),                                     -- Ảnh đại diện (Thumbnail hiển thị ở danh sách)
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,             -- Số lượng tồn kho (Hỗ trợ số lẻ 0.5kg cho cân ký)
    is_liquidation BIT NOT NULL DEFAULT 0,                  -- Cờ đánh dấu hàng thanh lý (1: Có, 0: Không)
    original_price DECIMAL(18, 2),                          -- Giá gốc/Giá thị trường (Dùng để gạch ngang hiển thị giảm giá ảo)
    discount INT DEFAULT 0 CHECK (discount >= 0 AND discount <= 100), -- % Giảm giá trực tiếp trên sản phẩm
    import_price DECIMAL(18, 2) DEFAULT 0,                  -- Giá nhập gần nhất (Trường ẩn, dùng tính lợi nhuận nội bộ)
    available BIT NOT NULL DEFAULT 1,                       -- Trạng thái kinh doanh (1: Đang bán, 0: Ngừng bán/Ẩn)
    create_date DATE DEFAULT GETDATE(),                     -- Ngày tạo sản phẩm
    category_id INT NOT NULL,                               -- Sản phẩm thuộc danh mục nào
    FOREIGN KEY (category_id) REFERENCES Category(id)       -- Liên kết khóa ngoại tới bảng Category
);

-- 6. Bảng PRODUCT_IMAGE (Thư viện ảnh)
-- Ý nghĩa: Cho phép một sản phẩm có nhiều ảnh chi tiết (góc cạnh, bao bì, giấy chứng nhận...).
CREATE TABLE Product_Image (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã hình ảnh
    product_id INT NOT NULL,                                -- Thuộc về sản phẩm nào
    image_url VARCHAR(255) NOT NULL,                        -- Đường dẫn file ảnh
    is_main BIT DEFAULT 0,                                  -- Cờ đánh dấu: 1 là ảnh chính, 0 là ảnh phụ
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE -- Nếu xóa sản phẩm thì xóa luôn các ảnh này
);

-- 7. Bảng PRODUCT_WISHLIST (Sản phẩm yêu thích)
-- Ý nghĩa: Lưu danh sách các món hàng khách quan tâm để mua sau (Wishlist).
CREATE TABLE Product_Wishlist (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã dòng yêu thích
    username VARCHAR(50) NOT NULL,                          -- Tài khoản nào bấm thích
    product_id INT NOT NULL,                                -- Thích sản phẩm nào
    create_date DATETIME DEFAULT GETDATE(),                 -- Thời điểm bấm thích
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE, -- Xóa user xóa luôn wishlist
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE,     -- Xóa sản phẩm xóa luôn trong wishlist
    CONSTRAINT UQ_Product_Wishlist UNIQUE (username, product_id) -- Ràng buộc: Mỗi người chỉ được thích 1 sản phẩm 1 lần duy nhất
);

-- 8. Bảng VOUCHER (Mã giảm giá)
-- Ý nghĩa: Quản lý các chương trình khuyến mãi, mã giảm giá cho đơn hàng.
CREATE TABLE Voucher (
    code VARCHAR(20) PRIMARY KEY,                           -- Mã Voucher (VD: TET2025) - Là khóa chính
    description NVARCHAR(255),                              -- Mô tả nội dung khuyến mãi
    
    -- Logic: Giảm theo % HOẶC Giảm theo tiền mặt. Không dùng cả 2 cùng lúc.
    discount_percent INT DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 100), -- Giảm theo % (0-100)
    discount_amount DECIMAL(18,2) DEFAULT 0 CHECK (discount_amount >= 0),      -- Giảm tiền mặt
    
    -- Nếu giảm theo %, phải có mức giảm tối đa (VD: Giảm 10% nhưng tối đa chỉ giảm 50k)
    max_discount_amount DECIMAL(18,2) DEFAULT 0 CHECK (max_discount_amount >= 0),        

    min_condition DECIMAL(18,2) DEFAULT 0,                  -- Điều kiện: Giá trị đơn hàng tối thiểu để áp dụng
    start_date DATETIME,                                    -- Ngày bắt đầu hiệu lực
    end_date DATETIME,                                      -- Ngày hết hạn
    quantity INT DEFAULT 100,                               -- Số lượng mã phát hành
    active BIT DEFAULT 1,                                   -- Trạng thái (1: Kích hoạt, 0: Vô hiệu hóa)
    
    -- Constraint (Ràng buộc): Đảm bảo logic loại trừ lẫn nhau giữa % và Tiền mặt
    CONSTRAINT CK_Voucher_Method CHECK (
        (discount_percent > 0 AND discount_amount = 0) OR 
        (discount_percent = 0 AND discount_amount > 0) OR
        (discount_percent = 0 AND discount_amount = 0)
    )
);

-- 9. Bảng ORDERS (Đơn hàng)
-- Ý nghĩa: Lưu thông tin tổng quan (Header) của một đơn đặt hàng.
CREATE TABLE Orders (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã hóa đơn (Tự tăng)
    create_date DATETIME DEFAULT GETDATE(),                 -- Ngày đặt hàng
    
    -- [QUAN TRỌNG] Tại sao lưu string shipping_address ở đây mà không dùng ID Address?
    -- Vì địa chỉ trong bảng Address có thể bị user sửa/xóa sau này. 
    -- Đơn hàng lịch sử phải lưu cứng (snapshot) địa chỉ tại thời điểm đặt để đối soát vận chuyển chính xác.
    shipping_address NVARCHAR(500) NOT NULL,                -- Địa chỉ giao hàng thực tế
    
    status NVARCHAR(50) NOT NULL,                           -- Trạng thái đơn (VD: Chờ xác nhận, Đang giao, Hoàn thành...)
    notes NVARCHAR(500),                                    -- Ghi chú của khách hàng
    payment_method VARCHAR(50),                             -- Phương thức thanh toán (COD, VNPAY...)
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,         -- Tổng tiền khách phải thanh toán (Sau khi trừ KM + Ship)
    account_username VARCHAR(50) NOT NULL,                  -- Khách hàng nào đặt đơn này
    voucher_code VARCHAR(20),                               -- Mã giảm giá đã sử dụng (nếu có)
    order_code AS ('DH' + RIGHT('000000' + CAST(id AS VARCHAR(10)), 6)), -- Cột tính toán: Mã đơn hàng tự động (VD: DH000001)
    recipient_name NVARCHAR(100),                           -- Tên người nhận hàng
    recipient_phone VARCHAR(20),                            -- Số điện thoại người nhận
    shipping_fee DECIMAL(18, 2) DEFAULT 0,                  -- Phí giao hàng
    is_printed BIT DEFAULT 0,                               -- Cờ đánh dấu: Đã in hóa đơn chưa?
    export_date DATETIME,                                   -- Ngày xuất hóa đơn gần nhất
    FOREIGN KEY (account_username) REFERENCES Account(username), -- Liên kết user
    FOREIGN KEY (voucher_code) REFERENCES Voucher(code)          -- Liên kết voucher
);

-- 10. Bảng ORDER_DETAIL (Chi tiết đơn hàng)
-- Ý nghĩa: Lưu danh sách sản phẩm (Line Items) trong đơn hàng và giá bán TẠI THỜI ĐIỂM MUA.
CREATE TABLE Order_Detail (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã chi tiết
    price DECIMAL(18, 2) NOT NULL,                          -- Giá bán CHỐT lúc mua (Quan trọng để đối soát doanh thu)
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),  -- Số lượng mua (Kg)
    product_id INT NOT NULL,                                -- Mua sản phẩm nào
    order_id INT NOT NULL,                                  -- Thuộc về hóa đơn nào
    FOREIGN KEY (product_id) REFERENCES Product(id),
    FOREIGN KEY (order_id) REFERENCES Orders(id) ON DELETE CASCADE -- Xóa hóa đơn thì xóa luôn các dòng chi tiết
);

-- 11. Bảng CART (Giỏ hàng)
-- Ý nghĩa: Lưu trữ các sản phẩm khách hàng đã chọn "Thêm vào giỏ" nhưng chưa thanh toán.
-- Cấu trúc mới: Gộp Cart và CartItem thành 1 bảng duy nhất để tối ưu. Mỗi dòng là 1 sản phẩm trong giỏ của 1 user.
CREATE TABLE Cart (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã dòng giỏ hàng
    username VARCHAR(50) NOT NULL,                          -- Giỏ hàng của ai (Tài khoản nào)
    product_id INT NOT NULL,                                -- Sản phẩm muốn mua
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),  -- Số lượng bao nhiêu
    create_date DATETIME DEFAULT GETDATE(),                 -- Thời điểm thêm vào giỏ
    
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE, -- Xóa tài khoản xóa luôn giỏ hàng của họ
    FOREIGN KEY (product_id) REFERENCES Product(id),                       -- Liên kết sản phẩm
    
    -- Constraint quan trọng: Một User không thể có 2 dòng trùng 1 sản phẩm trong giỏ. 
    -- Nếu khách thêm tiếp sản phẩm đã có -> Hệ thống sẽ cập nhật số lượng (quantity) chứ không tạo dòng mới.
    CONSTRAINT UQ_Cart_User_Product UNIQUE (username, product_id)
);

-- 12. Bảng REVIEW (Đánh giá sản phẩm)
-- Ý nghĩa: Lưu đánh giá (sao, bình luận) của khách hàng sau khi mua xong.
-- Logic: Nối trực tiếp với Order_Detail để đảm bảo quy trình "Mua hàng thành công mới được đánh giá".
CREATE TABLE Review (
    id INT PRIMARY KEY IDENTITY(1,1),                           -- Mã đánh giá
    comment NVARCHAR(MAX),                                      -- Nội dung bình luận
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),    -- Số sao (chỉ nhận từ 1 đến 5)
    review_date DATETIME DEFAULT GETDATE(),                     -- Ngày đánh giá
    username VARCHAR(50) NOT NULL,                              -- Người đánh giá (Lưu để hiển thị nhanh)
    
    order_detail_id INT UNIQUE NOT NULL,                        -- Liên kết chặt với chi tiết đơn hàng. UNIQUE đảm bảo 1 lần mua chỉ đánh giá 1 lần.
    
    FOREIGN KEY (username) REFERENCES Account(username),
    FOREIGN KEY (order_detail_id) REFERENCES Order_Detail(id) ON DELETE CASCADE -- Xóa dòng đơn hàng thì mất luôn review
);

-- 13. Bảng NEWS (Tin tức - Blog)
-- Ý nghĩa: Lưu trữ các bài viết tin tức, mẹo vặt, kiến thức trái cây, bài SEO.
CREATE TABLE News (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã bài viết
    title NVARCHAR(255) NOT NULL,                           -- Tiêu đề bài viết
    content NVARCHAR(MAX) NOT NULL,                         -- Nội dung bài viết (Chứa mã HTML)
    image VARCHAR(255),                                     -- Ảnh đại diện bài viết (Thumbnail)
    create_date DATETIME DEFAULT GETDATE(),                 -- Ngày đăng
    account_username VARCHAR(50) NOT NULL,                  -- Người đăng bài (Admin/Staff)
    
    -- Các trường thống kê nhanh (Được cập nhật tự động bởi Trigger, không cần đếm thủ công mỗi lần load trang)
    like_count INT DEFAULT 0,                               -- Tổng số lượt thích
    view_count INT DEFAULT 0,                               -- Tổng số lượt xem

    FOREIGN KEY (account_username) REFERENCES Account(username)
);

-- 14. Bảng NEWS_VIEW (Lịch sử xem tin)
-- Ý nghĩa: Ghi log (lịch sử) mỗi lần có người bấm vào xem bài viết để tính view và phân tích hành vi.
CREATE TABLE News_View (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã lượt xem
    news_id INT NOT NULL,                                   -- Xem bài nào
    username VARCHAR(50),                                   -- Ai xem (Có thể NULL nếu là khách vãng lai chưa đăng nhập)
    view_date DATETIME DEFAULT GETDATE(),                   -- Thời điểm xem
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE
);

-- 15. Bảng NEWS_LIKE (Lượt thích tin tức)
-- Ý nghĩa: Lưu danh sách những người đã "thả tim" bài viết.
CREATE TABLE News_Like (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã lượt like
    news_id INT NOT NULL,                                   -- Like bài nào
    username VARCHAR(50) NOT NULL,                          -- Ai like
    like_date DATETIME DEFAULT GETDATE(),                   -- Thời điểm like
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE,
    CONSTRAINT UQ_News_Like UNIQUE (news_id, username)      -- Ràng buộc: Mỗi người chỉ được Like 1 bài 1 lần
);

-- 16. Bảng NEWS_SHARE (Lịch sử chia sẻ)
-- Ý nghĩa: Thống kê lượt chia sẻ bài viết lên các nền tảng mạng xã hội (Facebook, Zalo...).
CREATE TABLE News_Share (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã lượt share
    news_id INT NOT NULL,                                   -- Share bài nào
    username VARCHAR(50) NOT NULL,                          -- Ai share
    share_date DATETIME DEFAULT GETDATE(),                  -- Thời điểm share
    platform NVARCHAR(50),                                  -- Nền tảng chia sẻ (Facebook, Zalo, Copy Link...)
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username)
);

-- 17. Bảng NEWS_COMMENT (Bình luận tin tức)
-- Ý nghĩa: Hệ thống bình luận và trả lời bình luận (đa cấp/nested comments).
CREATE TABLE News_Comment (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã bình luận
    news_id INT NOT NULL,                                   -- Bình luận ở bài nào
    username VARCHAR(50) NOT NULL,                          -- Ai bình luận
    content NVARCHAR(MAX) NOT NULL,                         -- Nội dung bình luận
    create_date DATETIME DEFAULT GETDATE(),                 -- Thời gian
    is_visible BIT DEFAULT 1,                               -- Trạng thái hiển thị (1: Hiện, 0: Ẩn - dùng cho kiểm duyệt spam)
    parent_id INT,                                          -- Trả lời cho comment nào (NULL là comment gốc)
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username),
    FOREIGN KEY (parent_id) REFERENCES News_Comment(id)     -- Tham chiếu đệ quy chính bảng này
);

-- 18. Bảng CONTACT (Liên hệ)
-- Ý nghĩa: Lưu các tin nhắn, phản hồi từ Form liên hệ trên website (cả khách vãng lai cũng gửi được).
CREATE TABLE Contact (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã liên hệ
    full_name NVARCHAR(100) NOT NULL,                       -- Tên người gửi
    email VARCHAR(100) NOT NULL,                            -- Email phản hồi
    subject NVARCHAR(200),                                  -- Tiêu đề vấn đề
    message NVARCHAR(MAX) NOT NULL,                         -- Nội dung tin nhắn
    create_date DATETIME DEFAULT GETDATE(),                 -- Thời gian gửi
    status NVARCHAR(50) DEFAULT N'Chưa xử lý'              -- Trạng thái xử lý (Đã xem/Chưa xem/Đã trả lời)
);

-- 19. Bảng SHOP_INFO (Cấu hình Shop)
-- Ý nghĩa: Lưu các thông tin chung hiển thị ở Footer/Header (Logo, Hotline, Địa chỉ, Map...) để Admin tự chỉnh sửa không cần Code.
CREATE TABLE Shop_Info (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã cấu hình
    shop_name NVARCHAR(100) NOT NULL,                       -- Tên cửa hàng
    address NVARCHAR(255) NOT NULL,                         -- Địa chỉ hiển thị
    phone VARCHAR(20) NOT NULL,                             -- Hotline
    email VARCHAR(100) NOT NULL,                            -- Email shop
    logo_url VARCHAR(255),                                  -- Link ảnh Logo
    facebook_link VARCHAR(255),                             -- Link Fanpage
    zalo_link VARCHAR(255),                                 -- Link Zalo OA
    map_iframe NVARCHAR(MAX)                                -- Mã nhúng bản đồ Google Map
);

-- 20. Bảng STATIC_PAGE (Trang tĩnh)
-- Ý nghĩa: Quản lý nội dung các trang thông tin ít thay đổi (Giới thiệu, Chính sách, Điều khoản...).
CREATE TABLE Static_Page (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã trang
    slug VARCHAR(50) UNIQUE NOT NULL,                       -- Đường dẫn định danh (VD: 'gioi-thieu', 'chinh-sach')
    title NVARCHAR(255) NOT NULL,                           -- Tiêu đề trang
    content NVARCHAR(MAX) NOT NULL,                         -- Nội dung HTML
    image_url VARCHAR(255),                                 -- Ảnh Banner trang
    last_modified DATETIME DEFAULT GETDATE()                -- Ngày cập nhật cuối cùng
);

-- 21. Bảng SUPPLIER (Nhà cung cấp)
-- Ý nghĩa: Quản lý thông tin các đối tác cung cấp nguồn hàng đầu vào.
CREATE TABLE Supplier (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã nhà cung cấp
    name NVARCHAR(200) NOT NULL,                            -- Tên nhà cung cấp
    contact_name NVARCHAR(100),                             -- Người liên hệ đại diện
    phone VARCHAR(20),                                      -- Số điện thoại
    email VARCHAR(100),                                     -- Email
    address NVARCHAR(255),                                  -- Địa chỉ kho/văn phòng
    bank_name NVARCHAR(100),                                -- Tên ngân hàng thanh toán
    bank_account_number VARCHAR(50),                        -- Số tài khoản
    bank_account_holder NVARCHAR(100),                      -- Tên chủ tài khoản
    active BIT DEFAULT 1                                    -- Trạng thái hợp tác (1: Đang hợp tác, 0: Ngừng)
);

-- 22. Bảng IMPORT (Phiếu nhập kho)
-- Ý nghĩa: Lưu thông tin tổng quan của một lần nhập hàng (Header phiếu nhập).
CREATE TABLE Import (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã phiếu nhập
    import_date DATETIME DEFAULT GETDATE(),                 -- Ngày nhập
    supplier_id INT NOT NULL,                               -- Nhập từ nhà cung cấp nào
    account_username VARCHAR(50) NOT NULL,                  -- Nhân viên nào thực hiện nhập kho
    total_amount DECIMAL(18, 2) DEFAULT 0,                  -- Tổng tiền thanh toán cho NCC
    notes NVARCHAR(500),                                    -- Ghi chú nhập hàng
    FOREIGN KEY (supplier_id) REFERENCES Supplier(id),
    FOREIGN KEY (account_username) REFERENCES Account(username)
);

-- 23. Bảng IMPORT_DETAIL (Chi tiết nhập kho)
-- Ý nghĩa: Lưu chi tiết từng sản phẩm nhập trong phiếu. 
-- Quan trọng: Lưu unit_price (giá vốn) tại thời điểm nhập để tính toán chi phí lịch sử chính xác.
CREATE TABLE Import_Detail (
    id INT PRIMARY KEY IDENTITY(1,1),                       -- Mã chi tiết nhập
    import_id INT NOT NULL,                                 -- Thuộc phiếu nhập nào
    product_id INT NOT NULL,                                -- Nhập sản phẩm nào
    quantity DECIMAL(10, 2) NOT NULL,                       -- Số lượng nhập
    unit_price DECIMAL(18, 2) NOT NULL,                     -- Giá vốn nhập vào tại thời điểm đó (Lịch sử)
    FOREIGN KEY (import_id) REFERENCES Import(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(id)
);
GO





-- PHẦN 3: TRIGGER TỰ ĐỘNG (DATABASE TRIGGERS)

-- Trigger 1: Tự động cập nhật số lượng LIKE trong bảng News
-- Khi thêm dòng vào News_Like -> Tăng like_count
-- Khi xóa dòng khỏi News_Like -> Giảm like_count
CREATE OR ALTER TRIGGER trg_UpdateNewsLikeCount
ON News_Like
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Trường hợp 1: Có lượt Like mới (INSERT)
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE N 
        SET N.like_count = N.like_count + 1
        FROM News N 
        JOIN inserted I ON N.id = I.news_id;
    END

    -- Trường hợp 2: Có lượt Bỏ Like (DELETE)
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE N 
        SET N.like_count = N.like_count - 1
        FROM News N 
        JOIN deleted D ON N.id = D.news_id;
    END
END;
GO

-- Trigger 2: Tự động cập nhật số lượng VIEW trong bảng News
-- Khi thêm dòng vào News_View -> Tăng view_count
CREATE OR ALTER TRIGGER trg_UpdateNewsViewCount
ON News_View
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cộng dồn số lượt xem vào bảng News
    UPDATE N
    SET N.view_count = N.view_count + 1
    FROM News N
    JOIN inserted I ON N.id = I.news_id;
END;
GO

-- Trigger 3: Tự động cập nhật kho hàng và giá nhập
-- Khi nhập hàng vào Import_Detail -> Cộng tồn kho Product và Cập nhật giá vốn mới nhất
CREATE OR ALTER TRIGGER trg_UpdateStockAfterImport
ON Import_Detail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Cập nhật số lượng tồn kho (Cộng dồn số lượng vừa nhập)
    UPDATE p
    SET p.quantity = p.quantity + i.quantity
    FROM Product p
    JOIN inserted i ON p.id = i.product_id;

    -- 2. Cập nhật giá nhập mới nhất (Để tính lợi nhuận nội bộ)
    UPDATE p
    SET p.import_price = i.unit_price
    FROM Product p
    JOIN inserted i ON p.id = i.product_id;
END;
GO

-- Trigger 4: Kiểm tra điều kiện Đánh giá (Review)
-- Logic: Chỉ được đánh giá khi đơn hàng có trạng thái "Giao hàng thành công"
-- Lưu ý: Không cần check product_id nữa vì bảng Review mới đã bỏ cột này.
CREATE OR ALTER TRIGGER trg_ValidateReview
ON Review
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra trạng thái đơn hàng thông qua chuỗi liên kết: 
    -- Review -> Order_Detail -> Orders
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Order_Detail od ON i.order_detail_id = od.id
        JOIN Orders o ON od.order_id = o.id
        WHERE o.status <> N'Giao hàng thành công' -- Nếu trạng thái KHÁC thành công thì chặn
    )
    BEGIN
        ROLLBACK TRANSACTION; -- Hủy lệnh Insert
        RAISERROR (N'Lỗi: Đơn hàng chưa hoàn thành (Giao hàng thành công), bạn chưa thể đánh giá sản phẩm này!', 16, 1);
        RETURN;
    END
END;
GO


-- PHẦN 4: THỦ TỤC LƯU TRỮ (STORED PROCEDURES)

-- 1. Thủ tục: Lấy danh sách đơn hàng để xuất hóa đơn
-- Mục đích: Hỗ trợ Admin lọc đơn hàng theo ngày, trạng thái in và từ khóa để in phiếu giao hàng.
-- Lưu ý: Dữ liệu lấy từ bảng Orders (nơi lưu snapshot địa chỉ) nên việc tách bảng Address không ảnh hưởng.
CREATE OR ALTER PROCEDURE sp_GetOrdersForPrinting
    @FromDate DATETIME = NULL,        -- Từ ngày
    @ToDate DATETIME = NULL,          -- Đến ngày
    @IsPrinted BIT = NULL,            -- Trạng thái in (0: Chưa, 1: Rồi)
    @SearchKeyword NVARCHAR(100) = NULL -- Tìm theo Mã đơn hoặc Tên người nhận
AS
BEGIN
    SET NOCOUNT ON; 

    SELECT 
        o.id, 
        o.order_code, 
        o.create_date, 
        o.recipient_name, 
        o.recipient_phone, 
        o.shipping_address, 
        o.total_amount, 
        o.status, 
        o.is_printed, 
        o.shipping_fee, 
        a.fullname AS account_name    
    FROM Orders o
    INNER JOIN Account a ON o.account_username = a.username
    WHERE 
        -- Điều kiện 1: Lọc trong khoảng ngày đặt hàng
        (@FromDate IS NULL OR o.create_date >= @FromDate) AND
        (@ToDate IS NULL OR o.create_date <= @ToDate) AND
        
        -- Điều kiện 2: Lọc theo trạng thái đã in đơn hay chưa
        (@IsPrinted IS NULL OR o.is_printed = @IsPrinted) AND
        
        -- Điều kiện 3: Tìm kiếm tương đối (LIKE)
        (@SearchKeyword IS NULL OR 
         o.order_code LIKE '%' + @SearchKeyword + '%' OR 
         o.recipient_name LIKE '%' + @SearchKeyword + '%')
         
    ORDER BY o.create_date DESC; -- Đơn mới nhất lên đầu
END;
GO

-- 2. Thủ tục: Cập nhật trạng thái sau khi xuất hóa đơn
-- Mục đích: Đánh dấu đơn hàng đã in để tránh in trùng lặp.
CREATE OR ALTER PROCEDURE sp_MarkOrderAsPrinted
    @OrderId INT -- ID của đơn hàng vừa được in
AS
BEGIN
    SET NOCOUNT ON;

    -- Cập nhật cờ is_printed = 1 và lưu thời gian xuất
    UPDATE Orders
    SET is_printed = 1,
        export_date = GETDATE()
    WHERE id = @OrderId;

    -- Trả về thông báo thành công
    SELECT N'Đã cập nhật trạng thái in cho đơn hàng: ' + CAST(@OrderId AS NVARCHAR(10));
END;
GO






-- PHẦN 5: DỮ LIỆU MẪU 

-- 1. Tạo quyền hạn (Roles)
INSERT INTO Role (name) VALUES ('ROLE_ADMIN'), ('ROLE_USER'), ('ROLE_STAFF'), ('ROLE_SHIPPER');

-- 2. Tạo tài khoản mẫu 
-- MÃ HÓA MẬT KHẨU CHO SPRING SECURITY
-- thay thế '[CHUỖI_BCRYPT_ĐÃ_MÃ_HÓA]' bằng chuỗi hash BCrypt thực tế của "123456"
INSERT INTO Account (username, password, fullname, email, phone, role_id, enabled) VALUES 
('admin', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Công Việt', 'nguyencongviet121103@gmail.com', '0901111222', 1, 1), 
('user1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Thị Ngọc Trâm', 'ngoctram20092005@gmail.com', '0903333444', 2, 1), 
('staff1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Văn Nhân Viên', 'staff1@gmail.com', '0911222333', 3, 1),
('shipper1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Trần Văn Tài Xế', 'shipper1@gmail.com', '0944555666', 4, 1);

-- 3.  Tạo Sổ địa chỉ (Bảng Address)
INSERT INTO Address (username, fullname, phone, address_line, province, district, ward, is_default) VALUES
('admin', N'Nguyễn Công Việt', '0901111222', N'123 Đường Lớn', N'Hà Nội', N'Cầu Giấy', N'Dịch Vọng', 1),
('user1', N'Nguyễn Thị Ngọc Trâm', '0903333444', N'456 Phố Nhỏ', N'Hồ Chí Minh', N'Quận 1', N'Bến Nghé', 1),
('staff1', N'Nguyễn Văn Nhân Viên', '0911222333', N'789 Đường Kho', N'Đà Nẵng', N'Hải Châu', N'Thạch Thang', 1),
('shipper1', N'Trần Văn Tài Xế', '0944555666', N'101 Đường Vận Chuyển', N'Cần Thơ', N'Ninh Kiều', N'An Cư', 1);

-- 4. Tạo 8 Danh mục sản phẩm (Categories)
SET IDENTITY_INSERT Category ON;
INSERT INTO Category (id, name) VALUES 
(1, N'Táo'), (2, N'Nho'), (3, N'Cam và Quýt'), (4, N'Cherry và Dâu tây'), 
(5, N'Kiwi và Lê'), (6, N'Trái cây nhiệt đới nhập khẩu'), 
(7, N'Trái cây mọng nước'), (8, N'Trái cây họ hàng dưa');
SET IDENTITY_INSERT Category OFF;

-- 5. Tạo Sản phẩm mẫu (Products)
-- Lưu ý: Quantity để mặc định là 0, sẽ dùng lệnh Nhập kho (Import) ở dưới để cộng số lượng
INSERT INTO Product (name, price, image, category_id) VALUES 
-- Loại 1: TÁO
(N'Táo Envy New Zealand', 250000.00, 'imgs/Tao_Envy_New_Zealand.jpg', 1), (N'Táo Fuji Nhật Bản', 380000.00, 'imgs/Tao_Fuji_Nhat_Ban.jpg', 1),
(N'Táo Gala Mỹ', 190000.00, 'imgs/Tao_Gala_My.jpg', 1), (N'Táo Rockit New Zealand (Dạng ống)', 120000.00, 'imgs/Tao_Rockit_New_Zealand.jpg', 1),
(N'Táo Ambrosia Mỹ', 210000.00, 'imgs/Tao_Ambrosia_My.jpg', 1), (N'Táo Xanh Granny Smith', 170000.00, 'imgs/Tao_Xanh_Granny_Smith.jpg', 1),
(N'Táo Juliet Pháp hữu cơ', 320000.00, 'imgs/Tao_Juliet_Phap_Huu_Co.jpg', 1), (N'Táo Honeycrisp Mỹ', 280000.00, 'imgs/Tao_Honeycrisp_My.jpg', 1),
-- Loại 2: NHO
(N'Nho Ngón Tay (Moon Drops) Úc', 350000.00, 'imgs/Nho_Ngon_Tay_Uc.jpg', 2), (N'Nho Đen không hạt Mỹ', 290000.00, 'imgs/Nho_Den_Khong_Hat_My.jpg', 2),
(N'Nho Xanh không hạt Úc', 270000.00, 'imgs/Nho_Xanh_Khong_Hat_Uc.jpg', 2), (N'Nho Đỏ không hạt Nam Phi', 260000.00, 'imgs/Nho_Do_Khong_Hat_Nam_Phi.jpg', 2),
(N'Nho Kyoho Nhật Bản', 590000.00, 'imgs/Nho_Kyoho_Nhat_Ban.jpg', 2), (N'Nho Mẫu Đơn Shine Muscat Hàn Quốc', 650000.00, 'imgs/Nho_Mau_Don_Shine_Muscat_Han_Quoc.jpg', 2),
(N'Nho Candy Hearts Mỹ', 380000.00, 'imgs/Nho_Candy_Hearts_My.jpg', 2), (N'Nho Tim Cardinal', 240000.00, 'imgs/Nho_Tim_Cardinal.jpg', 2),
-- Loại 3: CAM QUÝT
(N'Cam Vàng Navel Úc', 180000.00, 'imgs/Cam_Vang_Navel_Uc.jpg', 3), (N'Cam Ruột Đỏ Cara Cara Mỹ', 220000.00, 'imgs/Cam_Ruot_Do_Cara_Cara_My.jpg', 3),
(N'Quýt Úc Honey Murcott', 240000.00, 'imgs/Quyt_Uc_Honey_Murcott.jpg', 3), (N'Cam Vàng Valencia Nam Phi', 170000.00, 'imgs/Cam_Vang_Valencia_Nam_Phi.jpg', 3),
(N'Cam Blood Orange Ý', 290000.00, 'imgs/Cam_Blood_Orange_Y.jpg', 3), (N'Quýt Ponkan Đài Loan', 190000.00, 'imgs/Quyt_Ponkan_Dai_Loan.jpg', 3),
(N'Cam Sunkist Mỹ', 150000.00, 'imgs/Cam_Sunkist_My.jpg', 3), (N'Quýt Mandarin Tây Ban Nha', 200000.00, 'imgs/Quyt_Mandarin_Tay_Ban_Nha.jpg', 3),
-- Loại 4: CHERRY & DÂU
(N'Cherry Đỏ Canada', 450000.00, 'imgs/Cherry_Do_Canada.jpg', 4), (N'Cherry Vàng Rainier Mỹ', 520000.00, 'imgs/Cherry_Vang_Rainier_My.jpg', 4),
(N'Dâu tây Hàn Quốc To', 280000.00, 'imgs/Dau_Tay_Han_Quoc_To.jpg', 4), (N'Dâu tây Mỹ Trắng Pineberry', 350000.00, 'imgs/Dau_Tay_My_Trang_Pineberry.jpg', 4),
(N'Cherry Úc', 410000.00, 'imgs/Cherry_Uc.jpg', 4), (N'Dâu tây Nhật Bản Amaou', 680000.00, 'imgs/Dau_Tay_Nhat_Ban_Amaou.jpg', 4),
(N'Dâu tây Mỹ Camarosa', 250000.00, 'imgs/Dau_Tay_My_Camarosa.jpg', 4), (N'Cherry Nam Phi', 390000.00, 'imgs/Cherry_Nam_Phi.jpg', 4),
-- Loại 5: KIWI & LÊ
(N'Kiwi Vàng Zespri New Zealand', 150000.00, 'imgs/Kiwi_Vang_Zespri_New_Zealand.jpg', 5), (N'Kiwi Xanh Zespri New Zealand', 130000.00, 'imgs/Kiwi_Xanh_Zespri_New_Zealand.jpg', 5),
(N'Lê Nam Phi Vàng', 180000.00, 'imgs/Le_Nam_Phi_Vang.jpg', 5), (N'Lê Hàn Quốc Nashi', 190000.00, 'imgs/Le_Han_Quoc_Nashi.jpg', 5),
(N'Kiwi Đỏ New Zealand', 210000.00, 'imgs/Kiwi_Do_New_Zealand.jpg', 5), (N'Lê Xanh Bosc Mỹ', 160000.00, 'imgs/Le_Xanh_Bosc_My.jpg', 5),
(N'Kiwi Xanh Organic Ý', 140000.00, 'imgs/Kiwi_Xanh_Organic_Y.jpg', 5), (N'Lê Đỏ Starkrimson Mỹ', 200000.00, 'imgs/Le_Do_Starkrimson_My.jpg', 5),
-- Loại 6: NHIỆT ĐỚI
(N'Xoài Thái Lan (Giống R2E2)', 300000.00, 'imgs/Xoai_Thai_Lan_R2E2.jpg', 6), (N'Bơ Hass Úc', 210000.00, 'imgs/Bo_Hass_Uc.jpg', 6),
(N'Thanh Long Ruột Đỏ Israel', 250000.00, 'imgs/Thanh_Long_Ruot_Do_Israel.jpg', 6), (N'Mãng Cầu Đài Loan', 320000.00, 'imgs/Mang_Cau_Dai_Loan.jpg', 6),
(N'Ổi Đài Loan', 150000.00, 'imgs/Oi_Dai_Loan.jpg', 6), (N'Chôm Chôm Thái Lan', 180000.00, 'imgs/Chom_Chom_Thai_Lan.jpg', 6),
(N'Măng Cụt Thái Lan', 280000.00, 'imgs/Mang_Cut_Thai_Lan.jpg', 6), (N'Dừa Xiêm Mã Lai', 90000.00, 'imgs/Dua_Xiem_Ma_Lai.jpg', 6),
-- Loại 7: MỌNG NƯỚC
(N'Việt Quất (Blueberry) Peru', 160000.00, 'imgs/Viet_Quat_Blueberry_Peru.jpg', 7), (N'Mâm Xôi Đen (Blackberry) Mỹ', 320000.00, 'imgs/Mam_Xoi_Den_Blackberry_My.jpg', 7),
(N'Mâm Xôi Đỏ (Raspberry) Mỹ', 350000.00, 'imgs/Mam_Xoi_Do_Raspberry_My.jpg', 7), (N'Nho Lý Chua Đỏ (Red Currant) Hà Lan', 420000.00, 'imgs/Nho_Ly_Chua_Do_Ha_Lan.jpg', 7),
(N'Quả Goji Berry Tây Tạng', 290000.00, 'imgs/Qua_Goji_Berry_Tay_Tang.jpg', 7), (N'Việt Quất Canada', 190000.00, 'imgs/Viet_Quat_Canada.jpg', 7),
(N'Quả Cranberry Mỹ', 310000.00, 'imgs/Qua_Cranberry_My.jpg', 7), (N'Dâu tằm trắng Nhật Bản', 480000.00, 'imgs/Dau_Tam_Trang_Nhat_Ban.jpg', 7),
-- Loại 8: DƯA
(N'Dưa Lưới Yubari Nhật Bản', 1500000.00, 'imgs/Dua_Luoi_Yubari_Nhat_Ban.jpg', 8), (N'Dưa Lưới Vàng Kim Hoàng Đài Loan', 350000.00, 'imgs/Dua_Luoi_Vang_Kim_Hoang_Dai_Loan.jpg', 8),
(N'Dưa Hami Tân Cương', 380000.00, 'imgs/Dua_Hami_Tan_Cuong.jpg', 8), (N'Dưa Hấu Không Hạt Thái Lan', 250000.00, 'imgs/Dua_Hau_Khong_Hat_Thai_Lan.jpg', 8),
(N'Dưa Hấu Vỏ Vàng Ruột Đỏ Nhật Bản', 450000.00, 'imgs/Dua_Hau_Vo_Vang_Ruot_Do_Nhat_Ban.jpg', 8), (N'Dưa Hoàng Kim (Piel de Sapo) Tây Ban Nha', 310000.00, 'imgs/Dua_Hoang_Kim_Tay_Ban_Nha.jpg', 8),
(N'Dưa Lưới Xanh Charentais Pháp', 400000.00, 'imgs/Dua_Luoi_Xanh_Charentais_Phap.jpg', 8), (N'Dưa Galia Israel', 330000.00, 'imgs/Dua_Galia_Israel.jpg', 8);

-- 6. Tạo dữ liệu ảnh (Product_Image)
-- Copy ảnh đại diện vào bảng Product_Image làm ảnh chính
INSERT INTO Product_Image (product_id, image_url, is_main)
SELECT id, image, 1 FROM Product WHERE image IS NOT NULL;

-- 7. Tạo Nhà cung cấp (Supplier) - Để phục vụ nhập hàng
INSERT INTO Supplier (name, contact_name, phone, address, active) VALUES 
(N'Công Ty Rau Quả Sạch Đà Lạt', N'Anh Nam', '0909999888', N'Đà Lạt, Lâm Đồng', 1),
(N'Import Fruit USA', N'Mr. John', '0908888777', N'California, USA', 1);

-- 8. NHẬP KHO (Import) - Quan trọng để cộng tồn kho
-- Tạo phiếu nhập
INSERT INTO Import (supplier_id, account_username, total_amount, notes) VALUES 
(1, 'admin', 50000000, N'Nhập hàng đầu mùa vụ');

-- Chi tiết nhập (Kích hoạt Trigger để cộng quantity và update import_price)
-- Nhập mẫu cho 5 sản phẩm đầu tiên (ID 1-5)
INSERT INTO Import_Detail (import_id, product_id, quantity, unit_price) VALUES 
(1, 1, 100, 180000), -- Táo Envy
(1, 2, 50, 250000),  -- Táo Fuji
(1, 3, 200, 120000), -- Táo Gala
(1, 4, 100, 80000),  -- Táo Rockit
(1, 5, 50, 150000);  -- Táo Ambrosia

-- 9. Tạo dữ liệu Voucher mẫu
INSERT INTO Voucher (code, description, discount_percent, discount_amount, max_discount_amount, quantity, active) VALUES
('WELCOME', N'Chào bạn mới', 10, 0, 50000, 1000, 1),
('FREESHIP', N'Miễn phí vận chuyển', 0, 20000, 0, 500, 1);

-- 10. Tạo Tin tức (News)
INSERT INTO News (title, content, image, account_username) VALUES 
(N'Lợi ích tuyệt vời của Táo Envy', N'<p>Táo Envy không chỉ ngon mà còn giúp đẹp da...</p>', 'imgs/Tao_Envy_New_Zealand.jpg', 'admin'),
(N'Cách bảo quản Nho mẫu đơn tươi lâu', N'<p>Để nho luôn tươi, bạn cần bảo quản trong ngăn mát...</p>', 'imgs/Nho_Mau_Don_Shine_Muscat_Han_Quoc.jpg', 'admin'),
(N'Chương trình khuyến mãi mùa hè', N'<p>Giảm giá 20% cho các loại trái cây nhiệt đới...</p>', 'imgs/Dua_Hau_Khong_Hat_Thai_Lan.jpg', 'admin');

-- 11. Tạo Liên hệ (Contact)
INSERT INTO Contact (full_name, email, subject, message) VALUES 
(N'Nguyễn Văn A', 'khachhangA@gmail.com', N'Hỏi về giá sỉ', N'Shop có bán sỉ thùng 10kg Nho không?'),
(N'Trần Thị B', 'khachhangB@gmail.com', N'Phàn nàn giao hàng', N'Shipper giao hàng hơi chậm nha shop.');

-- 12. Cấu hình Shop (Shop_Info)
INSERT INTO Shop_Info (shop_name, address, phone, email, logo_url, facebook_link) 
VALUES (
    N'Trái Cây Bay - Fresh & Healthy', 
    N'123 Đường Cầu Giấy, Hà Nội', 
    '0988.888.888', 
    'contact@traicaybay.com', 
    'imgs/logo.png',
    'https://facebook.com/traicaybay'
);

-- 13. Tạo Trang tĩnh (Static Page)
INSERT INTO Static_Page (slug, title, content, image_url) 
VALUES (
    'gioi-thieu', 
    N'Về Trái Cây Bay - Sứ Mệnh & Tầm Nhìn', 
    N'<p>Chào mừng bạn đến với <b>Trái Cây Bay</b>. Chúng tôi được thành lập vào năm 2025...</p>', 
    'imgs/banner-gioi-thieu.jpg'
);

-- 14. Tạo Đơn hàng, Chi tiết & Đánh giá (Sử dụng biến để lấy ID tự động - An toàn tuyệt đối)
BEGIN TRANSACTION; -- Dùng Transaction để đảm bảo toàn vẹn dữ liệu
    
    DECLARE @NewOrderID INT;
    DECLARE @NewOrderDetailID INT;

    -- A. Tạo Đơn hàng
    INSERT INTO Orders (account_username, shipping_address, recipient_name, recipient_phone, status, total_amount, payment_method)
    VALUES ('user1', N'456 Phố Nhỏ, Quận 1, HCM', N'Ngọc Trâm', '0903333444', N'Giao hàng thành công', 250000, 'COD');
    
    -- Lấy ID của đơn hàng vừa tạo gán vào biến
    SET @NewOrderID = SCOPE_IDENTITY();

    -- B. Tạo Chi tiết đơn hàng (Sử dụng ID vừa lấy)
    INSERT INTO Order_Detail (order_id, product_id, quantity, price) 
    VALUES (@NewOrderID, 1, 1.0, 250000); -- Mua 1kg Táo Envy

    -- Lấy ID của dòng chi tiết vừa tạo
    SET @NewOrderDetailID = SCOPE_IDENTITY();

    -- C. Tạo Đánh giá (Sử dụng ID chi tiết vừa lấy)
    INSERT INTO Review (username, order_detail_id, rating, comment)
    VALUES ('user1', @NewOrderDetailID, 5, N'Táo rất giòn và ngọt, giao hàng nhanh!');

COMMIT TRANSACTION;
GO

-- 15. Tương tác News
INSERT INTO News_Like (news_id, username) VALUES (1, 'user1');
INSERT INTO News_Share (news_id, username, platform) VALUES (1, 'user1', 'Facebook');
INSERT INTO News_Comment (news_id, username, content, parent_id) VALUES (1, 'user1', N'Bài viết rất bổ ích, cảm ơn shop!', NULL);
INSERT INTO News_Comment (news_id, username, content, parent_id) VALUES (1, 'admin', N'Cảm ơn bạn đã ủng hộ Trái Cây Bay ạ!', 1); -- Trả lời comment trên

-- 16. Giỏ hàng (Cart)
-- User1 thêm sản phẩm ID = 4 vào giỏ (Bảng Cart gộp)
INSERT INTO Cart (username, product_id, quantity) VALUES ('user1', 4, 2.5);

GO



