import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_std = '''input int     Std_BuyStopPoints      = 3000;     // Buy Stop distance (points)'''
new_std = '''input int     Std_OpenBeforeSec      = 30;       // วาง Pending ก่อนข่าว (วินาที)
input int     Std_BuyStopPoints      = 3000;     // Buy Stop distance (points)'''
content = content.replace(old_std, new_std)

old_single = '''input int     Single_StopPoints      = 3000;     // Stop distance (points)'''
new_single = '''input int     Single_OpenBeforeSec   = 30;       // วาง Pending ก่อนข่าว (วินาที)
input int     Single_StopPoints      = 3000;     // Stop distance (points)'''
content = content.replace(old_single, new_single)

old_market = '''input int     Market_SL_Points       = 0;        // Stop Loss (0 = disabled)'''
new_market = '''input int     Market_ExecuteBeforeSec= 2;        // ยิงออเดอร์สด ก่อนข่าว (วินาที)
input int     Market_SL_Points       = 0;        // Stop Loss (0 = disabled)'''
content = content.replace(old_market, new_market)

old_news = '''input int     OpenBeforeSeconds             = 30;   // Open pending X sec before news'''
new_news = '''// (OpenBeforeSeconds is now separated by Mode)'''
content = content.replace(old_news, new_news)

old_globals = '''//--- Global Shadow Variables for Active Settings'''
new_globals = '''//--- Global Shadow Variables for Active Settings
int     OpenBeforeSeconds;'''
content = content.replace(old_globals, new_globals)

assign_std = '''      BuyStopPoints         = Std_BuyStopPoints;'''
assign_std_new = '''      OpenBeforeSeconds     = Std_OpenBeforeSec;
      BuyStopPoints         = Std_BuyStopPoints;'''
content = content.replace(assign_std, assign_std_new)

assign_single = '''      BuyStopPoints         = Single_StopPoints;'''
assign_single_new = '''      OpenBeforeSeconds     = Single_OpenBeforeSec;
      BuyStopPoints         = Single_StopPoints;'''
content = content.replace(assign_single, assign_single_new)

assign_market = '''      BuyStopPoints         = 0;'''
assign_market_new = '''      OpenBeforeSeconds     = Market_ExecuteBeforeSec;
      BuyStopPoints         = 0;'''
content = content.replace(assign_market, assign_market_new)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Added mode-specific execution timers.')
