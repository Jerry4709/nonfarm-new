with open('tools/LicenseGenerator.py', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = \"\"\"        params = {
            "action": "add",
            "key": license_key,
            "user": user,
            "broker": broker if broker else "ANY",
            "acc": acc if acc else "ANY",
            "mode": mode_val
        }\"\"\"

content = re.sub(r'params = \{\s*"action": "add",\s*"key": license_key,\s*"user": user,\s*"broker": broker if broker else "ANY",\s*"acc": acc if acc else "ANY"\s*\}', replacement, content)

with open('tools/LicenseGenerator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed params dictionary.')
