with open('tools/LicenseGenerator.py', 'r', encoding='utf-8') as f:
    content = f.read()

old_str = '''        params = {
            "action": "add",
            "key": license_key,
            "user": user,
            "broker": broker if broker else "ANY",
            "acc": acc if acc else "ANY"
        }'''

new_str = '''        params = {
            "action": "add",
            "key": license_key,
            "user": user,
            "broker": broker if broker else "ANY",
            "acc": acc if acc else "ANY",
            "mode": mode_val
        }'''

content = content.replace(old_str, new_str)

with open('tools/LicenseGenerator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated params in Python.")
