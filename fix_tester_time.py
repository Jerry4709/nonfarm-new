with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_inputs = '''input group   "--- ⚙️ NEWS COUNTDOWN (All Modes) ---"
input ENUM_NEWS_MODE NewsMode = NEWS_AUTO_NFP;
input ENUM_TIMEZONE_CITY Timezone = LONDON;
input int     NewsHour                      = 9;
input int     NewsMinute                    = 30;'''

new_inputs = '''input group   "--- ⚙️ NEWS COUNTDOWN (All Modes) ---"
input ENUM_NEWS_MODE NewsMode = NEWS_AUTO_NFP;
input ENUM_TIMEZONE_CITY Timezone = BANGKOK;
input int     NewsHour                      = 19;
input int     NewsMinute                    = 30;
input int     Backtest_Broker_GMT           = 3;      // ⏳ [Backtest] Broker GMT Offset'''

content = content.replace(old_inputs, new_inputs)

old_time = '''datetime GetCurrentTimeInZone()
{
   return TimeGMT() + (GetTimezoneOffset() * 3600);
}'''

new_time = '''datetime GetCurrentTimeInZone()
{
   datetime gmt = TimeGMT();
   if(MQLInfoInteger(MQL_TESTER))
   {
      // MT5 Tester bug: TimeGMT() often equals TimeCurrent(). Fix it using the backtest offset.
      if(TimeGMT() == TimeCurrent())
         gmt = TimeCurrent() - (Backtest_Broker_GMT * 3600);
   }
   return gmt + (GetTimezoneOffset() * 3600);
}'''

content = content.replace(old_time, new_time)

old_fallback = '''datetime GetNextNewsTimeManualFallback()
{
   datetime now_gmt = TimeGMT();
   long tz_offset_sec = (long)GetTimezoneOffset() * 3600;'''

new_fallback = '''datetime GetNextNewsTimeManualFallback()
{
   datetime now_gmt = TimeGMT();
   if(MQLInfoInteger(MQL_TESTER) && TimeGMT() == TimeCurrent())
   {
      now_gmt = TimeCurrent() - (Backtest_Broker_GMT * 3600);
   }
   long tz_offset_sec = (long)GetTimezoneOffset() * 3600;'''

content = content.replace(old_fallback, new_fallback)

# Bump version to 4.9.0
content = content.replace('#define EA_VERSION       "4.8.0"', '#define EA_VERSION       "4.9.0"')
content = content.replace('#define EA_BUILD         20261012', '#define EA_BUILD         20261013')
content = content.replace('string EA_VERSION = "4.8.0";', 'string EA_VERSION = "4.9.0";')
content = content.replace('int    EA_BUILD   = 20261012;', 'int    EA_BUILD   = 20261013;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed Strategy Tester GMT Bug!")
