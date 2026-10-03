with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_validate = '''bool ValidateLicenseKey(string key)
{
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
      return true;'''

new_validate = '''bool ValidateLicenseKey(string key)
{
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
   {
      string upperKey = key;
      StringToUpper(upperKey);
      
      if(StringFind(upperKey, "BUY_STOP") >= 0) ActiveTradeMode = MODE_BUY_STOP_ONLY;
      else if(StringFind(upperKey, "SELL_STOP") >= 0) ActiveTradeMode = MODE_SELL_STOP_ONLY;
      else if(StringFind(upperKey, "MARKET_BUY") >= 0) ActiveTradeMode = MODE_MARKET_BUY;
      else if(StringFind(upperKey, "MARKET_SELL") >= 0) ActiveTradeMode = MODE_MARKET_SELL;
      else ActiveTradeMode = MODE_STANDARD;
      
      Print("Backtest Mode Initialized via Key: ", EnumToString(ActiveTradeMode));
      return true;
   }'''

content = content.replace(old_validate, new_validate)

# Bump version to 4.8.0
content = content.replace('#define EA_VERSION       "4.7.0"', '#define EA_VERSION       "4.8.0"')
content = content.replace('#define EA_BUILD         20261011', '#define EA_BUILD         20261012')
content = content.replace('string EA_VERSION = "4.7.0";', 'string EA_VERSION = "4.8.0";')
content = content.replace('int    EA_BUILD   = 20261011;', 'int    EA_BUILD   = 20261012;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated Backtest Mode Bypass logic!")
