with open('tools/LicenseGenerator.py', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('tk.Label(root, text=\"Trade Mode:\").grid(row=4, column=0, padx=10, pady=10, sticky=\'e\')', 'tk.Label(frame, text=\"Trade Mode:\").grid(row=4, column=0, sticky=\"w\", pady=5)')
content = content.replace('combo_mode = ttk.Combobox(root,', 'combo_mode = ttk.Combobox(frame,')
content = content.replace('combo_mode.grid(row=4, column=1, padx=10, pady=10)', 'combo_mode.grid(row=4, column=1, pady=5)')
content = content.replace('btn_generate.grid(row=5,', '#')
content = content.replace('lbl_result.grid(row=6,', '#')
content = content.replace('entry_result.grid(row=7,', '#')

with open('tools/LicenseGenerator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed grid vs pack conflict.')
