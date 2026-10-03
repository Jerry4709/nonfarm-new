import tkinter as tk
from tkinter import messagebox, ttk
import urllib.request
import urllib.parse
import string
import json

GAS_URL = "https://script.google.com/macros/s/AKfycbzerZNdTdMPx-BDMXz1cIX4IgIvrH5RnrwMpfishcUWc8--WDrOYChq2E7g6akqMgN2JA/exec"

def generate_key():
    serial = entry_serial.get().upper().strip()
    user = entry_user.get().strip()
    broker = entry_broker.get().strip()
    acc = entry_acc.get().strip()
    mode_text = combo_mode.get()
    mode_val = mode_text.split(" ")[0] if mode_text != "MODE_STANDARD (Pendings)" else ""
    
    if not (3 <= len(serial) <= 15) or not all(c in string.ascii_uppercase + string.digits for c in serial):
        messagebox.showerror("Error", "Serial must be 3 to 15 alphanumeric characters (A-Z, 0-9).\nExample: ADMIN, USER1")
        return
        
    hash_val = 5381
    for char in serial:
        hash_val = ((hash_val << 5) + hash_val) + ord(char)
        hash_val &= 0xFFFFFFFFFFFFFFFF
        
    hash_val ^= 0x4E465249
    
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    check_code = ""
    for i in range(5):
        idx = ((hash_val >> (i * 5)) & 0x1F) % len(chars)
        check_code += chars[idx]
        
    license_key = f"NFARM-{serial}-{check_code}"
    
    # Save to UI
    entry_result.config(state=tk.NORMAL)
    entry_result.delete(0, tk.END)
    entry_result.insert(0, license_key)
    entry_result.config(state="readonly")
    
    # Add to Google Sheet
    try:
        btn_generate.config(text="Sending to Google Sheet...", state=tk.DISABLED)
        root.update()
        
        params = {
            "action": "add",
            "key": license_key,
            "user": user,
            "broker": broker if broker else "ANY",
            "acc": acc if acc else "ANY"
        }
        query_string = urllib.parse.urlencode(params)
        url = f"{GAS_URL}?{query_string}"
        
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            resp_text = response.read().decode('utf-8')
            if "SUCCESS" in resp_text:
                messagebox.showinfo("Success", f"License Generated & Added to Sheet!\n\nKey: {license_key}")
            else:
                messagebox.showerror("Sheet Error", resp_text)
    except Exception as e:
        messagebox.showerror("Network Error", f"Failed to connect to Google Sheet:\n{str(e)}")
    finally:
        btn_generate.config(text="Generate & Add to Sheet", state=tk.NORMAL)

def copy_to_clipboard():
    root.clipboard_clear()
    root.clipboard_append(entry_result.get())
    messagebox.showinfo("Copied", "License Key copied to clipboard!")

root = tk.Tk()
root.title("NonfarmRich v3 License Generator")
root.geometry("420x380")
root.resizable(False, False)
root.configure(padx=20, pady=20)

tk.Label(root, text="License Generator & Sheet Sync", font=("Arial", 14, "bold")).pack(pady=(0, 15))

frame = tk.Frame(root)
frame.pack(fill=tk.BOTH, expand=True)

# Serial
tk.Label(frame, text="Serial (3-15 chars, e.g. ADMIN):").grid(row=0, column=0, sticky="w", pady=5)
entry_serial = tk.Entry(frame, width=25)
entry_serial.grid(row=0, column=1, pady=5)
entry_serial.insert(0, "ADMIN")

# User
tk.Label(frame, text="Customer Name (Optional):").grid(row=1, column=0, sticky="w", pady=5)
entry_user = tk.Entry(frame, width=25)
entry_user.grid(row=1, column=1, pady=5)

# Broker
tk.Label(frame, text="Broker (e.g. Exness, ANY):").grid(row=2, column=0, sticky="w", pady=5)
entry_broker = tk.Entry(frame, width=25)
entry_broker.grid(row=2, column=1, pady=5)
entry_broker.insert(0, "ANY")

# Account
tk.Label(frame, text="Account Number(s) (or ANY):").grid(row=3, column=0, sticky="w", pady=5)
entry_acc = tk.Entry(frame, width=25)
entry_acc.grid(row=3, column=1, pady=5)
entry_acc.insert(0, "ANY")

# Generate Button

tk.Label(root, text="Trade Mode:").grid(row=4, column=0, padx=10, pady=10, sticky='e')
combo_mode = ttk.Combobox(root, values=["MODE_STANDARD (Pendings)", "MODE_BUY_STOP_ONLY", "MODE_SELL_STOP_ONLY", "MODE_MARKET_BUY", "MODE_MARKET_SELL"], state="readonly", width=27)
combo_mode.current(0)
combo_mode.grid(row=4, column=1, padx=10, pady=10)

btn_generate = tk.Button(root, text="Generate & Add to Sheet", font=("Arial", 10, "bold"), bg="#4CAF50", fg="white", command=generate_key, pady=5)
btn_generate.pack(fill=tk.X, pady=(20, 10))

# Result
tk.Label(root, text="Generated License Key:").pack(anchor="w")
frame_res = tk.Frame(root)
frame_res.pack(fill=tk.X)
entry_result = tk.Entry(frame_res, width=32, font=("Courier", 12, "bold"), state="readonly")
entry_result.pack(side=tk.LEFT, ipady=3)
tk.Button(frame_res, text="Copy", command=copy_to_clipboard).pack(side=tk.RIGHT, padx=5)

root.mainloop()




