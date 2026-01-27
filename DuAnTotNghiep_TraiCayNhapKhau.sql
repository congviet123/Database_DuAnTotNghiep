
CREATE DATABASE DuAnTotNghiep_WebsiteTraiCayNhapKhau;
GO

USE DuAnTotNghiep_WebsiteTraiCayNhapKhau;
GO



-- PHẦN 2: TẠO CÁC BẢNG (TABLES) & RÀNG BUỘC (CONSTRAINTS)

-- 1. Bảng ROLE (Quyền hạn)
-- Lưu trữ các quyền trong hệ thống (Admin, User, Staff...)
CREATE TABLE Role (
    id INT PRIMARY KEY IDENTITY(1,1),   -- Mã quyền (Tự động tăng 1, 2, 3...)
    name VARCHAR(50) UNIQUE NOT NULL    -- Tên quyền (VD: ROLE_ADMIN, ROLE_USER) - Không được trùng
);

-- 2. Bảng ACCOUNT (Tài khoản người dùng)
-- Lưu thông tin đăng nhập và thông tin cá nhân cơ bản
CREATE TABLE Account (
    username VARCHAR(50) PRIMARY KEY,               -- Tên đăng nhập (Khóa chính, định danh duy nhất)
    password VARCHAR(255) NOT NULL,                 -- Mật khẩu (Lưu chuỗi mã hóa BCrypt, không lưu text thường)
    fullname NVARCHAR(100) NOT NULL,                -- Họ và tên đầy đủ của người dùng
    email VARCHAR(100) UNIQUE NOT NULL,             -- Email (Dùng để nhận thông báo/lấy lại mật khẩu)
    address NVARCHAR(255),                          -- Địa chỉ cá nhân mặc định (để ship hàng nhanh)
    phone VARCHAR(20),                              -- Số điện thoại liên hệ
    enabled BIT NOT NULL DEFAULT 1,                 -- Trạng thái tài khoản (1: Hoạt động, 0: Bị khóa/Cấm)
    role_id INT NOT NULL,                           -- Mã quyền hạn của tài khoản này
    FOREIGN KEY (role_id) REFERENCES Role(id)       -- Liên kết tới bảng Role
);

-- 3. Bảng CATEGORY (Danh mục sản phẩm)
-- Phân loại trái cây (VD: Táo, Nho, Cam...)
CREATE TABLE Category (
    id INT PRIMARY KEY IDENTITY(1,1),   -- Mã danh mục (Tự tăng)
    name NVARCHAR(100) UNIQUE NOT NULL  -- Tên danh mục (VD: Trái cây nhiệt đới)
);

-- 4. Bảng PRODUCT (Sản phẩm - Trái cây)
-- Lưu toàn bộ thông tin về sản phẩm bán ra
CREATE TABLE Product (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã sản phẩm (Tự tăng)
    name NVARCHAR(150) NOT NULL,                    -- Tên sản phẩm (VD: Táo Envy Mỹ)
    price DECIMAL(18, 2) CHECK (price >= 0) NOT NULL, -- Giá bán thực tế khách phải trả (Không được âm)
    description NVARCHAR(MAX) DEFAULT N'Mô tả...',  -- Bài viết mô tả chi tiết (HTML/Text)
    image VARCHAR(255),                             -- Đường dẫn ảnh đại diện (Thumbnail hiển thị ở danh sách)
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,     -- Số lượng tồn kho (Tính bằng Kg, hỗ trợ số lẻ 0.5kg)
    is_liquidation BIT NOT NULL DEFAULT 0,          -- Cờ đánh dấu hàng thanh lý (1: Có, 0: Không)
    original_price DECIMAL(18, 2),                  -- Giá gốc/Giá niêm yết (Dùng để gạch ngang hiển thị giảm giá)
    discount INT DEFAULT 0 CHECK (discount >= 0 AND discount <= 100), -- % Giảm giá (0-100%)
    import_price DECIMAL(18, 2) DEFAULT 0,          -- Giá nhập vào (Dùng để tính lợi nhuận nội bộ)
    available BIT NOT NULL DEFAULT 1,               -- Trạng thái kinh doanh (1: Đang bán, 0: Ngừng bán/Ẩn)
    create_date DATE DEFAULT GETDATE(),             -- Ngày tạo sản phẩm (Mặc định là ngày hiện tại)
    category_id INT NOT NULL,                       -- Sản phẩm thuộc danh mục nào
    FOREIGN KEY (category_id) REFERENCES Category(id) -- Liên kết tới bảng Category
);

