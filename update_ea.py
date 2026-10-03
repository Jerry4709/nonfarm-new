import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update SendPendingOrder signature and logic
content = content.replace('ulong SendPendingOrder(ENUM_ORDER_TYPE orderType, double lots, double price,', 'ulong SendTradeOrder(ENUM_ORDER_TYPE orderType, double lots, double price,')
content = content.replace('req.action       = TRADE_ACTION_PENDING;', 'req.action       = (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) ? TRADE_ACTION_DEAL : TRADE_ACTION_PENDING;')
content = content.replace('if(orderType == ORDER_TYPE_BUY_STOP)', 'if(orderType == ORDER_TYPE_BUY_STOP)\n            req.price = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK) + BuyStopPoints * _Point, _Digits);\n         else if(orderType == ORDER_TYPE_SELL_STOP)\n            req.price = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID) - SellStopPoints * _Point, _Digits);\n         else if(orderType == ORDER_TYPE_BUY)\n            req.price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);\n         else if(orderType == ORDER_TYPE_SELL)\n            req.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);\n         /*')
content = content.replace('req.price = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID) - SellStopPoints * _Point, _Digits);\n         continue;', '*/continue;')


# 2. Update PlaceAllPendingOrders logic
place_orders_new = """void PlaceAllPendingOrders()
{
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double lot1 = GetEffectiveLot1();
   double lot2 = GetEffectiveLot2();

   if(ActiveTradeMode == MODE_STANDARD || ActiveTradeMode == MODE_BUY_STOP_ONLY)
   {
      double buyPrice1 = NormalizeDouble(ask + BuyStopPoints * _Point, _Digits);
      double buyPrice2 = NormalizeDouble(buyPrice1 + Order2GapPoints * _Point, _Digits);
      buyPendingPrice1 = buyPrice1;
      double buyTp1  = NormalizeDouble(buyPrice1 + TP_Points_Order1 * _Point, _Digits);
      double buyTp2  = NormalizeDouble(buyPrice2 + TP_Points_Order2 * _Point, _Digits);
      double buySl1  = GetEffectiveSL(buyPrice1, true);
      double buySl2  = GetEffectiveSL(buyPrice2, true);
      buyStopTicket1 = SendTradeOrder(ORDER_TYPE_BUY_STOP, lot1, buyPrice1, buySl1, buyTp1, MagicNumber_1);
      buyStopTicket2 = SendTradeOrder(ORDER_TYPE_BUY_STOP, lot2, buyPrice2, buySl2, buyTp2, MagicNumber_2);
   }

   if(ActiveTradeMode == MODE_STANDARD || ActiveTradeMode == MODE_SELL_STOP_ONLY)
   {
      double sellPrice1 = NormalizeDouble(bid - SellStopPoints * _Point, _Digits);
      double sellPrice2 = NormalizeDouble(sellPrice1 - Order2GapPoints * _Point, _Digits);
      sellPendingPrice1 = sellPrice1;
      double sellTp1  = NormalizeDouble(sellPrice1 - TP_Points_Order1 * _Point, _Digits);
      double sellTp2  = NormalizeDouble(sellPrice2 - TP_Points_Order2 * _Point, _Digits);
      double sellSl1  = GetEffectiveSL(sellPrice1, false);
      double sellSl2  = GetEffectiveSL(sellPrice2, false);
      sellStopTicket1 = SendTradeOrder(ORDER_TYPE_SELL_STOP, lot1, sellPrice1, sellSl1, sellTp1, MagicNumber_1);
      sellStopTicket2 = SendTradeOrder(ORDER_TYPE_SELL_STOP, lot2, sellPrice2, sellSl2, sellTp2, MagicNumber_2);
   }
   
   if(ActiveTradeMode == MODE_MARKET_BUY)
   {
      double buyPrice1 = ask;
      double buyPrice2 = ask; // Execute both at market
      double buyTp1  = NormalizeDouble(buyPrice1 + TP_Points_Order1 * _Point, _Digits);
      double buyTp2  = NormalizeDouble(buyPrice2 + TP_Points_Order2 * _Point, _Digits);
      double buySl1  = GetEffectiveSL(buyPrice1, true);
      double buySl2  = GetEffectiveSL(buyPrice2, true);
      buyStopTicket1 = SendTradeOrder(ORDER_TYPE_BUY, lot1, buyPrice1, buySl1, buyTp1, MagicNumber_1);
      buyStopTicket2 = SendTradeOrder(ORDER_TYPE_BUY, lot2, buyPrice2, buySl2, buyTp2, MagicNumber_2);
   }
   
   if(ActiveTradeMode == MODE_MARKET_SELL)
   {
      double sellPrice1 = bid;
      double sellPrice2 = bid;
      double sellTp1  = NormalizeDouble(sellPrice1 - TP_Points_Order1 * _Point, _Digits);
      double sellTp2  = NormalizeDouble(sellPrice2 - TP_Points_Order2 * _Point, _Digits);
      double sellSl1  = GetEffectiveSL(sellPrice1, false);
      double sellSl2  = GetEffectiveSL(sellPrice2, false);
      sellStopTicket1 = SendTradeOrder(ORDER_TYPE_SELL, lot1, sellPrice1, sellSl1, sellTp1, MagicNumber_1);
      sellStopTicket2 = SendTradeOrder(ORDER_TYPE_SELL, lot2, sellPrice2, sellSl2, sellTp2, MagicNumber_2);
   }
}"""
content = re.sub(r'void PlaceAllPendingOrders\(\)\s*\{.*?(?=ulong SendTradeOrder)', place_orders_new + '\n\n', content, flags=re.DOTALL)


# 3. UI Updates - Mode label
ui_text_update = """
   //--- Mode Specific Labeling
   string modeText = "Mode: Standard (Straddle)";
   if(ActiveTradeMode == MODE_BUY_STOP_ONLY) modeText = "Mode: Buy Stop Only";
   else if(ActiveTradeMode == MODE_SELL_STOP_ONLY) modeText = "Mode: Sell Stop Only";
   else if(ActiveTradeMode == MODE_MARKET_BUY) modeText = "Mode: Market Buy Only";
   else if(ActiveTradeMode == MODE_MARKET_SELL) modeText = "Mode: Market Sell Only";
   
   ObjectSetString(0, LABEL_MODE, OBJPROP_TEXT, modeText);
   
   if(ActiveTradeMode == MODE_MARKET_BUY || ActiveTradeMode == MODE_MARKET_SELL)
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
   }
"""
content = content.replace('//--- Spike Guard\n   text = "Spike Guard: " + (spikeGuardEnabled ? "ON" : "OFF");', ui_text_update + '\n   //--- Spike Guard\n   text = "Spike Guard: " + (spikeGuardEnabled ? "ON" : "OFF");')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('EA updated.')
