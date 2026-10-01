# KhoaVeyonService

[English](README.md) | **Tiếng Việt**

Một file batch duy nhất cho Windows, bổ sung các chức năng quản lý lớp học cho [Veyon](https://veyon.io): đóng cưỡng bức ứng dụng, chặn internet (vẫn giữ mạng LAN), chỉ cho phép một số trang web, chặn ứng dụng, khóa Task Manager và Settings, và tắt tiếng loa.

Mỗi chức năng là một tham số (switch) dòng lệnh, nên có thể chạy riêng từng chức năng bằng tính năng **Run program** của Veyon.

```
C:\cmd\KhoaVeyonService.bat -blockall
```

> Đây là một script độc lập, không do Veyon tạo ra và không liên kết với Veyon. Nó **không phải** add-on *Internet Access Control* trả phí của veyon.io; đây là giải pháp miễn phí dựa trên luật của Windows Firewall.

---

## Mục lục

- [Tính năng](#tính-năng)
- [Yêu cầu](#yêu-cầu)
- [Cài đặt](#cài-đặt)
- [Các tham số](#các-tham-số)
- [File danh sách Excel](#file-danh-sách-excel)
- [Thêm chức năng vào Veyon](#thêm-chức-năng-vào-veyon)
- [Cách hoạt động](#cách-hoạt-động)
- [Hạn chế](#hạn-chế)
- [Khắc phục sự cố](#khắc-phục-sự-cố)
- [Gỡ cài đặt](#gỡ-cài-đặt)
- [Lưu ý bảo mật](#lưu-ý-bảo-mật)

---

## Tính năng

| Tính năng | Tham số |
|---|---|
| Đóng cưỡng bức tất cả ứng dụng đang mở | `-killapp` |
| Đóng cưỡng bức tất cả, trừ các ứng dụng trong danh sách | `-keepapp` |
| Chặn toàn bộ internet, vẫn giữ LAN và Veyon hoạt động | `-blockall` |
| Chặn internet, trừ các trang trong file Excel | `-allowpage` |
| Cho phép internet trở lại | `-allowall` |
| Chặn ứng dụng hoặc thư mục trong file Excel | `-blockapp` |
| Bỏ chặn các ứng dụng đó | `-unblockapp` |
| Tắt Task Manager và Settings/Control Panel | `-lockdown` |
| Bật lại chúng | `-unlock` |
| Tắt tiếng / bật tiếng loa | `-mute`, `-unmute` |

Điểm khác:

- Chỉ một file, không cần biên dịch, không cần công cụ bên thứ ba.
- **Không cần** cài Excel trên các máy. Các danh sách `.xlsx` được đọc trực tiếp.
- Không lưu mật khẩu admin trong script.
- Thiết kế cho lớp học dùng tài khoản học sinh thường (không phải admin).

## Yêu cầu

- Windows 10 hoặc 11 trên các máy học sinh (dùng Windows PowerShell 5.1 có sẵn).
- Veyon đã cài trên máy giáo viên và các máy học sinh. Các chức năng được chạy bằng tính năng **Run program** của Veyon.
- **Windows Defender Firewall phải bật**, và dịch vụ của nó (`mpssvc`) phải đang chạy. Việc chặn internet hoạt động bằng cách thêm luật tường lửa, nên nếu tường lửa tắt thì không có tác dụng.
- Tài khoản học sinh không có quyền quản trị.
- Script phải được cài trong thư mục `C:\cmd` trên mọi máy học sinh.
- Cần quản trị viên cho phép một lần trên mỗi máy (xem [Cài đặt](#cài-đặt)).

## Cài đặt

Làm **một lần trên mỗi máy học sinh**.

1. Tạo thư mục `C:\cmd` và chép `KhoaVeyonService.bat` vào đó. Chép luôn các file danh sách Excel vào đây (xem [File danh sách Excel](#file-danh-sách-excel)).
2. Chạy cài đặt bằng tài khoản quản trị của máy đó. Trong Command Prompt:
   ```
   C:\cmd\KhoaVeyonService.bat -install
   ```
   Windows sẽ hỏi tên và mật khẩu admin trong cửa sổ UAC.
3. Khi thấy dòng `Install done` là xong.

`-install` làm hai việc:

- Tạo một dịch vụ Windows nhỏ cho mỗi chức năng cần quyền admin (`KhoaVeyonService_blockall`, `_allowpage`, `_allowall`, `_blockapp`, `_unblockapp`). Người dùng thường được phép **khởi động** các dịch vụ này nhưng không được sửa chúng.
- Đặt `C:\cmd` ở chế độ chỉ đọc với người dùng thường, để học sinh không sửa được script hay các danh sách.

### Cổng tường lửa

Nếu trước đây tường lửa bị tắt, hãy chắc chắn Veyon vẫn kết nối được với các máy học sinh:

```
netsh advfirewall firewall add rule name="Veyon Server" dir=in action=allow protocol=TCP localport=11100 profile=any
```

Trên máy giáo viên, mở thêm cổng `11400` cho tính năng Demo của Veyon. Đây là cổng mặc định của Veyon; nếu bạn đã đổi thì dùng cổng của bạn. Không cần chuyển tiếp cổng (port forwarding).

## Các tham số

| Tham số | Cần `-install`? | Chức năng |
|---|---|---|
| `-install` | - | Cài đặt một lần (cần quyền admin). |
| `-uninstall` | - | Gỡ các dịch vụ, luật tường lửa và các chặn ứng dụng. |
| `-killapp` | Không | Đóng cưỡng bức mọi ứng dụng trong phiên của người dùng đang đăng nhập. Không bao giờ đóng giao diện Windows, Veyon, cmd và PowerShell. |
| `-keepapp` | Không | Giống `-killapp` nhưng giữ lại các ứng dụng trong `KeepAppList.xlsx`. |
| `-blockall` | Có | Chặn toàn bộ internet. LAN, localhost và Veyon vẫn hoạt động. Cũng chặn internet IPv6. |
| `-allowpage` | Có | Chặn internet, trừ các trang trong `AllowPage.xlsx` (và máy chủ DNS của máy). |
| `-allowall` | Có | Gỡ chặn internet. |
| `-blockapp` | Có | Chặn không cho chạy các file hoặc thư mục trong `BlockAppList.xlsx`, và đóng các bản đang mở. |
| `-unblockapp` | Có | Gỡ các chặn đó. |
| `-lockdown` | Không | Tắt Task Manager và Settings/Control Panel cho người dùng đang đăng nhập. |
| `-unlock` | Không | Hoàn tác `-lockdown`. `-unlockdown` cũng dùng được. |
| `-mute` | Không | Tắt tiếng loa mặc định. |
| `-unmute` | Không | Bật tiếng lại. |

Chạy không có tham số (hoặc tham số sai) sẽ in ra dòng hướng dẫn cách dùng.

Việc chặn internet vẫn còn sau khi khởi động lại máy, cho đến khi bạn chạy `-allowall`.

## File danh sách Excel

Tạo các file này trong `C:\cmd`. Dùng **cột A của sheet đầu tiên**, mỗi dòng một mục. Có thể có dòng tiêu đề (sẽ bị bỏ qua nếu không giống một trang web hoặc đường dẫn). Chỉ đọc file `.xlsx`.

### `AllowPage.xlsx`

Các trang được phép khi dùng `-allowpage`:

```
Site
wikipedia.org
vietjack.vn
```

Script tự xử lý `https://`, đường dẫn phía sau và `www.`.

### `BlockAppList.xlsx`

Đường dẫn đầy đủ của chương trình hoặc thư mục cần chặn bằng `-blockapp`. Hỗ trợ ký tự đại diện và biến môi trường:

```
Path
C:\Program Files\Google\Chrome\Application\chrome.exe
C:\Games\*.exe
C:\Users\Public\Games
```

Mọi thứ trong `C:\Windows`, thư mục Veyon, `C:\cmd` và ổ đĩa gốc sẽ bị bỏ qua có chủ ý, để gõ nhầm cũng không làm hỏng máy.

### `KeepAppList.xlsx`

Các ứng dụng mà `-keepapp` giữ lại. Dùng tên chương trình (có hoặc không có `.exe`) hoặc đường dẫn đầy đủ:

```
App
chrome
mathgame.exe
C:\Games\KidsLearning
```

### Đổi thư mục chứa danh sách

Mặc định các danh sách được đọc từ `C:\cmd\`. Để dùng chung một bản cho mọi máy, hãy đổi `LISTDIR` ở đầu script thành đường dẫn mạng (giữ dấu `\` ở cuối). Thư mục chia sẻ phải đọc được bởi tài khoản máy tính (với các chức năng cần admin) và bởi tài khoản học sinh (với `-keepapp`).

Vì `-install` đặt `C:\cmd` chỉ đọc với người dùng thường, bạn cập nhật danh sách bằng tài khoản quản trị.

## Thêm chức năng vào Veyon

1. Mở **Veyon Configurator** và vào **Programs & websites** (tên mục tùy phiên bản; ở bản cũ nằm trong **Master**).
2. Thêm mỗi chức năng một mục. Lệnh là đường dẫn script cộng với tham số:

| Tên | Lệnh |
|---|---|
| Đóng tất cả ứng dụng | `C:\cmd\KhoaVeyonService.bat -killapp` |
| Đóng tất cả trừ danh sách | `C:\cmd\KhoaVeyonService.bat -keepapp` |
| Chặn internet | `C:\cmd\KhoaVeyonService.bat -blockall` |
| Chỉ cho phép các trang trong danh sách | `C:\cmd\KhoaVeyonService.bat -allowpage` |
| Cho phép internet | `C:\cmd\KhoaVeyonService.bat -allowall` |
| Chặn ứng dụng | `C:\cmd\KhoaVeyonService.bat -blockapp` |
| Bỏ chặn ứng dụng | `C:\cmd\KhoaVeyonService.bat -unblockapp` |
| Khóa (Lockdown) | `C:\cmd\KhoaVeyonService.bat -lockdown` |
| Mở khóa (Unlock) | `C:\cmd\KhoaVeyonService.bat -unlock` |
| Tắt tiếng | `C:\cmd\KhoaVeyonService.bat -mute` |
| Bật tiếng | `C:\cmd\KhoaVeyonService.bat -unmute` |

3. Bấm **Apply**.
4. Trong **Veyon Master**, chọn các máy học sinh, bấm **Run program** và chọn mục cần dùng.

## Cách hoạt động

**Run program** của Veyon chạy lệnh dưới quyền học sinh đang đăng nhập, và học sinh không có quyền admin. Thay đổi tường lửa cần quyền admin, nên script dùng hai đường:

- **Chức năng cần quyền admin** (`-blockall`, `-allowpage`, `-allowall`, `-blockapp`, `-unblockapp`): khi học sinh chạy, script nhờ dịch vụ SYSTEM tương ứng chạy. Dịch vụ khởi động chính script đó với quyền admin và thực hiện công việc bằng PowerShell.
- **Chức năng ở mức người dùng** (`-killapp`, `-keepapp`, `-lockdown`, `-unlock`, `-mute`, `-unmute`): chạy trực tiếp trong phiên của học sinh, không cần quyền admin hay dịch vụ.

Chi tiết:

- **Chặn internet** thêm hai luật tường lửa chiều đi ra là `KhoaVeyonBlock` và `KhoaVeyonBlock6`. Chúng chặn mọi địa chỉ, trừ các dải mạng LAN riêng (`10.x`, `172.16-31.x`, `192.168.x`), localhost, link-local, multicast và broadcast.
- **`-allowpage`** tra cứu địa chỉ IP của từng trang trong danh sách và loại chúng khỏi các dải bị chặn. Máy chủ DNS của máy cũng được cho phép.
- **`-blockapp`** thêm quyền *từ chối Execute* cho nhóm Users trên từng file hoặc thư mục, và ghi đường dẫn vào `blocked.txt` để `-unblockapp` hoàn tác.
- **`-lockdown`** đặt chính sách `DisableTaskMgr` và `NoControlPanel` cho người dùng hiện tại.
- **`-mute`** dùng Windows Core Audio API để tắt tiếng thiết bị phát mặc định.

Mã PowerShell nằm ở cuối file `.bat`, sau dấu hiệu `#PS1START`. Không viết đoạn chữ đó ở chỗ nào khác trong file.

## Hạn chế

- **`-allowpage` hoạt động theo địa chỉ IP, không theo tên miền.** Các trang lớn dùng nhiều tên miền hoặc CDN (ví dụ YouTube, Google) có thể chỉ tải được một phần, và địa chỉ IP thay đổi theo thời gian. Chạy lại `-allowpage` để làm mới. Nếu cần lọc trang web đáng tin cậy, hãy dùng bộ lọc DNS ở router.
- **Máy chủ proxy trong mạng LAN sẽ vô hiệu hóa việc chặn.** Nếu các máy ra internet qua proxy có địa chỉ LAN, lưu lượng đó trông như lưu lượng LAN và được cho phép. Kiểm tra bằng `netsh winhttp show proxy`.
- **Tường lửa hoặc phần mềm diệt virus của bên thứ ba** quản lý Windows Firewall có thể ghi đè các luật này.
- **Kết nối đang mở** có thể còn tồn tại một lúc. Đóng hẳn rồi mở lại trình duyệt để thấy việc chặn có hiệu lực ngay.
- **`-blockapp`** cũng ảnh hưởng đến quản trị viên cho đến khi bạn chạy `-unblockapp`. Nó không chặn ứng dụng Microsoft Store (UWP). Học sinh vẫn có thể chép chương trình bị chặn sang vị trí khác.
- **`-lockdown` và `-mute`** chỉ áp dụng cho tài khoản đang đăng nhập. Học sinh vẫn có thể bật tiếng bằng phím âm lượng.
- **Windows có thể ghi nhật ký "service did not respond" (lỗi 1053)** cho các dịch vụ. Điều này là bình thường: các dịch vụ này không phải chương trình dịch vụ thật, nhưng lệnh vẫn chạy.
- Chỉ xử lý sheet đầu tiên của file Excel.

## Khắc phục sự cố

**Không có gì xảy ra.**
Xem file nhật ký. Các chức năng cần admin ghi vào `C:\cmd\KhoaVeyonService.log`; các chức năng mức người dùng ghi vào `%TEMP%\KhoaVeyonService.log` của học sinh đang đăng nhập. Nhật ký ghi lại từng hành động, file danh sách bị thiếu và đường dẫn bị bỏ qua.

**Báo `Service not installed`.**
Chạy `-install` bằng tài khoản quản trị của máy.

**Vẫn vào được internet sau `-blockall`.**
Kiểm tra theo thứ tự:
1. Tường lửa đang bật: `netsh advfirewall show allprofiles state`
2. Luật đã tồn tại: `netsh advfirewall firewall show rule name="KhoaVeyonBlock"`
3. Không có proxy: `netsh winhttp show proxy`
4. `ping 8.8.8.8` thất bại sau khi chặn, còn `ping <IP máy giáo viên>` vẫn thông.

**Máy biến mất khỏi Veyon Master sau khi bật tường lửa.**
Thêm luật cho phép cổng 11100 chiều đi vào (xem [Cổng tường lửa](#cổng-tường-lửa)).

**`-mute` không có tác dụng.**
Đảm bảo máy có thiết bị phát âm thanh đang hoạt động. Xem nhật ký để biết nội dung lỗi.

## Gỡ cài đặt

Chạy bằng quyền quản trị trên mỗi máy:

```
C:\cmd\KhoaVeyonService.bat -uninstall
```

Lệnh này gỡ việc chặn internet, các chặn ứng dụng và các dịch vụ. Sau đó bạn có thể xóa `C:\cmd`. `-lockdown` và `-mute` là thiết lập theo từng người dùng, nên nếu còn đang bật hãy chạy `-unlock` và `-unmute` dưới tài khoản học sinh.

## Lưu ý bảo mật

- Script **không chứa mật khẩu**. Quyền admin được cấp một lần khi cài đặt, qua hộp thoại UAC của Windows.
- Các dịch vụ chạy script dưới quyền SYSTEM, nên ai sửa được `C:\cmd` đều có thể chạy lệnh với quyền SYSTEM. Vì vậy `-install` đặt thư mục này chỉ đọc với người dùng thường. Hãy để học sinh dùng tài khoản thường và không cấp quyền ghi vào thư mục này.
- Hãy thông báo cho học sinh và phụ huynh rằng các công cụ lớp học có thể hạn chế máy tính, phù hợp với quy định của nhà trường.

## Giấy phép

Hãy thêm giấy phép bạn chọn (ví dụ MIT) trước khi đăng lên.