-- 5. Bảng PRODUCT_IMAGE (Thư viện ảnh)
-- Một sản phẩm có thể có nhiều ảnh chi tiết (góc cạnh, bao bì...)
CREATE TABLE Product_Image (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã hình ảnh
    product_id INT NOT NULL,                        -- Thuộc về sản phẩm nào
    image_url VARCHAR(255) NOT NULL,                -- Đường dẫn file ảnh
    is_main BIT DEFAULT 0,                          -- Cờ đánh dấu: 1 là ảnh chính, 0 là ảnh phụ
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE -- Xóa sản phẩm thì xóa luôn ảnh
);

-- 6. Bảng PRODUCT_WISHLIST (Sản phẩm yêu thích)
-- Lưu danh sách các món khách hàng muốn mua sau
CREATE TABLE Product_Wishlist (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã dòng yêu thích
    username VARCHAR(50) NOT NULL,                  -- Tài khoản nào thích
    product_id INT NOT NULL,                        -- Thích sản phẩm nào
    create_date DATETIME DEFAULT GETDATE(),         -- Ngày bấm thích
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE, -- Xóa user xóa luôn wishlist
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE,     -- Xóa sản phẩm xóa luôn wishlist
    CONSTRAINT UQ_Product_Wishlist UNIQUE (username, product_id) -- Ràng buộc: Mỗi user chỉ thích 1 sp 1 lần
);

-- 7. Bảng VOUCHER (Mã giảm giá)
-- Quản lý các mã khuyến mãi 
CREATE TABLE Voucher (
    code VARCHAR(20) PRIMARY KEY,                   -- Mã voucher (VD: SUMMER2025) - Là khóa chính
    description NVARCHAR(255),                      -- Mô tả voucher (VD: Giảm 50k cho đơn từ 200k)
    discount_percent INT CHECK (discount_percent BETWEEN 0 AND 100), -- Giảm theo % (VD: 10%)
    discount_amount DECIMAL(18,2) DEFAULT 0,        -- Giảm theo tiền mặt (VD: 50.000 VNĐ)
    min_condition DECIMAL(18,2) DEFAULT 0,          -- Điều kiện: Giá trị đơn hàng tối thiểu để áp dụng
    start_date DATETIME,                            -- Ngày bắt đầu hiệu lực
    end_date DATETIME,                              -- Ngày hết hạn
    quantity INT DEFAULT 100,                       -- Số lượng mã phát hành
    active BIT DEFAULT 1                            -- Trạng thái (1: Kích hoạt, 0: Vô hiệu hóa)
);

-- 8. Bảng ORDERS (Đơn hàng)
-- Lưu thông tin tổng quan của đơn hàng
CREATE TABLE Orders (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã hóa đơn (Tự tăng)
    create_date DATETIME DEFAULT GETDATE(),         -- Thời gian đặt hàng
    shipping_address NVARCHAR(255) NOT NULL,        -- Địa chỉ giao hàng thực tế (có thể khác địa chỉ mặc định)
    status NVARCHAR(50) NOT NULL,                   -- Trạng thái đơn (VD: Chờ xác nhận, Đang giao, Hoàn thành...)
    notes NVARCHAR(500),                            -- Ghi chú của khách (VD: Giao giờ hành chính)
    payment_method VARCHAR(50),                     -- Phương thức thanh toán (COD, Chuyển khoản, VNPAY...)
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0, -- Tổng tiền khách phải thanh toán
    account_username VARCHAR(50) NOT NULL,          -- Khách hàng nào đặt đơn này
    voucher_code VARCHAR(20),                       -- Mã giảm giá đã sử dụng (nếu có)
    order_code AS ('DH' + RIGHT('000000' + CAST(id AS VARCHAR(10)), 6)), -- Mã đơn hàng tự động (VD: DH000001)
    recipient_name NVARCHAR(100),       -- Tên người nhận (nếu khác chủ tài khoản)
    recipient_phone VARCHAR(20),        -- Số điện thoại người nhận
    shipping_fee DECIMAL(18, 2) DEFAULT 0, -- Phí giao hàng
    is_printed BIT DEFAULT 0,           -- Đã in hóa đơn chưa? (0: Chưa, 1: Rồi)
    export_date DATETIME,               -- Ngày xuất hóa đơn gần nhất
	FOREIGN KEY (account_username) REFERENCES Account(username), -- Liên kết user
    FOREIGN KEY (voucher_code) REFERENCES Voucher(code)          -- Liên kết voucher
);

