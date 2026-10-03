with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('   else modeText = "Mode: STANDARD (Straddle)";\n   else modeText = "Mode: STANDARD (Straddle)";', '   else modeText = "Mode: STANDARD (Straddle)";')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed duplicate else.')
