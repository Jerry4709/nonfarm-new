import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix Header Text
content = content.replace('"NonfarmRich EA v3.4"', '"NonfarmRich EA v" + EA_VERSION')

# Fix Mode Text
old_mode = '''   if(ActiveTradeMode == MODE_BUY_STOP_ONLY) modeText = "Mode: Buy Stop Only";
   else if(ActiveTradeMode == MODE_SELL_STOP_ONLY) modeText = "Mode: Sell Stop Only";
   else if(ActiveTradeMode == MODE_MARKET_BUY) modeText = "Mode: Market Buy Only";
   else if(ActiveTradeMode == MODE_MARKET_SELL) modeText = "Mode: Market Sell Only";'''

new_mode = '''   if(ActiveTradeMode == MODE_BUY_STOP_ONLY) modeText = "Mode: Buy Stop Only";
   else if(ActiveTradeMode == MODE_SELL_STOP_ONLY) modeText = "Mode: Sell Stop Only";
   else if(ActiveTradeMode == MODE_MARKET_BUY) modeText = "Mode: Market Buy Only";
   else if(ActiveTradeMode == MODE_MARKET_SELL) modeText = "Mode: Market Sell Only";
   else modeText = "Mode: STANDARD (Straddle)";'''

content = content.replace(old_mode, new_mode)

# Fix Version Defines
content = re.sub(r'#define EA_VERSION\s+".*"', '#define EA_VERSION       "4.3.0"', content)
content = re.sub(r'#define EA_BUILD\s+\d+', '#define EA_BUILD         20261007', content)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed UI text and version defines.")