-- 9. Bảng ORDER_DETAIL (Chi tiết đơn hàng)
-- Lưu từng món hàng trong đơn (Mua gì, bao nhiêu kg, giá lúc mua bao nhiêu)
CREATE TABLE Order_Detail (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã chi tiết
    price DECIMAL(18, 2) NOT NULL,                  -- Giá bán TẠI THỜI ĐIỂM MUA (Quan trọng để đối soát)
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0), -- Số lượng mua (Kg)
    product_id INT NOT NULL,                        -- Mua sản phẩm nào
    order_id INT NOT NULL,                          -- Thuộc về hóa đơn nào
    FOREIGN KEY (product_id) REFERENCES Product(id),
    FOREIGN KEY (order_id) REFERENCES Orders(id) ON DELETE CASCADE -- Xóa hóa đơn thì xóa luôn chi tiết
);

-- 10. Bảng CART (Giỏ hàng)
-- Quản lý phiên mua sắm (Mỗi người dùng chỉ có 1 giỏ hàng duy nhất)
CREATE TABLE Cart (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã giỏ hàng
    account_username VARCHAR(50) UNIQUE NOT NULL,   -- Chủ sở hữu giỏ (Unique: 1 người - 1 giỏ)
    FOREIGN KEY (account_username) REFERENCES Account(username)
);

-- 11. Bảng CART_ITEM (Sản phẩm trong giỏ)
-- Lưu các món hàng đang nằm trong giỏ chờ thanh toán
CREATE TABLE Cart_Item (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã dòng trong giỏ
    cart_id INT NOT NULL,                           -- Thuộc giỏ hàng nào
    product_id INT NOT NULL,                        -- Sản phẩm nào
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0), -- Số lượng muốn mua
    FOREIGN KEY (cart_id) REFERENCES Cart(id) ON DELETE CASCADE, -- Xóa giỏ thì xóa sạch đồ trong giỏ
    FOREIGN KEY (product_id) REFERENCES Product(id)
);

-- 12. Bảng REVIEW (Đánh giá sản phẩm)
-- Lưu đánh giá của khách hàng cho sản phẩm đã mua (Ràng buộc: Mỗi lượt mua chỉ được đánh giá 1 lần)
CREATE TABLE Review (
    id INT PRIMARY KEY IDENTITY(1,1),                           -- Mã đánh giá
    comment NVARCHAR(MAX),                                      -- Nội dung bình luận
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),    -- Số sao (1 đến 5)
    review_date DATETIME DEFAULT GETDATE(),                     -- Ngày đánh giá
    username VARCHAR(50) NOT NULL,                              -- Người đánh giá
    product_id INT NOT NULL,                                    -- Sản phẩm được đánh giá
    order_detail_id INT UNIQUE NOT NULL,                        -- Liên kết chi tiết đơn (Đảm bảo mua rồi mới được đánh giá)
    FOREIGN KEY (username) REFERENCES Account(username),
    FOREIGN KEY (product_id) REFERENCES Product(id),
    FOREIGN KEY (order_detail_id) REFERENCES Order_Detail(id) ON DELETE CASCADE
);
GO

-- 13. Bảng NEWS (Tin tức - Blog)
-- Bài viết tin tức, mẹo vặt, SEO
CREATE TABLE News (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã bài viết
    title NVARCHAR(255) NOT NULL,                   -- Tiêu đề bài viết
    content NVARCHAR(MAX) NOT NULL,                 -- Nội dung bài viết (Chứa HTML)
    image VARCHAR(255),                             -- Ảnh đại diện bài viết
    create_date DATETIME DEFAULT GETDATE(),         -- Ngày đăng
    account_username VARCHAR(50) NOT NULL,          -- Người đăng (Admin/Staff)
    
    -- Hai trường này được Trigger tự động cập nhật, giúp hiển thị nhanh
    like_count INT DEFAULT 0,                       -- Tổng số lượt thích
    view_count INT DEFAULT 0,                       -- Tổng số lượt xem

    FOREIGN KEY (account_username) REFERENCES Account(username)
);

