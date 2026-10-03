with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_delete = '''   string objs[] = {
      PANEL_NAME, HEADER_LABEL, LABEL_STATUS, LABEL_LICENSE,
      BTN_OPEN, BTN_CLOSE, BTN_PRICE_TRACK, BTN_TRAILING_STOP,'''

new_delete = '''   string objs[] = {
      PANEL_NAME, HEADER_LABEL, LABEL_MODE, LABEL_STATUS, LABEL_LICENSE,
      BTN_OPEN, BTN_CLOSE, BTN_PRICE_TRACK, BTN_TRAILING_STOP,'''

content = content.replace(old_delete, new_delete)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Added LABEL_MODE to DeleteUI.')
