with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('string EA_VERSION = "3.4.0";', 'string EA_VERSION = "4.0.0";')
content = content.replace('int    EA_BUILD   = 20261002;', 'int    EA_BUILD   = 20261004;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Bumped version to 4.0.0 in EA source.')