-- 14. Bảng NEWS_VIEW (Lịch sử xem tin)
-- Ghi log mỗi lần có người bấm vào xem bài viết
CREATE TABLE News_View (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã lượt xem
    news_id INT NOT NULL,                           -- Xem bài nào
    username VARCHAR(50),                           -- Ai xem (NULL nếu là khách vãng lai)
    view_date DATETIME DEFAULT GETDATE(),           -- Thời điểm xem
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE
);

-- 15. Bảng NEWS_LIKE (Lượt thích tin tức)
-- Lưu danh sách những người đã like bài viết
CREATE TABLE News_Like (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã lượt like
    news_id INT NOT NULL,                           -- Like bài nào
    username VARCHAR(50) NOT NULL,                  -- Ai like
    like_date DATETIME DEFAULT GETDATE(),           -- Thời điểm like
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username) ON DELETE CASCADE,
    CONSTRAINT UQ_News_Like UNIQUE (news_id, username) -- Ràng buộc: Mỗi người chỉ Like 1 bài 1 lần
);

-- 16. Bảng NEWS_SHARE (Lịch sử chia sẻ)
-- Thống kê lượt chia sẻ bài viết lên mạng xã hội
CREATE TABLE News_Share (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã lượt share
    news_id INT NOT NULL,                           -- Share bài nào
    username VARCHAR(50) NOT NULL,                  -- Ai share
    share_date DATETIME DEFAULT GETDATE(),          -- Thời điểm share
    platform NVARCHAR(50),                          -- Nền tảng (Facebook, Zalo, Copy Link...)
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username)
);

-- 17. Bảng NEWS_COMMENT (Bình luận tin tức)
-- Hệ thống bình luận đa cấp (User comment, Admin reply)
CREATE TABLE News_Comment (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã bình luận
    news_id INT NOT NULL,                           -- Bình luận bài nào
    username VARCHAR(50) NOT NULL,                  -- Ai bình luận
    content NVARCHAR(MAX) NOT NULL,                 -- Nội dung
    create_date DATETIME DEFAULT GETDATE(),         -- Thời gian
    is_visible BIT DEFAULT 1,                       -- Trạng thái hiển thị (1: Hiện, 0: Ẩn/Kiểm duyệt)
    parent_id INT,                                  -- Mã bình luận cha (NULL = Comment gốc, Có ID = Reply)
    FOREIGN KEY (news_id) REFERENCES News(id) ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES Account(username),
    FOREIGN KEY (parent_id) REFERENCES News_Comment(id) -- Tham chiếu chính bảng này
);

-- 18. Bảng CONTACT (Liên hệ từ menu liên hệ khách gửi)
-- Lưu form liên hệ từ khách hàng gửi về
CREATE TABLE Contact (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã liên hệ
    full_name NVARCHAR(100) NOT NULL,               -- Tên người gửi
    email VARCHAR(100) NOT NULL,                    -- Email phản hồi
    subject NVARCHAR(200),                          -- Tiêu đề vấn đề
    message NVARCHAR(MAX) NOT NULL,                 -- Nội dung tin nhắn
    create_date DATETIME DEFAULT GETDATE(),         -- Thời gian gửi
    status NVARCHAR(50) DEFAULT N'Chưa xử lý'      -- Trạng thái xử lý (Đã xem/Chưa xem)
);

-- 19. Bảng SHOP_INFO (Cấu hình Shop menu liên hệ)
-- Lưu thông tin cửa hàng menu liên hệ
CREATE TABLE Shop_Info (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã cấu hình
    shop_name NVARCHAR(100) NOT NULL,               -- Tên cửa hàng
    address NVARCHAR(255) NOT NULL,                 -- Địa chỉ hiển thị
    phone VARCHAR(20) NOT NULL,                     -- Hotline
    email VARCHAR(100) NOT NULL,                    -- Email shop
    logo_url VARCHAR(255),                          -- Link ảnh Logo
    facebook_link VARCHAR(255),                     -- Link Fanpage
    zalo_link VARCHAR(255),                         -- Link Zalo OA
    map_iframe NVARCHAR(MAX)                        -- Mã nhúng bản đồ Google Map
);

