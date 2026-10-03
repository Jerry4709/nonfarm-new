with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_aw_ui = '''   //--- Anti-Whipsaw
   string awText = "Anti-Whipsaw: " + (EnableAntiWhipsaw ? "ON" : "OFF");
   if(EnableAntiWhipsaw && awaitingCancelConfirm)
      awText = "Anti-WS: CONFIRMING";
   color awBg = EnableAntiWhipsaw ? C'180,50,180' : C'80,80,80';
   if(awaitingCancelConfirm) awBg = C'255,140,0';
   ObjectSetString(0, BTN_ANTI_WHIPSAW, OBJPROP_TEXT, awText);
   ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BGCOLOR, awBg);
   ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BORDER_COLOR, awBg);'''

new_aw_ui = '''   //--- Anti-Whipsaw
   if(ActiveTradeMode != MODE_MARKET_BUY && ActiveTradeMode != MODE_MARKET_SELL)
   {
      string awText = "Anti-Whipsaw: " + (EnableAntiWhipsaw ? "ON" : "OFF");
      if(EnableAntiWhipsaw && awaitingCancelConfirm)
         awText = "Anti-WS: CONFIRMING";
      color awBg = EnableAntiWhipsaw ? C'180,50,180' : C'80,80,80';
      if(awaitingCancelConfirm) awBg = C'255,140,0';
      ObjectSetString(0, BTN_ANTI_WHIPSAW, OBJPROP_TEXT, awText);
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BGCOLOR, awBg);
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_BORDER_COLOR, awBg);
   }'''

content = content.replace(old_aw_ui, new_aw_ui)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed Market Mode UI Overwrite!")
