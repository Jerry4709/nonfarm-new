# NonfarmRich EA v3.0

**NonfarmRich EA** is a professional Expert Advisor (EA) for MetaTrader 5, specifically designed for high-volatility news trading (such as Non-Farm Payrolls, CPI, and Interest Rate decisions).

## 🚀 Key Trading Features

* **Straddle Pending Orders (Buy Stop / Sell Stop):** Automatically places pending orders at a specified distance from the current price right before a news event.
* **Cancel Opposite Pending:** When one pending order is triggered (e.g., Buy Stop is hit), the EA can automatically delete the opposite pending order (Sell Stop) to prevent whip-saw losses. This can be toggled on/off directly from the EA's on-chart UI.
* **Spike Guard:** A protective mechanism that monitors price ticks just seconds before the news release. If it detects abnormal price manipulation or massive spikes (which often cause severe slippage), it will automatically pause tracking or move pending orders to a safer distance.
* **Trailing Stop:** Automatically trails the Stop Loss behind the current price once the trade is in profit, securing gains dynamically.
* **Lot Size Calculator:** Built-in dynamic lot sizing based on account balance and risk parameters.

## 🔐 Licensing & Security System (v3.0)

Version 3.0 introduces a highly secure, centralized licensing system integrated with **Google Sheets**.

* **Centralized Management:** Licenses are managed via a Google Sheet, acting as a real-time database. You can instantly see which accounts are active or revoke licenses.
* **Auto-Binding System:** Keys can be generated as "Unbound" (`ANY`). The first time a client enters the key into their MT5, the EA grabs their **Account Name**, **Broker**, and **Account Number**, and silently writes this data to the Google Sheet. The key is then permanently locked to that specific account.
* **DLL Network Bypass:** Instead of forcing clients to manually add URLs to the MT5 `WebRequest` whitelist (which is confusing for users), the EA uses Windows API (`wininet.dll`) to validate the license. The user only needs to check **"Allow DLL imports"** in their MT5 settings.
* **XOR URL Obfuscation:** All sensitive URLs (Google Apps Script, GitHub Update URLs) are XOR-encrypted as byte arrays inside the source code. They are invisible to hex editors and reverse-engineering tools analyzing the `.ex5` file.

## 🛠 Included Tools

### License Generator (`tools/LicenseGenerator.py`)
A Python GUI application (built with Tkinter) for the EA Administrator. 
- Input a 5-character serial, customer name, broker, and account number.
- Generates a cryptographically hashed license key (djb2 hash algorithm).
- Automatically syncs the generated key to your Google Sheet database in real-time.

**To compile the License Generator into an `.exe`:**
```bash
pip install pyinstaller
pyinstaller --noconsole --onefile --windowed --name "NonfarmRich_LicenseGenerator" tools/LicenseGenerator.py
```

## ⚙️ Installation & Usage (For Clients)

1. Copy `NonfarmRich_v3.ex5` to your MT5 `MQL5/Experts` folder.
2. Open MetaTrader 5 and refresh the Expert Advisors list.
3. Drag the EA onto the chart.
4. Go to the **Dependencies** (or Common) tab and check **"Allow DLL imports"**.
5. Go to the **Inputs** tab and enter your License Key.
6. Click OK. The EA will validate your license and bind it to your account automatically.