-- 20. Bảng STATIC_PAGE (menu giới thiệu)
-- Quản lý nội dung các trang: Giới thiệu, Chính sách, Điều khoản
CREATE TABLE Static_Page (
    id INT PRIMARY KEY IDENTITY(1,1),               -- Mã trang
    slug VARCHAR(50) UNIQUE NOT NULL,               -- Đường dẫn định danh (VD: 'gioi-thieu')
    title NVARCHAR(255) NOT NULL,                   -- Tiêu đề trang
    content NVARCHAR(MAX) NOT NULL,                 -- Nội dung HTML
    image_url VARCHAR(255),                         -- Ảnh Banner trang
    last_modified DATETIME DEFAULT GETDATE()        -- Ngày cập nhật cuối cùng
);



-- QUẢN LÝ NHẬP HÀNG & NHÀ CUNG CẤP

-- 21. Bảng SUPPLIER (Nhà cung cấp)
CREATE TABLE Supplier (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(200) NOT NULL,        -- Tên nhà cung cấp
    contact_name NVARCHAR(100),         -- Người liên hệ
    phone VARCHAR(20),                  -- SĐT
    email VARCHAR(100),                 -- Email
    address NVARCHAR(255),              -- Địa chỉ
    bank_name NVARCHAR(100),            -- Tên ngân hàng
    bank_account_number VARCHAR(50),    -- Số tài khoản
    bank_account_holder NVARCHAR(100),  -- Tên chủ tài khoản
    active BIT DEFAULT 1                -- 1: Đang hợp tác, 0: Ngừng
);

-- 22. Bảng IMPORT (Phiếu nhập kho)
CREATE TABLE Import (
    id INT PRIMARY KEY IDENTITY(1,1),
    import_date DATETIME DEFAULT GETDATE(), -- Ngày nhập
    supplier_id INT NOT NULL,               -- Nhập từ ai
    account_username VARCHAR(50) NOT NULL,  -- Nhân viên nào nhập
    total_amount DECIMAL(18, 2) DEFAULT 0,  -- Tổng tiền
    notes NVARCHAR(500),                    -- Ghi chú
    FOREIGN KEY (supplier_id) REFERENCES Supplier(id),
    FOREIGN KEY (account_username) REFERENCES Account(username)
);

-- 23. Bảng IMPORT_DETAIL (Chi tiết nhập)
CREATE TABLE Import_Detail (
    id INT PRIMARY KEY IDENTITY(1,1),
    import_id INT NOT NULL,                 -- Thuộc phiếu nhập nào
    product_id INT NOT NULL,                -- Sản phẩm nào
    quantity DECIMAL(10, 2) NOT NULL,       -- Số lượng nhập
    unit_price DECIMAL(18, 2) NOT NULL,     -- Giá vốn nhập vào
    FOREIGN KEY (import_id) REFERENCES Import(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(id)
);
GO





-- PHẦN 3: TRIGGER TỰ ĐỘNG (AUTOMATION)

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

-- Trigger 3: Tự động cập nhập kho
CREATE OR ALTER TRIGGER trg_UpdateStockAfterImport
ON Import_Detail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Cập nhật số lượng tồn kho (Cộng dồn)
    UPDATE p
    SET p.quantity = p.quantity + i.quantity
    FROM Product p
    JOIN inserted i ON p.id = i.product_id;

    -- 2. Cập nhật giá nhập mới nhất (Để tính lãi lỗ)
    -- (Lưu ý: Có thể dùng công thức bình quân gia quyền nếu muốn chuyên sâu hơn, 
    -- ở đây mình dùng giá mới nhất cho đơn giản hóa đồ án)
    UPDATE p
    SET p.import_price = i.unit_price
    FROM Product p
    JOIN inserted i ON p.id = i.product_id;
END;
GO

-- Trigger kiểm tra trạng thái đơn hàng "Thành công"
CREATE OR ALTER TRIGGER trg_ValidateReview
ON Review
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra: Đơn hàng chứa chi tiết này đã "Giao hàng thành công" chưa?
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Order_Detail od ON i.order_detail_id = od.id
        JOIN Orders o ON od.order_id = o.id
        WHERE o.status <> N'Giao hàng thành công' -- Nếu trạng thái KHÁC thành công
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'Lỗi: Đơn hàng chưa hoàn thành, bạn chưa thể đánh giá sản phẩm này!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra: Product_ID trong Review có khớp với Product_ID trong Order_Detail không?
    -- (Tránh trường hợp hacker gửi API sai: Review SP A nhưng lấy ID đơn hàng của SP B)
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Order_Detail od ON i.order_detail_id = od.id
        WHERE i.product_id <> od.product_id -- Nếu lệch sản phẩm
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'Lỗi dữ liệu: Sản phẩm đánh giá không khớp với đơn hàng!', 16, 1);
        RETURN;
    END
