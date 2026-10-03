with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('#define EA_VERSION       "4.0.0"', '#define EA_VERSION       "4.1.0"')
content = content.replace('#define EA_BUILD         20261004', '#define EA_BUILD         20261005')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Bumped EA to v4.1.0 for Github.')
