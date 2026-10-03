with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('string EA_VERSION = "4.1.0";', 'string EA_VERSION = "4.2.0";')
content = content.replace('int    EA_BUILD   = 20261005;', 'int    EA_BUILD   = 20261006;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Bumped EA to v4.2.0.')