END;
GO


-- PHẦN 4: THỦ TỤC LƯU TRỮ (STORED PROCEDURES)
-- 1. Thủ tục: Lấy danh sách đơn hàng để xuất hóa đơn
-- Mục đích: Hỗ trợ Admin lọc đơn hàng theo ngày, trạng thái in và từ khóa để chọn đơn đi giao
CREATE OR ALTER PROCEDURE sp_GetOrdersForPrinting
    @FromDate DATETIME = NULL,        
    @ToDate DATETIME = NULL,          
    @IsPrinted BIT = NULL,            
    @SearchKeyword NVARCHAR(100) = NULL 
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
        
        -- Điều kiện 3: Tìm kiếm theo mã đơn hàng hoặc tên người nhận (Tìm gần đúng)
        (@SearchKeyword IS NULL OR 
         o.order_code LIKE '%' + @SearchKeyword + '%' OR 
         o.recipient_name LIKE '%' + @SearchKeyword + '%')
         
    ORDER BY o.create_date DESC; -- Đơn hàng mới nhất hiện lên trên đầu
END;
GO

-- 2. Thủ tục: Cập nhật trạng thái sau khi xuất hóa đơn
-- Mục đích: Đánh dấu đơn hàng đã in để Admin không in nhầm/in trùng cho Shipper
CREATE OR ALTER PROCEDURE sp_MarkOrderAsPrinted
    @OrderId INT -- ID của đơn hàng vừa được Admin bấm xuất PDF
AS
BEGIN
    SET NOCOUNT ON;

    -- Cập nhật cờ is_printed và lưu lại thời điểm xuất hóa đơn
    UPDATE Orders
    SET is_printed = 1,
        export_date = GETDATE()
    WHERE id = @OrderId;

    -- Trả về thông báo nhỏ để Backend xác nhận thành công
    SELECT N'Đã cập nhật trạng thái in cho đơn hàng: ' + CAST(@OrderId AS NVARCHAR(10));
END;
GO






-- PHẦN 5: DỮ LIỆU MẪU (SEED DATA)

-- 1. Tạo quyền hạn (Roles)
INSERT INTO Role (name) VALUES ('ROLE_ADMIN'), ('ROLE_USER'), ('ROLE_STAFF'), ('ROLE_SHIPPER');

