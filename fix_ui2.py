import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix UI Overlap
content = content.replace('CreateLabel(LABEL_STATUS, 25, 75, \"Status: Ready\"', 'CreateLabel(LABEL_STATUS, 25, 75, \"Status: Ready\"')
content = content.replace('CreateLabel(LABEL_LICENSE, 25, 75, \"License: Checking...\"', 'CreateLabel(LABEL_LICENSE, 25, 95, \"License: Checking...\"')

# Fix Input Grouping
content = content.replace('input group   "Expert Advisor Settings"', 'input group   "--- ⚙️ GENERAL SETTINGS (All Modes) ---"')
content = content.replace('input group   "Pending Orders"', 'input group   "--- ⚠️ PENDING MODE ONLY (Modes 1,2,3) ---"')
content = content.replace('input group   "Take Profit Settings"', 'input group   "--- ⚙️ TAKE PROFIT SETTINGS (All Modes) ---"')
content = content.replace('input group   "Lot Size Settings"', 'input group   "--- ⚙️ LOT SIZE SETTINGS (All Modes) ---"')
content = content.replace('input group   "Trailing Stop - Order 1"', 'input group   "--- ⚙️ TRAILING STOP (All Modes) ---"')
content = content.replace('input group   "News Countdown"', 'input group   "--- ⚙️ NEWS COUNTDOWN (All Modes) ---"')
content = content.replace('input group   "Spike Guard (Pre-News Protection)"', 'input group   "--- ⚠️ PENDING MODE ONLY: Spike Guard ---"')
content = content.replace('input group   "Anti-Whipsaw (Fake Spike Protection)"', 'input group   "--- ⚠️ STRADDLE MODE ONLY: Anti-Whipsaw ---"')

# Fix Button States for BuyStop/SellStop modes
button_logic_old = '''   if(ActiveTradeMode == MODE_MARKET_BUY || ActiveTradeMode == MODE_MARKET_SELL)
   {
      ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_PRICE_TRACK, OBJPROP_TEXT, "Price Track: N/A");
      
      ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_SPIKE_GUARD, OBJPROP_TEXT, "Spike Guard: N/A");
      
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_ANTI_WHIPSAW, OBJPROP_TEXT, "Anti-Whipsaw: N/A");
      
      spikeGuardEnabled = false;
      priceTrackingEnabled = false;
      EnableAntiWhipsaw = false;
   }'''

button_logic_new = '''   if(ActiveTradeMode == MODE_MARKET_BUY || ActiveTradeMode == MODE_MARKET_SELL)
   {
      ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_PRICE_TRACK, OBJPROP_TEXT, "Price Track: N/A");
      
      ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_SPIKE_GUARD, OBJPROP_TEXT, "Spike Guard: N/A");
      
      spikeGuardEnabled = false;
      priceTrackingEnabled = false;
   }
   
   if(ActiveTradeMode != MODE_STANDARD)
   {
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 1);
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BGCOLOR, C'80,80,80');
      ObjectSetString(0, BTN_ANTI_WHIPSAW, OBJPROP_TEXT, "Anti-Whipsaw: N/A");
   }'''

content = content.replace(button_logic_old, button_logic_new)

# Shift buttons down further to clear License Label
content = content.replace('CreateButton(BTN_OPEN,          25,  125,', 'CreateButton(BTN_OPEN,          25,  130,')
content = content.replace('CreateButton(BTN_CLOSE,         205, 125,', 'CreateButton(BTN_CLOSE,         205, 130,')
content = content.replace('CreateButton(BTN_PRICE_TRACK,   25,  175,', 'CreateButton(BTN_PRICE_TRACK,   25,  180,')
content = content.replace('CreateButton(BTN_TRAILING_STOP, 25,  217,', 'CreateButton(BTN_TRAILING_STOP, 25,  222,')
content = content.replace('CreateButton(BTN_COUNTDOWN,     25,  259,', 'CreateButton(BTN_COUNTDOWN,     25,  264,')
content = content.replace('CreateButton(BTN_SPIKE_GUARD,   25,  301,', 'CreateButton(BTN_SPIKE_GUARD,   25,  306,')
content = content.replace('CreateButton(BTN_ANTI_WHIPSAW,  25,  343,', 'CreateButton(BTN_ANTI_WHIPSAW,  25,  348,')
content = content.replace('CreateButton(BTN_CALC_LOT,      25,  385,', 'CreateButton(BTN_CALC_LOT,      25,  390,')

# Shift info labels down
content = content.replace('LABEL_LOT_INFO,      25, 430', 'LABEL_LOT_INFO,      25, 435')
content = content.replace('LABEL_MARGIN_INFO,   25, 453', 'LABEL_MARGIN_INFO,   25, 458')
content = content.replace('LABEL_CALC_LOT,      25, 473', 'LABEL_CALC_LOT,      25, 478')
content = content.replace('LABEL_COUNTDOWN,     25, 498', 'LABEL_COUNTDOWN,     25, 503')
content = content.replace('LABEL_TRAILING_INFO, 25, 528', 'LABEL_TRAILING_INFO, 25, 533')
content = content.replace('LABEL_SPIKE_INFO,    25, 553', 'LABEL_SPIKE_INFO,    25, 558')
content = content.replace('LABEL_AW_INFO,       25, 578', 'LABEL_AW_INFO,       25, 583')
content = content.replace('LABEL_PARAMS, 25, 606', 'LABEL_PARAMS, 25, 611')
content = content.replace('LABEL_POINTS, 25, 628', 'LABEL_POINTS, 25, 633')
content = content.replace('LABEL_TP_INFO, 25, 648', 'LABEL_TP_INFO, 25, 653')
content = content.replace('LABEL_TRAIL1, 25, 668', 'LABEL_TRAIL1, 25, 673')
content = content.replace('LABEL_TRAIL2, 25, 688', 'LABEL_TRAIL2, 25, 693')
content = content.replace('LABEL_NEWS_TIME, 25, 708', 'LABEL_NEWS_TIME, 25, 713')
content = content.replace('LABEL_SPIKE_PARAMS, 25, 728', 'LABEL_SPIKE_PARAMS, 25, 733')


with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('UI and Inputs Fixed.')
