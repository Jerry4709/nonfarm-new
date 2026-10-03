with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('#define LABEL_STATUS        "NR_Status"', '#define LABEL_STATUS        "NR_Status"\n#define LABEL_MODE        "NR_Mode"')
content = content.replace('EnableAntiWhipsaw = false;', '')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed compilation errors.')
