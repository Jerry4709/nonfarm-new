with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_click = '''   else if(sparam == BTN_ANTI_WHIPSAW)
   {
      EnableAntiWhipsaw = !EnableAntiWhipsaw;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 0);
   }'''

new_click = '''   else if(sparam == BTN_ANTI_WHIPSAW)
   {
      if(ActiveTradeMode != MODE_MARKET_BUY && ActiveTradeMode != MODE_MARKET_SELL)
      {
         EnableAntiWhipsaw = !EnableAntiWhipsaw;
         UpdateButtonStates();
      }
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 0);
   }'''

content = content.replace(old_click, new_click)
with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated OnChartEvent click block!")
