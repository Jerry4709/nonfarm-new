# NonfarmRich EA v3.3
Expert Advisor สำหรับเทรดชนข่าว Non-Farm Payrolls (และข่าวแรงอื่นๆ) พร้อมระบบป้องกันความเสี่ยงขั้นสูง เช่น Spike Guard, Anti-Whipsaw และ Smart Auto-Close

## ?? คำอธิบาย Input (พารามิเตอร์การตั้งค่า)

### ?? License Settings
* **LicenseKey**: คีย์สำหรับใช้งาน EA หากตั้งเป็น "AUTO_LOAD" ระบบจะโหลดคีย์ที่เคยบันทึกไว้ในเครื่องขึ้นมาใช้โดยอัตโนมัติ

### ?? Auto-Update
* **EnableAutoUpdate**: เปิด/ปิด การเช็คเวอร์ชันอัพเดทใหม่ตอนที่ลาก EA ลงกราฟ (แนะนำให้เปิดไว้)

### ?? Pending Orders (ตั้งค่าออเดอร์ล่วงหน้า)
* **BuyStopPoints**: ระยะห่างจากราคาปัจจุบัน (Current Price) ที่จะวางไม้ Buy Stop (หน่วยเป็นจุด/Points)
* **SellStopPoints**: ระยะห่างจากราคาปัจจุบัน ที่จะวางไม้ Sell Stop (หน่วยเป็นจุด/Points)
* **SL_Points**: ระยะ Stop Loss แบบคงที่ (0 = ปิดการใช้งาน แนะนำให้ใช้ 0 แล้วไปใช้ระบบ Anti-Whipsaw/Trailing แทน)
* **Order2GapPoints**: ระยะห่างของไม้ที่ 2 จากไม้แรก (เพื่อให้ไม้ 1 และไม้ 2 ได้ราคาต่างกันเล็กน้อย)

### ?? Take Profit Settings (ตั้งค่าจุดทำกำไร)
* **TP_Points_Order1**: ระยะเป้าหมายทำกำไร (Take Profit) สำหรับไม้ที่ 1 (หน่วยเป็นจุด)
* **TP_Points_Order2**: ระยะเป้าหมายทำกำไรสำหรับไม้ที่ 2 (หน่วยเป็นจุด)

### ?? Lot Size Settings (ตั้งค่าขนาดหลอด)
* **LotSize_Order1**: ขนาด Lot ปกติสำหรับไม้ที่ 1
* **LotSize_Order2**: ขนาด Lot ปกติสำหรับไม้ที่ 2
* **UseCalculatedLots**: เปิด/ปิด การใช้ Lot Size ที่คำนวณจากความเสี่ยง (% Risk) แทนการตั้งค่าหลอดคงที่ข้างต้น
* **RiskPercentage**: ระดับความเสี่ยง (%) ของ Margin ที่ต้องการใช้คำนวณ Lot (ทำงานเมื่อเปิด UseCalculatedLots)

### ?? Trailing Stop - Order 1 & 2 (ระบบล็อคกำไร)
* **TrailingStartPoints**: จุดเริ่มต้นทำงานของ Trailing Stop (ตัวอย่าง: เมื่อกำไรถึง 300 จุด ให้เริ่มขยับ SL)
* **TrailingStepPoints**: ขยับ SL ตามราคาเมื่อราคาวิ่งนำไปทุกๆ กี่จุด
* **TrailingDistancePoints**: รักษาระยะห่างของ SL กับราคาปัจจุบันไว้กี่จุด
*(หมายเหตุ: Order 1 และ Order 2 แยกตั้งค่าอิสระจากกัน สามารถตั้งไม้หนึ่งปิดไว อีกไม้หนึ่งทนรันเทรนด์ได้)*

