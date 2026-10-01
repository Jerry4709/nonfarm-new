# NonfarmRich EA v2.0 — News Straddle Stop Orders

Expert Advisor สำหรับ MetaTrader 5 ที่ตั้ง **Buy Stop + Sell Stop** (2 คู่) ดักจับราคาตอนข่าวออก

## 📁 ไฟล์ในโปรเจค

| ไฟล์ | คำอธิบาย |
|------|----------|
| `NonfarmRich_v1.mq5` | เวอร์ชันดั้งเดิม (v1.0) |
| `NonfarmRich_v2.mq5` | เวอร์ชันใหม่ (v2.0) พร้อมฟีเจอร์เพิ่มเติม |
| `tools/NonfarmRich_KeyGenerator.mq5` | Script สร้าง License Key |
| `update/version.txt` | ไฟล์ตรวจสอบ Auto-Update |

---

## 🆕 ฟีเจอร์ใหม่ใน v2.0

### 🔑 License Key System
- ใส่ License Key ใน input parameter `LicenseKey`
- รูปแบบ: `NFARM-XXXXX-XXXXX`
- ใช้ `tools/NonfarmRich_KeyGenerator.mq5` เพื่อสร้าง key
- ถ้า key ไม่ถูกต้อง EA จะแสดงบนชาร์ตแต่ **ไม่เปิดเทรด**
- ในโหมด Strategy Tester ไม่ต้องใส่ key

### 🔄 Auto-Update (ออนไลน์)
- EA ตรวจสอบเวอร์ชันล่าสุดอัตโนมัติเมื่อเริ่มทำงาน
- ถ้ามีอัพเดท → ดาวน์โหลดไฟล์ใหม่ไปที่ `MQL5\Files\`
- **ตั้งค่า**: เพิ่ม URL ใน MT5:
  - ไปที่ `Tools > Options > Expert Advisors`
  - เพิ่ม `https://raw.githubusercontent.com` ในช่อง Allow WebRequest

### 🛡️ Spike Guard (ป้องกันข่าวกระชากก่อนเวลา)
- ตรวจจับราคาวิ่งแรงผิดปกติก่อนเวลาข่าว
- ทำงานเฉพาะ X นาทีก่อนข่าว (ตั้งค่าได้)
- เมื่อตรวจพบ spike:
  - **Widen Pending**: เลื่อน pending order ออกไกลขึ้น
  - **Disable Price Track**: ปิดการเลื่อนตามราคา
  - **Both**: ทำทั้งสองอย่าง
- **เปิด/ปิดได้** ผ่านปุ่มบน panel (ช่วงทดสอบ)

### 🔀 Cancel Opposite Toggle
- เลือกได้ว่าจะลบ Pending ฝั่งตรงข้ามหรือไม่เมื่อ order ถูก execute
- **ON** = ลบฝั่งตรงข้าม (พฤติกรรมเดิม)
- **OFF** = เก็บ pending ทั้งสองฝั่งไว้
- Toggle ได้จากปุ่มบน panel

---

## 🔧 Bug Fixes จาก v1.0

| # | ปัญหา | ระดับ | แก้ไข |
|---|--------|-------|-------|
| 1 | Ticket หลุดเมื่อ restart EA | 🔴 Critical | เก็บ ticket ใน GlobalVariable |
| 2 | ตรวจจับ execution ผิดฝั่ง | 🔴 Critical | ใช้ HasPositionByMagic() ตรวจ position จริง |
| 3 | OrderDelete ไม่เช็คสถานะ | 🔴 Critical | SafeCancelOrder() ตรวจ ORDER_STATE |
| 4 | Modify ถี่เกินไป (ทุก tick) | 🟠 High | Throttle 500ms + min 5 points |
| 5 | Filling type hardcode FOK | 🟠 High | Auto-detect ตามโบรกเกอร์ |
| 6 | TP/SL Order#2 คำนวณจากราคา Order#1 | 🟠 High | คำนวณจากราคา entry ของ Order#2 |
| 7 | `ordersOpened` ไม่ sync กับสถานะจริง | 🟡 Medium | SyncOrderState() ทุก tick |
| 8 | ไม่มี retry logic | 🟡 Medium | Retry 3 ครั้งใน SendPendingOrder |
| 9 | SL=0 ไม่มี safety net | 🟡 Medium | Emergency SL parameter |
| 10 | ใช้ OnTradeTransaction | 🟢 Low | Event-driven execution check |

---

## 📦 วิธีติดตั้ง

1. คัดลอก `NonfarmRich_v2.mq5` ไปที่ `MQL5\Experts\`
2. คัดลอก `tools\NonfarmRich_KeyGenerator.mq5` ไปที่ `MQL5\Scripts\`
3. Compile ทั้งสองไฟล์ใน MetaEditor
4. รัน Script `NonfarmRich_KeyGenerator` เพื่อสร้าง License Key
5. แนบ EA `NonfarmRich_v2` บนชาร์ต ใส่ License Key ที่สร้างไว้

### ตั้งค่า Auto-Update
- ไปที่ `Tools > Options > Expert Advisors`
- ✅ Allow WebRequest for listed URL
- เพิ่ม: `https://raw.githubusercontent.com`

---

## 📝 Changelog

### v2.0.0 (2026-10-02)
- เพิ่มระบบ License Key
- เพิ่ม Auto-Update ออนไลน์
- เพิ่ม Spike Guard ป้องกันข่าวกระชาก
- เพิ่ม Cancel Opposite Toggle
- แก้ไข bug 10 รายการจาก v1.0
- UI Dark Theme ใหม่
- Ticket persistence ผ่าน GlobalVariable
- OnTradeTransaction event-driven

### v1.0.0
- เวอร์ชันแรก: Buy/Sell Stop 2 คู่
- Price Tracking, Trailing Stop
- News Countdown, Auto-open
- Lot Calculation from margin
