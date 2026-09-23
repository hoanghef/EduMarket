# Sao lưu và khôi phục PostgreSQL

Tài liệu này mô tả quy trình an toàn cho môi trường phát triển/demo của EduMarket. Không commit file backup: thư mục `backups/` và phần mở rộng backup/dump đã được `.gitignore` bỏ qua.

## Điều kiện trước khi thực hiện

- Cài PostgreSQL client tools (`pg_dump`, `pg_restore`; cần thêm `createdb` nếu tự tạo database thử nghiệm).
- Đặt `DATABASE_URL` trong môi trường hoặc truyền bằng tham số. Không ghi mật khẩu trong script, lịch sử lệnh dùng chung hoặc tài liệu.
- Dừng backend/worker đang ghi dữ liệu nếu cần snapshot nhất quán cho môi trường production.

Ví dụ PowerShell (chỉ máy cá nhân, không in URL):

```powershell
$env:DATABASE_URL = 'postgresql://USER:PASSWORD@HOST:5432/edumarket?schema=public'
```

## Sao lưu

Từ thư mục gốc repository:

```powershell
.\backend\scripts\Backup-EduMarket.ps1
```

Script dùng `pg_dump --format=custom --no-owner --no-privileges` và tạo file `.backup` có timestamp trong `backups/`. Có thể chọn vị trí khác:

```powershell
.\backend\scripts\Backup-EduMarket.ps1 -OutputDirectory C:\safe-backups
```

## Kiểm tra archive không phá hủy

```powershell
.\backend\scripts\Test-EduMarketBackup.ps1 -BackupFile .\backups\edumarket-YYYYMMDD-HHMMSS.backup
```

Lệnh này chạy `pg_restore --list`; nó chỉ đọc archive, không kết nối hay ghi đè database.

## Khôi phục vào database thử nghiệm sạch

Tạo database rỗng riêng biệt (ví dụ tên `edumarket_restore_check`) bằng tài khoản PostgreSQL có quyền tạo database. Sau đó dùng URL của **database thử nghiệm**, không dùng URL development chính:

```powershell
$restoreUrl = 'postgresql://USER:PASSWORD@HOST:5432/edumarket_restore_check?schema=public'
.\backend\scripts\Restore-EduMarketBackup.ps1 `
  -BackupFile .\backups\edumarket-YYYYMMDD-HHMMSS.backup `
  -DatabaseUrl $restoreUrl `
  -Force
```

Sau khi khôi phục, xác minh:

```powershell
$env:DATABASE_URL = $restoreUrl
cd backend
npx prisma migrate status
npm test
```

`npm test` dùng dữ liệu test riêng và dọn dẹp sau test; không dùng database thật có dữ liệu người dùng.

## Cảnh báo khi khôi phục

- `Restore-EduMarketBackup.ps1` yêu cầu `-Force` vì dùng `--clean --if-exists` và có thể xóa object trong database đích.
- Luôn kiểm tra hostname/tên database trong URL, tạo backup mới của database đích, và ưu tiên database disposable.
- Không khôi phục đè database development/production đang dùng; không thử restore trên production trong phạm vi demo.
- Archive có thể chứa dữ liệu cá nhân demo. Bảo vệ nơi lưu, mã hóa nếu cần và không gửi kèm source code.