-- 2. Tạo tài khoản mẫu (Password là 123456 đã mã hóa BCrypt)
INSERT INTO Account (username, password, fullname, email, address, phone, role_id, enabled) VALUES 
('admin', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Công Việt', 'nguyencongviet121103@gmail.com', N'123 Đường Lớn', '0901111222', 1, 1), 
-- Khách hàng
('user1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Thị Ngọc Trâm', 'ngoctram20092005@gmail.com', N'456 Phố Nhỏ', '0903333444', 2, 1), 
-- Tài khoản Nhân viên
('staff1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Nguyễn Văn Nhân Viên', 'staff1@gmail.com', N'789 Đường Kho', '0911222333', 3, 1),
-- Tài khoản Shipper
('shipper1', '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi', N'Trần Văn Tài Xế', 'shipper1@gmail.com', N'101 Đường Vận Chuyển', '0944555666', 4, 1);

-- 3. Tạo 8 Danh mục sản phẩm (Categories)
SET IDENTITY_INSERT Category ON;
INSERT INTO Category (id, name) VALUES 
(1, N'Táo'), (2, N'Nho'), (3, N'Cam và Quýt'), (4, N'Cherry và Dâu tây'), 
(5, N'Kiwi và Lê'), (6, N'Trái cây nhiệt đới nhập khẩu'), 
(7, N'Trái cây mọng nước'), (8, N'Trái cây họ hàng dưa');
SET IDENTITY_INSERT Category OFF;

-- 4. Tạo Sản phẩm mẫu (Products)
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

-- 5. Tạo dữ liệu ảnh (Copy ảnh đại diện vào bảng Product_Image làm ảnh chính)
INSERT INTO Product_Image (product_id, image_url, is_main)
SELECT id, image, 1 FROM Product WHERE image IS NOT NULL;

-- 6. Tạo dữ liệu Voucher mẫu
INSERT INTO Voucher (code, description, discount_percent, min_condition, quantity, active) VALUES
('WELCOME', N'Chào bạn mới', 10, 0, 1000, 1),
('FREESHIP', N'Miễn phí vận chuyển', 0, 500000, 500, 1);

-- 7. Tạo Bài viết tin tức (News)
INSERT INTO News (title, content, image, account_username) VALUES 
(N'Lợi ích tuyệt vời của Táo Envy', N'<p>Táo Envy không chỉ ngon mà còn giúp đẹp da...</p>', 'imgs/Tao_Envy_New_Zealand.jpg', 'admin'),
(N'Cách bảo quản Nho mẫu đơn tươi lâu', N'<p>Để nho luôn tươi, bạn cần bảo quản trong ngăn mát...</p>', 'imgs/Nho_Mau_Don_Shine_Muscat_Han_Quoc.jpg', 'admin'),
(N'Chương trình khuyến mãi mùa hè', N'<p>Giảm giá 20% cho các loại trái cây nhiệt đới...</p>', 'imgs/Dua_Hau_Khong_Hat_Thai_Lan.jpg', 'admin');

-- 8. Tạo dữ liệu Liên hệ mẫu
INSERT INTO Contact (full_name, email, subject, message) VALUES 
(N'Nguyễn Văn A', 'khachhangA@gmail.com', N'Hỏi về giá sỉ', N'Shop có bán sỉ thùng 10kg Nho không?'),
(N'Trần Thị B', 'khachhangB@gmail.com', N'Phàn nàn giao hàng', N'Shipper giao hàng hơi chậm nha shop.');

-- 9. Cấu hình thông tin Shop
INSERT INTO Shop_Info (shop_name, address, phone, email, logo_url, facebook_link) 
VALUES (
    N'Trái Cây Bay - Fresh & Healthy', 
    N'123 Đường Cầu Giấy, Hà Nội', 
    '0988.888.888', 
    'contact@traicaybay.com', 
    'imgs/logo.png',
    'https://facebook.com/traicaybay'
);

-- 10. Tạo trang tĩnh (Giới thiệu)
INSERT INTO Static_Page (slug, title, content, image_url) 
VALUES (
    'gioi-thieu', 
    N'Về Trái Cây Bay - Sứ Mệnh & Tầm Nhìn', 
    N'<p>Chào mừng bạn đến với <b>Trái Cây Bay</b>. Chúng tôi được thành lập vào năm 2025...</p>', 
    'imgs/banner-gioi-thieu.jpg'
);

-- 11. Test thử Trigger và tương tác
-- User1 Like bài viết số 1
INSERT INTO News_Like (news_id, username) VALUES (1, 'user1');
-- User1 Share bài viết số 1
INSERT INTO News_Share (news_id, username, platform) VALUES (1, 'user1', 'Facebook');
-- User1 Bình luận
INSERT INTO News_Comment (news_id, username, content, parent_id) VALUES (1, 'user1', N'Bài viết rất bổ ích, cảm ơn shop!', NULL);
-- Admin trả lời bình luận
INSERT INTO News_Comment (news_id, username, content, parent_id) VALUES (1, 'admin', N'Cảm ơn bạn đã ủng hộ Trái Cây Bay ạ!', 1);







-- Cập nhật thông tin người nhận cho đơn hàng mẫu (ví dụ đơn id = 1)
UPDATE Orders SET 
    recipient_name = N'Nguyễn Công Việt', 
    recipient_phone = '0901111222', 
    shipping_fee = 30000 
WHERE id = 1;

-- 12. Cập nhật tồn kho (Để sẵn sàng test mua hàng)
UPDATE Product SET quantity = 50.0 WHERE quantity = 0;
GO


-- PHẦN BỔ SUNG: MÃ HÓA MẬT KHẨU CHO SPRING SECURITY
-- Bạn phải thay thế '[CHUỖI_BCRYPT_ĐÃ_MÃ_HÓA]' bằng chuỗi hash BCrypt thực tế của "123456"
UPDATE Account 
SET password = '$2a$10$HJhN01nLwmoMWBQ72nzn5OZi9LgWpLD/NezmpPyYpqa3MO3ASKEwi'
WHERE username IN ('admin', 'user1');
-- Ví dụ thực tế:
-- UPDATE Account SET password = '$2a$10$LgL4K625zT8jLg7FpM8Qk.J.y8D7N4.M1X5Y5A8C9O5P6W2X0I3G' WHERE username IN ('admin', 'user1');







