with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('"NonfarmRich EA v3.4"', '"NonfarmRich EA v" + EA_VERSION')

mode_logic_old = '''   if(ActiveTradeMode == MODE_BUY_STOP_ONLY) modeText = "Mode: Buy Stop Only";
   else if(ActiveTradeMode == MODE_SELL_STOP_ONLY) modeText = "Mode: Sell Stop Only";
   else if(ActiveTradeMode == MODE_MARKET_BUY) modeText = "Mode: Market Buy Only";
   else if(ActiveTradeMode == MODE_MARKET_SELL) modeText = "Mode: Market Sell Only";'''

mode_logic_new = '''   if(ActiveTradeMode == MODE_BUY_STOP_ONLY) modeText = "Mode: Buy Stop Only";
   else if(ActiveTradeMode == MODE_SELL_STOP_ONLY) modeText = "Mode: Sell Stop Only";
   else if(ActiveTradeMode == MODE_MARKET_BUY) modeText = "Mode: Market Buy Only";
   else if(ActiveTradeMode == MODE_MARKET_SELL) modeText = "Mode: Market Sell Only";
   else modeText = "Mode: STANDARD (Straddle)";'''

content = content.replace(mode_logic_old, mode_logic_new)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed Header and Mode Text.')
