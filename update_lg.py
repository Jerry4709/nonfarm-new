import re

with open('tools/LicenseGenerator.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Add ttk import
content = content.replace('from tkinter import messagebox', 'from tkinter import messagebox, ttk')

# Add combo box UI
ui_addition = """
tk.Label(root, text="Trade Mode:").grid(row=4, column=0, padx=10, pady=10, sticky='e')
combo_mode = ttk.Combobox(root, values=["MODE_STANDARD (Pendings)", "MODE_BUY_STOP_ONLY", "MODE_SELL_STOP_ONLY", "MODE_MARKET_BUY", "MODE_MARKET_SELL"], state="readonly", width=27)
combo_mode.current(0)
combo_mode.grid(row=4, column=1, padx=10, pady=10)
"""
content = content.replace('btn_generate = tk.Button(root,', ui_addition + '\nbtn_generate = tk.Button(root,')
content = content.replace('btn_generate.grid(row=4,', 'btn_generate.grid(row=5,')
content = content.replace('lbl_result.grid(row=5,', 'lbl_result.grid(row=6,')
content = content.replace('entry_result.grid(row=6,', 'entry_result.grid(row=7,')

# Add mode extraction in generate_key()
content = content.replace('acc = entry_acc.get().strip()', 'acc = entry_acc.get().strip()\n    mode_text = combo_mode.get()\n    mode_val = mode_text.split(" ")[0] if mode_text != "MODE_STANDARD (Pendings)" else ""')

# Add to query params
content = content.replace('urllib.parse.urlencode({"action": "add", "key": final_key, "user": user, "broker": broker, "acc": acc})', 'urllib.parse.urlencode({"action": "add", "key": final_key, "user": user, "broker": broker, "acc": acc, "mode": mode_val})')

with open('tools/LicenseGenerator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('LicenseGenerator updated.')
