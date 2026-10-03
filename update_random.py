import re
import urllib.request
import urllib.parse
import string
import json

with open('tools/LicenseGenerator.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Add random import
if 'import random' not in content:
    content = content.replace('import string', 'import string\nimport random')

# Update UI Label
content = content.replace('Serial (3-15 chars, e.g. ADMIN):', 'Key Prefix (e.g. PORT1, ADMIN):')

# Update generate_key logic
old_logic = '''    if not (3 <= len(serial) <= 15) or not all(c in string.ascii_uppercase + string.digits for c in serial):
        messagebox.showerror("Error", "Serial must be 3 to 15 alphanumeric characters (A-Z, 0-9).\\nExample: ADMIN, USER1")
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
        
    license_key = f"NFARM-{serial}-{check_code}"'''

new_logic = '''    if not (1 <= len(serial) <= 15) or not all(c in string.ascii_uppercase + string.digits + "-" for c in serial):
        messagebox.showerror("Error", "Prefix must be 1 to 15 characters (A-Z, 0-9, -).\\nExample: ADMIN, PORT1")
        return
        
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    random_code1 = "".join(random.choice(chars) for _ in range(4))
    random_code2 = "".join(random.choice(chars) for _ in range(4))
    
    license_key = f"NFARM-{serial}-{random_code1}-{random_code2}"'''

content = content.replace(old_logic, new_logic)

with open('tools/LicenseGenerator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated to random key generation.')
