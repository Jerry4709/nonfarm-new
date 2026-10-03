import re
with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'#define EA_VERSION\s+".*"', '#define EA_VERSION       "4.4.0"', content)
content = re.sub(r'#define EA_BUILD\s+\d+', '#define EA_BUILD         20261008', content)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Bumped EA to v4.4.0.')
