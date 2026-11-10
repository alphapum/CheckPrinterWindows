# Printer Status Dashboard — คู่มือการติดตั้ง

**เวอร์ชัน:** 1.1.0
**ผู้พัฒนา:** eatppv
**ติดต่อ:** 099-491-6445

โปรแกรมเช็คสถานะ printer ทุกเครื่องในเครื่องนี้ พร้อมปุ่มแก้ปัญหาพิมพ์ไม่ออก (Restart Spooler) และลบงานพิมพ์ที่ค้าง (Clear Queue)

---

## ความต้องการของระบบ

- Windows 10 / 11
- Windows PowerShell 5.1 (มีมากับ Windows อยู่แล้ว)
- สิทธิ์ Administrator (สำหรับปุ่ม Restart Spooler และ Clear Queue) — ดูสถานะอย่างเดียวไม่ต้องใช้

---

## วิธีที่ 1: ติดตั้งด้วย `PrinterDashboard-Setup.exe` (แนะนำ)

1. ดับเบิลคลิก `PrinterDashboard-Setup.exe`
2. ถ้า Windows SmartScreen เตือน (เพราะไฟล์ไม่ได้เซ็นชื่อ) ให้กด **More info** แล้วกด **Run anyway**
3. รอจนขึ้นข้อความ "ติดตั้งเรียบร้อยแล้ว"
4. เปิดโปรแกรมจากไอคอน **Printer Dashboard** บน Desktop หรือใน Start Menu
5. กด **Yes** ที่หน้าต่าง UAC — ไอคอนถูกตั้งให้รันแบบ Administrator ทุกครั้ง

**ติดตั้งไปที่:** `%LOCALAPPDATA%\PrinterDashboard`
(ตัวติดตั้งไม่ต้องใช้สิทธิ์ Administrator)

---

## วิธีที่ 2: ใช้งานโดยไม่ติดตั้ง

เก็บ 3 ไฟล์นี้ไว้ในโฟลเดอร์เดียวกัน:

- `PrinterDashboard.hta`
- `Dashboard-Runner.ps1`
- `PrinterLib.ps1`

จากนั้นดับเบิลคลิก `Start-Dashboard.cmd` (ไฟล์นี้จะขอสิทธิ์ Administrator ให้เอง)

> ห้ามเปิด `PrinterDashboard.hta` ตรงๆ ถ้าต้องการใช้ปุ่ม Restart Spooler / Clear Queue
> เพราะไฟล์ `.hta` ไม่มีเมนู "Run as administrator"

---

## วิธีถอนการติดตั้ง

**วิธีที่ 1 (แนะนำ):** เปิด **Settings > Apps > Installed apps** หา **Printer Dashboard** แล้วกด **Uninstall**

**วิธีที่ 2:** ดับเบิลคลิก `Uninstall.cmd` ในโฟลเดอร์ `%LOCALAPPDATA%\PrinterDashboard`

ทั้งสองวิธีจะถามยืนยันก่อน แล้วลบให้ครบ:
- โฟลเดอร์ `%LOCALAPPDATA%\PrinterDashboard`
- ไอคอนบน Desktop และโฟลเดอร์ใน Start Menu
- รายการใน Settings > Apps
- ไฟล์ชั่วคราวใน `%TEMP%`

**ลบด้วยมือ (กรณีตัวถอนใช้ไม่ได้):** ลบโฟลเดอร์ติดตั้ง, ไอคอนบน Desktop, โฟลเดอร์ `Printer Dashboard` ใน Start Menu
(`%APPDATA%\Microsoft\Windows\Start Menu\Programs`) และ registry key
`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\PrinterDashboard`

---

## สร้างตัวติดตั้งใหม่ (สำหรับผู้พัฒนา)

หลังแก้ไฟล์ `.hta` หรือ `.ps1` ให้รัน:

```
installer\Build-Installer.cmd
```

จะได้ไฟล์ `PrinterDashboard-Setup.exe` ใหม่ในโฟลเดอร์ `scripts`

> **หมายเหตุ:** ไฟล์ `.ps1` ที่มีข้อความภาษาไทยต้องบันทึกเป็น **UTF-8 with BOM**
> ไม่เช่นนั้น PowerShell 5.1 จะอ่านผิดและโปรแกรมจะแจ้งว่าไม่ได้รัน as Administrator ทั้งที่รันอยู่

---

## แก้ปัญหาเบื้องต้น

| อาการ | วิธีแก้ |
|---|---|
| ขึ้นแบนเนอร์ "ยังไม่ได้สิทธิ์ Administrator" | เปิดผ่านไอคอนที่ติดตั้ง หรือ `Start-Dashboard.cmd` แล้วกด Yes ที่ UAC |
| ปุ่ม Restart Spooler / Clear Queue กดไม่ได้ | เหมือนข้างบน — ต้องรันแบบ Administrator |
| ขึ้น "ไม่ได้รับผลลัพธ์จาก PowerShell" | ตรวจว่ามี `Dashboard-Runner.ps1` และ `PrinterLib.ps1` อยู่โฟลเดอร์เดียวกับ `.hta` |
| มีปัญหาอื่น | ดูไฟล์ `dashboard-error.log` ในโฟลเดอร์ติดตั้ง แล้วติดต่อผู้พัฒนา |

---

## ติดต่อ

eatppv — 099-491-6445
