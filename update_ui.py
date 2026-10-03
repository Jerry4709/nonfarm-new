import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add LABEL_MODE
content = content.replace('CreateLabel(LABEL_STATUS, 25, 50,', 'CreateLabel(LABEL_MODE, 25, 50, \"Mode: \", C\'255,215,0\', 14, \"Arial Bold\");\n   CreateLabel(LABEL_STATUS, 25, 75,')

# Adjust button Y positions to make room
content = content.replace('CreateButton(BTN_OPEN,          25,  100,', 'CreateButton(BTN_OPEN,          25,  125,')
content = content.replace('CreateButton(BTN_CLOSE,         205, 100,', 'CreateButton(BTN_CLOSE,         205, 125,')
content = content.replace('CreateButton(BTN_PRICE_TRACK,   25,  150,', 'CreateButton(BTN_PRICE_TRACK,   25,  175,')
content = content.replace('CreateButton(BTN_TRAILING_STOP, 25,  192,', 'CreateButton(BTN_TRAILING_STOP, 25,  217,')
content = content.replace('CreateButton(BTN_COUNTDOWN,     25,  234,', 'CreateButton(BTN_COUNTDOWN,     25,  259,')
content = content.replace('CreateButton(BTN_SPIKE_GUARD,   25,  276,', 'CreateButton(BTN_SPIKE_GUARD,   25,  301,')
content = content.replace('CreateButton(BTN_ANTI_WHIPSAW,  25,  318,', 'CreateButton(BTN_ANTI_WHIPSAW,  25,  343,')
content = content.replace('CreateButton(BTN_CALC_LOT,      25,  360,', 'CreateButton(BTN_CALC_LOT,      25,  385,')

# Info labels Y offset + 25
content = content.replace('LABEL_LOT_INFO,      25, 405', 'LABEL_LOT_INFO,      25, 430')
content = content.replace('LABEL_MARGIN_INFO,   25, 428', 'LABEL_MARGIN_INFO,   25, 453')
content = content.replace('LABEL_CALC_LOT,      25, 448', 'LABEL_CALC_LOT,      25, 473')
content = content.replace('LABEL_COUNTDOWN,     25, 473', 'LABEL_COUNTDOWN,     25, 498')
content = content.replace('LABEL_TRAILING_INFO, 25, 503', 'LABEL_TRAILING_INFO, 25, 528')
content = content.replace('LABEL_SPIKE_INFO,    25, 528', 'LABEL_SPIKE_INFO,    25, 553')
content = content.replace('LABEL_AW_INFO,       25, 553', 'LABEL_AW_INFO,       25, 578')
content = content.replace('LABEL_PARAMS, 25, 581', 'LABEL_PARAMS, 25, 606')
content = content.replace('LABEL_POINTS, 25, 603', 'LABEL_POINTS, 25, 628')
content = content.replace('LABEL_TP_INFO, 25, 623', 'LABEL_TP_INFO, 25, 648')
content = content.replace('LABEL_TRAIL1, 25, 643', 'LABEL_TRAIL1, 25, 668')
content = content.replace('LABEL_TRAIL2, 25, 663', 'LABEL_TRAIL2, 25, 688')
content = content.replace('LABEL_NEWS_TIME, 25, 683', 'LABEL_NEWS_TIME, 25, 708')
content = content.replace('LABEL_SPIKE_PARAMS, 25, 703', 'LABEL_SPIKE_PARAMS, 25, 728')
content = content.replace('LABEL_VERSION, 25, 691', 'LABEL_VERSION, 25, 755')
content = content.replace('panelH = 790', 'panelH = 820')
content = content.replace('#define LABEL_STATUS         \"nr_lbl_status\"', '#define LABEL_STATUS         \"nr_lbl_status\"\n#define LABEL_MODE           \"nr_lbl_mode\"')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('UI adjusted for MODE label.')