### ? News Countdown (ระบบนับเวลาถอยหลังชนข่าว)
* **NewsMode**: โหมดการดึงเวลาข่าว (ดึงปฏิทินเศรษฐกิจอัตโนมัติ หรือตั้งเวลาเอง)
* **Timezone**: เลือกโซนเวลาที่ต้องการอ้างอิง หากตั้งโหมดแมนนวล (เช่น LONDON, NEW_YORK, ZONE_GMT_PLUS_7)
* **NewsHour & NewsMinute**: ชั่วโมงและนาทีที่ข่าวจะออก (ใช้กับโหมดตั้งเวลาแมนนวล)
* **OpenBeforeSeconds**: สั่งให้เปิด Pending Order อัตโนมัติ ก่อนข่าวออกกี่วินาที
* **ClosePriceTrackBeforeSeconds**: สั่งให้ระบบ Price Track (ขยับออเดอร์ตามราคา) หยุดทำงาน และ 'ล็อค' ออเดอร์ไว้ก่อนข่าวออกกี่วินาที (แนะนำ 3-20 วินาที)

### ??? Spike Guard (ระบบป้องกันราคาสวิงก่อนข่าวออก)
* **DefaultSpikeGuardOn**: เปิดทำงาน Spike Guard เป็นค่าเริ่มต้นหรือไม่
* **SpikeGuardMinutesBefore**: ให้เริ่มเฝ้าระวังพฤติกรรมกราฟล่วงหน้ากี่นาทีก่อนข่าวออก
* **SpikeThresholdPoints**: ถ้าราคาเหวี่ยงแรงผิดปกติเกินกี่จุด ภายในระยะเวลาที่กำหนด จะถือว่าเป็น Spike
* **SpikeCheckPeriodSec**: ระยะเวลาที่ใช้เช็คว่าเกิด Spike (เช่น เหวี่ยงเกิน 300 จุด ภายใน 10 วินาที)
* **SpikeAction**: การตอบสนองเมื่อพบ Spike (ขยับออเดอร์หนีให้กว้างขึ้น / ปิด Auto-Countdown / ทำทั้งคู่)
* **SpikeWidenPoints**: ถ้าราคาเกิด Spike ให้ขยับออเดอร์หนีไปไกลขึ้นอีกกี่จุด

### ??? Anti-Whipsaw (Fake Spike Protection - ป้องกันการสับหลอก)
* **EnableAntiWhipsaw**: เปิด/ปิด ระบบป้องกันกราฟสับหลอก (กินฝั่งนึงแล้วลากไปอีกฝั่งอย่างรวดเร็ว)
* **EnableDelayedCancel**: ไม่ลบ Pending Order อีกฝั่งทิ้งทันทีเมื่ออีกฝั่งทำงาน แต่จะรอประเมินสถานการณ์ก่อน
* **EnableSmartCutLoss (Auto-Close)**: **[New v3.3]** ปิดออเดอร์ที่ถูกลากทันที (Market Close) หากตั้ง SL ไม่ทันเพราะติดระยะ Stop Level ของโบรคเกอร์
* **DelayedCancelSec**: รอประเมินสถานการณ์กี่วินาที ก่อนจะยอมลบไม้ Pending อีกฝั่งทิ้ง (ช่วงวัดใจ)
* **BreakevenAfterExecPts**: หากไม้ฝั่งใดทำงานแล้ว จะขยับ SL มากันทุน (บวก/ลบ ระยะที่ตั้งไว้เล็กน้อย) เพื่อลดความเสี่ยงทันที
* **ConfirmDirectionPts**: ต้องวิ่งไปถูกทางเกินกี่จุด ถึงจะถือว่า 'ของจริง' และปลอดภัยที่จะลบไม้ฝั่งตรงข้ามทิ้ง

### ?? Expert Advisor Settings (การตั้งค่าทั่วไป)
* **MagicNumber_1**: รหัสประจำตัว (Magic Number) สำหรับ Order ที่ 1 (ใช้แยกออเดอร์จาก EA ตัวอื่น)
* **MagicNumber_2**: รหัสประจำตัว (Magic Number) สำหรับ Order ที่ 2
