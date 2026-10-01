//+------------------------------------------------------------------+
//|                    NonfarmRich_Modified_2Orders.mq5              |
//|      EA MT5 2 Orders + Modified Trailing Stop                    |
//|      FIXED: Auto Price Track Disable + Separate TP + Lot Calc   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

// --- Inputs for Pending Orders
input int     BuyStopPoints     = 3000;    // Distance of Buy Stop (points)
input int     SellStopPoints    = 3000;    // Distance of Sell Stop (points)
input int     SL_Points         = 0;       // Stop Loss distance (0 = disabled)
input int     Order2GapPoints   = 10;      // Extra gap for order #2

//--- Separate TP for each order (not separate Buy/Sell)
input group   "Take Profit Settings"
input int     TP_Points_Order1  = 600;     // TP for Order #1 (points)
input int     TP_Points_Order2  = 600;     // TP for Order #2 (points)

//--- Lot Size Settings
input group   "Lot Size Settings"
input double  LotSize_Order1    = 0.1;     // Default Lot size for order #1
input double  LotSize_Order2    = 0.1;     // Default Lot size for order #2
input bool    UseCalculatedLots = false;   // Use calculated lots from margin
input double  RiskPercentage    = 5.0;     // Risk percentage for lot calculation

//--- Inputs for Modified Trailing Stop
input group   "Trailing Stop - Order 1"
input int     TrailingStartPoints_1    = 300;     // (Order 1) Start moving SL when profit >= this (points)
input int     TrailingStepPoints_1     = 100;     // (Order 1) Move SL by this amount (points)
input int     TrailingDistancePoints_1 = 50;      // (Order 1) Keep SL this distance from current price (points)

input group   "Trailing Stop - Order 2"
input int     TrailingStartPoints_2    = 100;     // (Order 2) Start moving SL when profit >= this (points)
input int     TrailingStepPoints_2     = 0;       // (Order 2) Move SL by this amount (points)
input int     TrailingDistancePoints_2 = 0;       // (Order 2) Keep SL this distance from current price (points)

//--- Inputs for News Countdown
input group   "News Countdown"
enum ENUM_TIMEZONE_CITY
{
    BANGKOK,  // GMT+7
    TOKYO,    // GMT+9
    LONDON,   // GMT+0 / GMT+1 (BST)
    NEW_YORK, // GMT-5 (EST) / GMT-4 (EDT)
    SYDNEY    // GMT+10 (AEST) / GMT+11 (AEDT)
};
input ENUM_TIMEZONE_CITY Timezone = LONDON;   // Select news timezone by city (DST is handled automatically)
input int     NewsHour          = 9;      // News hour (24h format in your selected city)
input int     NewsMinute        = 40;      // News minute
input int     OpenBeforeSeconds = 30;      // Auto-open pending orders before news (seconds)
input int     ClosePriceTrackBeforeSeconds = 20; // Auto-disable Price Track before news (seconds)

//--- Magic Numbers
input group   "Expert Advisor Settings"
input ulong   MagicNumber_1     = 1111;    // Magic Number for Order #1
input ulong   MagicNumber_2     = 2222;    // Magic Number for Order #2

//--- Tickets
ulong buyStopTicket1 = 0, buyStopTicket2 = 0;
ulong sellStopTicket1 = 0, sellStopTicket2 = 0;

//--- Store original pending prices for trailing calculation
double buyPendingPrice1 = 0.0;
double sellPendingPrice1 = 0.0;

//--- States
bool ordersOpened         = false;
bool priceTrackingEnabled = true;
bool trailingStopActive   = true;
bool autoOrderPlaced      = false;
bool countdownEnabled     = true;
bool priceTrackDisabledByNews = false;  // Track if price track was disabled by news

//--- Track last SL levels to avoid unnecessary modifications
double lastBuySL_1 = 0.0, lastBuySL_2 = 0.0;
double lastSellSL_1 = 0.0, lastSellSL_2 = 0.0;

//--- Calculated lot sizes
double calculatedLot1 = 0.0;
double calculatedLot2 = 0.0;

//--- Chart Object Names
#define PANEL_NAME         "Panel_EA"
#define HEADER_LABEL       "Label_Header"
#define LABEL_STATUS       "Label_Status"
#define BTN_OPEN           "Btn_Open"
#define BTN_CLOSE          "Btn_Close"
#define BTN_PRICE_TRACK    "Btn_PriceTrack"
#define BTN_TRAILING_STOP  "Btn_TrailingStop"
#define BTN_COUNTDOWN      "Btn_Countdown"
#define BTN_CALC_LOT       "Btn_CalcLot"
#define LABEL_COUNTDOWN    "Label_Countdown"
#define LABEL_LOT_INFO     "Label_LotInfo"
#define LABEL_TRAILING_INFO "Label_TrailingInfo"
#define LABEL_MARGIN_INFO  "Label_MarginInfo"
#define LABEL_CALC_LOT     "Label_CalcLot"

//+------------------------------------------------------------------+
//| OnInit / OnDeinit                                               |
//+------------------------------------------------------------------+
int OnInit()
{
   CreateSimpleUI();
   UpdateButtonStates();
   if(MagicNumber_1 == MagicNumber_2)
   {
      Alert("MagicNumber_1 and MagicNumber_2 cannot be the same. Please set unique values.");
      return(INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){ DeleteUI(); }

//+------------------------------------------------------------------+
//| OnTick                                                          |
//+------------------------------------------------------------------+
void OnTick()
{
   UpdateLabels();
   UpdateMarginInfo();

   if(countdownEnabled)  UpdateCountdownLabel();
   else                  ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "Countdown: OFF");

   if(priceTrackingEnabled && ordersOpened)
      ModifyPendingOrders();

   if(!autoOrderPlaced && !ordersOpened && countdownEnabled)
      CheckAndPlaceAutoOrders();

   if(ordersOpened)
      CheckOrderExecution();

   if(trailingStopActive)
      ApplyModifiedTrailingStop();

   // Fixed: Check auto price track disable
   if(countdownEnabled && priceTrackingEnabled && !priceTrackDisabledByNews)
      CheckAutoPriceTrackDisable();
      
   UpdateTrailingInfo();
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam==BTN_OPEN)
      {
         HandleOpenOrders();
         ObjectSetInteger(0, BTN_OPEN, OBJPROP_STATE, 0);
      }
      else if(sparam==BTN_CLOSE)
      {
         HandleCloseOrders();
         ObjectSetInteger(0, BTN_CLOSE, OBJPROP_STATE, 0);
      }
      else if(sparam==BTN_PRICE_TRACK)
      {
         priceTrackingEnabled = !priceTrackingEnabled;
         priceTrackDisabledByNews = false;  // Reset flag when manually toggled
         UpdateButtonStates();
         ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_STATE, 0);
      }
      else if(sparam==BTN_TRAILING_STOP)
      {
         trailingStopActive = !trailingStopActive;
         UpdateButtonStates();
         ObjectSetInteger(0, BTN_TRAILING_STOP, OBJPROP_STATE, 0);
      }
      else if(sparam==BTN_COUNTDOWN)
      {
         countdownEnabled = !countdownEnabled;
         priceTrackDisabledByNews = false;  // Reset flag when countdown toggled
         UpdateButtonStates();
         ObjectSetInteger(0, BTN_COUNTDOWN, OBJPROP_STATE, 0);
      }
      else if(sparam==BTN_CALC_LOT)
      {
         CalculateLotSize();
         ObjectSetInteger(0, BTN_CALC_LOT, OBJPROP_STATE, 0);
      }
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size from Margin                                  |
//+------------------------------------------------------------------+
void CalculateLotSize()
{
   // Get account information
   double margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   // For XAUUSD at leverage 1:500
   double goldPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   // Calculate contract size (typically 100 oz for gold)
   double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize == 0) contractSize = 100;  // Default for gold
   
   // Calculate margin required per lot
   // Formula: (Contract Size * Market Price) / Leverage
   double marginPerLot = (contractSize * goldPrice) / (double)leverage;
   
   // Calculate risk amount
   double riskAmount = margin * (RiskPercentage / 100.0);
   
   // Calculate lot size based on risk
   double totalLots = riskAmount / marginPerLot;
   
   // Split between two orders
   calculatedLot1 = NormalizeDouble(totalLots / 2.0, 2);
   calculatedLot2 = NormalizeDouble(totalLots / 2.0, 2);
   
   // Ensure minimum lot size
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if(calculatedLot1 < minLot) calculatedLot1 = minLot;
   if(calculatedLot2 < minLot) calculatedLot2 = minLot;
   
   // Update display
   string calcInfo = StringFormat("Calculated Lots: %.2f / %.2f (Risk %.1f%%)", 
                                   calculatedLot1, calculatedLot2, RiskPercentage);
   ObjectSetString(0, LABEL_CALC_LOT, OBJPROP_TEXT, calcInfo);
   
   // Show calculation details
   Alert(StringFormat("Lot Calculation:\nMargin: $%.2f\nGold Price: $%.2f\nLeverage: 1:%d\nRisk: %.1f%%\nLot1: %.2f\nLot2: %.2f",
                      margin, goldPrice, (int)leverage, RiskPercentage, calculatedLot1, calculatedLot2));
}

//+------------------------------------------------------------------+
//| Get Effective Lot Sizes                                         |
//+------------------------------------------------------------------+
double GetEffectiveLot1()
{
   if(UseCalculatedLots && calculatedLot1 > 0) return calculatedLot1;
   return LotSize_Order1;
}

double GetEffectiveLot2()
{
   if(UseCalculatedLots && calculatedLot2 > 0) return calculatedLot2;
   return LotSize_Order2;
}

//+------------------------------------------------------------------+
//| Order Management                                                |
//+------------------------------------------------------------------+
void HandleOpenOrders()
{
   if(!ordersOpened)
   {
      PlaceAllPendingOrders();
      ordersOpened   = true;
      autoOrderPlaced= true;
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: Orders opened");
   }
}

void HandleCloseOrders()
{
   CloseAllOrders();
   ordersOpened    = false;
   autoOrderPlaced = false;
   priceTrackDisabledByNews = false;  // Reset flag
   buyPendingPrice1 = 0.0;
   sellPendingPrice1 = 0.0;
   lastBuySL_1 = 0.0; lastBuySL_2 = 0.0;
   lastSellSL_1 = 0.0; lastSellSL_2 = 0.0;
   ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: All orders closed");
}

void PlaceAllPendingOrders()
{
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   // Get effective lot sizes
   double lot1 = GetEffectiveLot1();
   double lot2 = GetEffectiveLot2();

   // Buy Orders with separate TP for each order
   double buyPrice1 = ask + (BuyStopPoints * _Point);
   buyPendingPrice1 = buyPrice1;
   double buyTp1 = buyPrice1 + (TP_Points_Order1 * _Point);  // TP for order #1
   double buyTp2 = buyPrice1 + (TP_Points_Order2 * _Point);  // TP for order #2
   double buySl = (SL_Points>0)? buyPrice1 - (SL_Points * _Point):0.0;
   double buyPrice2 = buyPrice1 + (Order2GapPoints * _Point);
   
   buyStopTicket1 = SendPendingOrder(ORDER_TYPE_BUY_STOP, lot1, buyPrice1, buySl, buyTp1, MagicNumber_1);
   buyStopTicket2 = SendPendingOrder(ORDER_TYPE_BUY_STOP, lot2, buyPrice2, buySl, buyTp2, MagicNumber_2);

   // Sell Orders with separate TP for each order
   double sellPrice1 = bid - (SellStopPoints * _Point);
   sellPendingPrice1 = sellPrice1;
   double sellTp1 = sellPrice1 - (TP_Points_Order1 * _Point);  // TP for order #1
   double sellTp2 = sellPrice1 - (TP_Points_Order2 * _Point);  // TP for order #2
   double sellSl = (SL_Points>0)? sellPrice1 + (SL_Points * _Point):0.0;
   double sellPrice2 = sellPrice1 - (Order2GapPoints * _Point);
   
   sellStopTicket1 = SendPendingOrder(ORDER_TYPE_SELL_STOP, lot1, sellPrice1, sellSl, sellTp1, MagicNumber_1);
   sellStopTicket2 = SendPendingOrder(ORDER_TYPE_SELL_STOP, lot2, sellPrice2, sellSl, sellTp2, MagicNumber_2);
}

ulong SendPendingOrder(ENUM_ORDER_TYPE orderType,double lots,double price,double sl,double tp, ulong magic)
{
   if(lots <= 0) return(0);
   
   MqlTradeRequest req;  MqlTradeResult res;
   ZeroMemory(req);      ZeroMemory(res);

   req.action       = TRADE_ACTION_PENDING;
   req.symbol       = Symbol();
   req.volume       = lots;
   req.price        = price;
   req.tp           = tp;
   req.sl           = sl;
   req.deviation    = 50;
   req.type         = orderType;
   req.type_filling = ORDER_FILLING_FOK;
   req.magic        = magic;

   if(!OrderSend(req,res))
   {
      Print("SendPendingOrder error:",GetLastError());
      return(0);
   }
   if(res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED)
   {
      Print("Order placed: type=",orderType,", lots=",lots,", price=",price,", ticket=",res.order, ", magic=", magic);
      return(res.order);
   }
   return(0);
}

//+------------------------------------------------------------------+
//| Price Tracking                                                  |
//+------------------------------------------------------------------+
void ModifyPendingOrders()
{
   if(buyStopTicket1 != 0 && OrderSelect(buyStopTicket1))
   {
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP && OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
      {
         double newPrice1 = SymbolInfoDouble(Symbol(), SYMBOL_ASK) + (BuyStopPoints * _Point);
         if(MathAbs(newPrice1 - OrderGetDouble(ORDER_PRICE_OPEN)) > _Point)
         {
            buyPendingPrice1 = newPrice1;
            double buyTp1 = newPrice1 + (TP_Points_Order1 * _Point);
            double buyTp2 = newPrice1 + (TP_Points_Order2 * _Point);
            double buySl = (SL_Points>0)? newPrice1 - SL_Points*_Point : 0.0;
            
            trade.OrderModify(buyStopTicket1, newPrice1, buySl, buyTp1, ORDER_TIME_GTC, 0, 50);
            if(buyStopTicket2!=0) 
               trade.OrderModify(buyStopTicket2, newPrice1 + (Order2GapPoints * _Point), buySl, buyTp2, ORDER_TIME_GTC, 0, 50);
         }
      }
   }

   if(sellStopTicket1 != 0 && OrderSelect(sellStopTicket1))
   {
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP && OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
      {
         double newPrice1 = SymbolInfoDouble(Symbol(), SYMBOL_BID) - (SellStopPoints * _Point);
         if(MathAbs(newPrice1 - OrderGetDouble(ORDER_PRICE_OPEN)) > _Point)
         {
            sellPendingPrice1 = newPrice1;
            double sellTp1 = newPrice1 - (TP_Points_Order1 * _Point);
            double sellTp2 = newPrice1 - (TP_Points_Order2 * _Point);
            double sellSl = (SL_Points>0)? newPrice1 + SL_Points*_Point : 0.0;
            
            trade.OrderModify(sellStopTicket1, newPrice1, sellSl, sellTp1, ORDER_TIME_GTC, 0, 50);
            if(sellStopTicket2!=0) 
               trade.OrderModify(sellStopTicket2, newPrice1 - (Order2GapPoints * _Point), sellSl, sellTp2, ORDER_TIME_GTC, 0, 50);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check Auto Price Track Disable (FIXED)                          |
//+------------------------------------------------------------------+
void CheckAutoPriceTrackDisable()
{
   if(ClosePriceTrackBeforeSeconds <= 0) return;

   datetime currentTimeInZone = GetCurrentTimeInZone();
   datetime newsDateTimeInZone = GetNextNewsTime();
   long secondsLeft = (long)(newsDateTimeInZone - currentTimeInZone);

   // Check if it's time to disable price tracking
   if(secondsLeft > 0 && secondsLeft <= ClosePriceTrackBeforeSeconds)
   {
      priceTrackingEnabled = false;
      priceTrackDisabledByNews = true;
      UpdateButtonStates();
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: Price Track OFF (News)");
      Print("Price tracking disabled automatically. ", secondsLeft, " seconds before news.");
   }
}

//+------------------------------------------------------------------+
//| Order Execution Check                                           |
//+------------------------------------------------------------------+
void CheckOrderExecution()
{
   bool buyExecuted = false;
   if(buyStopTicket1!=0 && (!OrderSelect(buyStopTicket1) || OrderGetInteger(ORDER_STATE)!=ORDER_STATE_PLACED))
      buyExecuted = true;
   else if(buyStopTicket2!=0 && (!OrderSelect(buyStopTicket2) || OrderGetInteger(ORDER_STATE)!=ORDER_STATE_PLACED))
      buyExecuted = true;

   if(buyExecuted) CancelAllSellPendingOrders();

   bool sellExecuted = false;
   if(sellStopTicket1!=0 && (!OrderSelect(sellStopTicket1) || OrderGetInteger(ORDER_STATE)!=ORDER_STATE_PLACED))
      sellExecuted = true;
   else if(sellStopTicket2!=0 && (!OrderSelect(sellStopTicket2) || OrderGetInteger(ORDER_STATE)!=ORDER_STATE_PLACED))
      sellExecuted = true;

   if(sellExecuted) CancelAllBuyPendingOrders();
}

void CancelAllBuyPendingOrders()
{
   if(buyStopTicket1!=0){ trade.OrderDelete(buyStopTicket1); buyStopTicket1=0; }
   if(buyStopTicket2!=0){ trade.OrderDelete(buyStopTicket2); buyStopTicket2=0; }
}

void CancelAllSellPendingOrders()
{
   if(sellStopTicket1!=0){ trade.OrderDelete(sellStopTicket1); sellStopTicket1=0; }
   if(sellStopTicket2!=0){ trade.OrderDelete(sellStopTicket2); sellStopTicket2=0; }
}

//+------------------------------------------------------------------+
//| Modified Trailing Stop                                         |
//+------------------------------------------------------------------+
void ApplyModifiedTrailingStop()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol())
         {
            long   posType   = PositionGetInteger(POSITION_TYPE);
            ulong  posMagic  = PositionGetInteger(POSITION_MAGIC);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double newSL     = 0.0;
            int trailingStart, trailingStep, trailingDist;
            
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);

            if(posMagic == MagicNumber_1)
            {
               trailingStart = TrailingStartPoints_1;
               trailingStep  = TrailingStepPoints_1;
               trailingDist  = TrailingDistancePoints_1;
            }
            else if(posMagic == MagicNumber_2)
            {
               trailingStart = TrailingStartPoints_2;
               trailingStep  = TrailingStepPoints_2;
               trailingDist  = TrailingDistancePoints_2;
            }
            else continue;
            
            if(posType == POSITION_TYPE_BUY)
            {
               double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
               double profitInPoints = (bid - entryPrice) / _Point;
               
               if(profitInPoints >= trailingStart)
               {
                  newSL = bid - (trailingDist * _Point);
                  if(trailingDist == 0) newSL = entryPrice;
                 
                  if(currentSL == 0 || (newSL > currentSL && (newSL - currentSL) >= (trailingStep * _Point)))
                  {
                     if( (posMagic == MagicNumber_1 && newSL != lastBuySL_1) || (posMagic == MagicNumber_2 && newSL != lastBuySL_2) )
                     {
                        if(trade.PositionModify(ticket, newSL, currentTP))
                        {
                           if(posMagic == MagicNumber_1) lastBuySL_1 = newSL; else lastBuySL_2 = newSL;
                           Print("Buy position (Magic ", posMagic, ") SL moved to: ", newSL);
                        }
                     }
                  }
               }
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
               double profitInPoints = (entryPrice - ask) / _Point;
               
               if(profitInPoints >= trailingStart)
               {
                  newSL = ask + (trailingDist * _Point);
                  if(trailingDist == 0) newSL = entryPrice;
                 
                  if(currentSL == 0 || (newSL < currentSL && (currentSL - newSL) >= (trailingStep * _Point)))
                  {
                     if( (posMagic == MagicNumber_1 && newSL != lastSellSL_1) || (posMagic == MagicNumber_2 && newSL != lastSellSL_2) )
                     {
                        if(trade.PositionModify(ticket, newSL, currentTP))
                        {
                           if(posMagic == MagicNumber_1) lastSellSL_1 = newSL; else lastSellSL_2 = newSL;
                           Print("Sell position (Magic ", posMagic, ") SL moved to: ", newSL);
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Trailing Info Label                                      |
//+------------------------------------------------------------------+
void UpdateTrailingInfo()
{
   if(!trailingStopActive)
   {
      ObjectSetString(0, LABEL_TRAILING_INFO, OBJPROP_TEXT, "Trailing: OFF");
      return;
   }
   
   string trailingText = "Trailing: Waiting...";
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol())
         {
            long   posType  = PositionGetInteger(POSITION_TYPE);
            ulong  posMagic = PositionGetInteger(POSITION_MAGIC);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
             
             int    trailingStart = 0;
             string orderId = "";

             if(posMagic == MagicNumber_1) { trailingStart = TrailingStartPoints_1; orderId = "#1"; }
             else if(posMagic == MagicNumber_2) { trailingStart = TrailingStartPoints_2; orderId = "#2"; }
             else continue;
            
            if(posType == POSITION_TYPE_BUY)
            {
               double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
               double profitInPoints = (bid - entryPrice) / _Point;
               if(profitInPoints >= trailingStart) trailingText = StringFormat("Trailing: ACTIVE (BUY %s +%.0f pts)", orderId, profitInPoints);
               else trailingText = StringFormat("Trailing: Waiting (BUY %s %.0f/%.0f pts)", orderId, profitInPoints, (double)trailingStart);
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
               double profitInPoints = (entryPrice - ask) / _Point;
               if(profitInPoints >= trailingStart) trailingText = StringFormat("Trailing: ACTIVE (SELL %s +%.0f pts)", orderId, profitInPoints);
               else trailingText = StringFormat("Trailing: Waiting (SELL %s %.0f/%.0f pts)", orderId, profitInPoints, (double)trailingStart);
            }
            break;
         }
      }
   }
   ObjectSetString(0, LABEL_TRAILING_INFO, OBJPROP_TEXT, trailingText);
}

//+------------------------------------------------------------------+
//| News Countdown & Timezone Logic                                  |
//+------------------------------------------------------------------+
datetime GetCurrentTimeInZone()
{
   return TimeGMT() + (GetTimezoneOffset() * 3600);
}

datetime GetNextNewsTime()
{
   datetime now_gmt = TimeGMT();
   long timezone_offset_seconds = (long)GetTimezoneOffset() * 3600;
   datetime now_in_selected_tz = (datetime)(now_gmt + timezone_offset_seconds);
   datetime today_start_in_selected_tz = (datetime)(now_in_selected_tz - (now_in_selected_tz % 86400));
   datetime today_news_time_in_tz = (datetime)(today_start_in_selected_tz + (NewsHour * 3600) + (NewsMinute * 60));

   if(now_in_selected_tz > today_news_time_in_tz)
       return (datetime)(today_news_time_in_tz + 86400);
   else
       return today_news_time_in_tz;
}

void UpdateCountdownLabel()
{
   datetime currentTimeInZone = GetCurrentTimeInZone();
   datetime newsDateTimeInZone = GetNextNewsTime();
   long secondsLeftTotal = (long)(newsDateTimeInZone - currentTimeInZone);
   
   if(secondsLeftTotal >= 0)
   {
      int secondsLeft = (int)(secondsLeftTotal % 60);
      int minutesLeft = (int)((secondsLeftTotal / 60) % 60);
      int hoursLeft   = (int)(secondsLeftTotal / 3600);
      string countdownText = StringFormat("News in: %02d:%02d:%02d", hoursLeft, minutesLeft, secondsLeft);
      ObjectSetString(0,LABEL_COUNTDOWN,OBJPROP_TEXT,countdownText);
   }
   else
   {
      ObjectSetString(0,LABEL_COUNTDOWN,OBJPROP_TEXT,"News: Event has passed");
   }
}

void CheckAndPlaceAutoOrders()
{
   if(!countdownEnabled) return;
   
   datetime currentTimeInZone = GetCurrentTimeInZone();
   datetime newsDateTimeInZone = GetNextNewsTime();
   datetime openTime = (datetime)(newsDateTimeInZone - OpenBeforeSeconds);

   if(currentTimeInZone >= openTime && currentTimeInZone < newsDateTimeInZone)
   {
      HandleOpenOrders();
      countdownEnabled = false;
      UpdateButtonStates();
      ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "Countdown: OFF");
   }
}

// --- DST Calculation Functions ---
datetime GetNthWeekdayOfMonth(int year, int month, int weekday, int n)
{
    MqlDateTime dt;
    dt.year = year;
    dt.mon = month;
    dt.day = 1;
    datetime first_day_of_month = StructToTime(dt);
    TimeToStruct(first_day_of_month, dt);
    
    int days_to_add = weekday - dt.day_of_week;
    if (days_to_add < 0) days_to_add += 7;
    
    days_to_add += (n - 1) * 7;
    
    return (datetime)(first_day_of_month + days_to_add * 86400);
}

int GetNewYorkOffset()
{
    MqlDateTime now;
    TimeToStruct(TimeGMT(), now);
    datetime dst_start = (datetime)(GetNthWeekdayOfMonth(now.year, 3, SUNDAY, 2) + 2 * 3600);
    datetime dst_end = (datetime)(GetNthWeekdayOfMonth(now.year, 11, SUNDAY, 1) + 2 * 3600);
    
    if (TimeGMT() >= dst_start && TimeGMT() < dst_end)
        return -4; // EDT
    return -5; // EST
}

int GetLondonOffset()
{
    MqlDateTime now_struct;
    TimeToStruct(TimeGMT(), now_struct);
    
    MqlDateTime dt_start;
    dt_start.year = now_struct.year;
    dt_start.mon = 3;
    dt_start.day = 31;
    datetime last_day_march_gmt = StructToTime(dt_start);
    
    MqlDateTime dt_start_temp;
    TimeToStruct(last_day_march_gmt, dt_start_temp);
    
    datetime dst_start = (datetime)(last_day_march_gmt - (long)dt_start_temp.day_of_week * 86400 + 1 * 3600);

    MqlDateTime dt_end;
    dt_end.year = now_struct.year;
    dt_end.mon = 10;
    dt_end.day = 31;
    datetime last_day_october_gmt = StructToTime(dt_end);
    
    MqlDateTime dt_end_temp;
    TimeToStruct(last_day_october_gmt, dt_end_temp);
    
    datetime dst_end = (datetime)(last_day_october_gmt - (long)dt_end_temp.day_of_week * 86400 + 1 * 3600);

    if (TimeGMT() >= dst_start && TimeGMT() < dst_end)
        return 1; // BST
    return 0; // GMT
}

int GetSydneyOffset()
{
    MqlDateTime now;
    TimeToStruct(TimeGMT(), now);
    datetime dst_start = (datetime)(GetNthWeekdayOfMonth(now.year, 10, SUNDAY, 1) + 2 * 3600);
    datetime dst_end = (datetime)(GetNthWeekdayOfMonth(now.year, 4, SUNDAY, 1) + 3 * 3600);
    
    if (now.mon >= 10 || now.mon < 4)
    {
        if (TimeGMT() >= dst_start || TimeGMT() < dst_end) 
        return 11; // AEDT
    }
    return 10; // AEST
}

int GetTimezoneOffset()
{
   switch(Timezone)
   {
      case BANGKOK:  return 7;
      case TOKYO:    return 9;
      case LONDON:   return GetLondonOffset();
      case NEW_YORK: return GetNewYorkOffset();
      case SYDNEY:   return GetSydneyOffset();
   }
   return 0;
}

string GetTimezoneString()
{
   int offset = GetTimezoneOffset();
   string city_name;
   switch(Timezone)
   {
      case BANGKOK:  city_name = "Bangkok"; break;
      case TOKYO:    city_name = "Tokyo"; break;
      case LONDON:   city_name = "London"; break;
      case NEW_YORK: city_name = "New York"; break;
      case SYDNEY:   city_name = "Sydney"; break;
   }
   
   if(offset >= 0)
      return StringFormat("%s / GMT+%d", city_name, offset);
   else
      return StringFormat("%s / GMT%d", city_name, offset);
}

//+------------------------------------------------------------------+
//| UI Helpers                                                      |
//+------------------------------------------------------------------+
string GetLotDisplayText()
{
   double lot1 = GetEffectiveLot1();
   double lot2 = GetEffectiveLot2();
   string mode = UseCalculatedLots ? " (Calc)" : " (Manual)";
   return StringFormat("Lots: %.2f / %.2f%s", lot1, lot2, mode);
}

void UpdateMarginInfo()
{
   double margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   double goldPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   string marginText = StringFormat("Margin: $%.2f | Gold: $%.2f | Lev: 1:%d", 
                                     margin, goldPrice, (int)leverage);
   ObjectSetString(0, LABEL_MARGIN_INFO, OBJPROP_TEXT, marginText);
}

void CreateSimpleUI()
{
   ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, 400);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, 580);  // Increased height
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, C'245,245,245');

   ObjectCreate(0, HEADER_LABEL, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, HEADER_LABEL, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, HEADER_LABEL, OBJPROP_XDISTANCE, 25);
   ObjectSetInteger(0, HEADER_LABEL, OBJPROP_YDISTANCE, 20);
   ObjectSetString(0, HEADER_LABEL, OBJPROP_TEXT, "NonfarmRich EA - Enhanced");
   ObjectSetString(0, HEADER_LABEL, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, HEADER_LABEL, OBJPROP_FONTSIZE, 16);

   ObjectCreate(0, LABEL_STATUS, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, LABEL_STATUS, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, LABEL_STATUS, OBJPROP_XDISTANCE, 25);
   ObjectSetInteger(0, LABEL_STATUS, OBJPROP_YDISTANCE, 50);
   ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: Ready");
   ObjectSetString(0, LABEL_STATUS, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, LABEL_STATUS, OBJPROP_FONTSIZE, 12);

   CreateButton(BTN_OPEN, 25, 80, 170, 45, "Open Orders", C'34,139,34', clrWhite);
   CreateButton(BTN_CLOSE, 205, 80, 170, 45, "Close All", C'220,20,60', clrWhite);
   CreateButton(BTN_PRICE_TRACK, 25, 140, 350, 40, "Price Track: ON", C'34,139,34', clrWhite);
   CreateButton(BTN_TRAILING_STOP, 25, 190, 350, 40, "Trailing Stop: ON", C'34,139,34', clrWhite);
   CreateButton(BTN_COUNTDOWN, 25, 240, 350, 40, "Countdown: ON", C'70,130,180', clrWhite);
   CreateButton(BTN_CALC_LOT, 25, 290, 350, 40, "Calculate Lot Size", C'255,140,0', clrWhite);

   CreateLabel(LABEL_LOT_INFO, 25, 340, GetLotDisplayText(), C'255,140,0', 14, "Arial Bold");
   CreateLabel(LABEL_MARGIN_INFO, 25, 365, "Margin: Loading...", C'0,100,200', 12, "Arial Bold");
   CreateLabel(LABEL_CALC_LOT, 25, 390, "Calculated Lots: Not calculated", C'100,100,100', 11, "Arial");
   CreateLabel(LABEL_COUNTDOWN, 25, 415, "News in: --:--:--", C'255,0,0', 16, "Arial Bold");
   CreateLabel(LABEL_TRAILING_INFO, 25, 445, "Trailing: ON", C'0,100,150', 12, "Arial Bold");

   CreateLabel("LABEL_PARAMS", 25, 475, "Trading Parameters:", C'0,0,128', 13, "Arial Bold");
   CreateLabel("LABEL_POINTS", 25, 500, StringFormat("Buy/Sell Stop: %d | SL: %d", BuyStopPoints, SL_Points), C'105,105,105', 11, "Arial");
   CreateLabel("LABEL_TP_INFO", 25, 520, StringFormat("TP Order#1: %d | TP Order#2: %d", 
            TP_Points_Order1, TP_Points_Order2), C'105,105,105', 11, "Arial");
   CreateLabel("LABEL_TRAILING1", 25, 540, StringFormat("Trail#1: Start %d | Step %d | Dist %d", TrailingStartPoints_1, TrailingStepPoints_1, TrailingDistancePoints_1), C'105,105,105', 11, "Arial");
   CreateLabel("LABEL_TRAILING2", 25, 560, StringFormat("Trail#2: Start %d | Step %d | Dist %d", TrailingStartPoints_2, TrailingStepPoints_2, TrailingDistancePoints_2), C'105,105,105', 11, "Arial");
   CreateLabel("LABEL_NEWS_TIME", 25, 580, StringFormat("News: %02d:%02d (%s)", NewsHour, NewsMinute, GetTimezoneString()), C'255,165,0', 11, "Arial");
}

void CreateButton(string name, int x, int y, int width, int height, string text, color bg_color, color text_color)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
}

void CreateLabel(string name, int x, int y, string text, color text_color, int font_size, string font_name)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, font_name);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
}

//+------------------------------------------------------------------+
//| Update Functions                                                |
//+------------------------------------------------------------------+
void UpdateLabels()
{
   ObjectSetString(0, "LABEL_NEWS_TIME", OBJPROP_TEXT, StringFormat("News: %02d:%02d (%s)", NewsHour, NewsMinute, GetTimezoneString()));
   ObjectSetString(0, LABEL_LOT_INFO, OBJPROP_TEXT, GetLotDisplayText());
   ObjectSetString(0, "LABEL_TP_INFO", OBJPROP_TEXT, StringFormat("TP Order#1: %d | TP Order#2: %d", 
            TP_Points_Order1, TP_Points_Order2));
}

void UpdateButtonStates()
{
   string text; color bg_color;
   text = "Price Track: " + (priceTrackingEnabled ? "ON" : "OFF");
   bg_color = priceTrackingEnabled ? C'34,139,34' : C'128,128,128';
   ObjectSetString(0, BTN_PRICE_TRACK, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_BGCOLOR, bg_color);

   text = "Trailing Stop: " + (trailingStopActive ? "ON" : "OFF");
   bg_color = trailingStopActive ? C'34,139,34' : C'128,128,128';
   ObjectSetString(0, BTN_TRAILING_STOP, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_TRAILING_STOP, OBJPROP_BGCOLOR, bg_color);

   text = "Countdown: " + (countdownEnabled ? "ON" : "OFF");
   bg_color = countdownEnabled ? C'70,130,180' : C'128,128,128';
   ObjectSetString(0, BTN_COUNTDOWN, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_COUNTDOWN, OBJPROP_BGCOLOR, bg_color);

   if(ordersOpened){
      ObjectSetString(0, BTN_OPEN, OBJPROP_TEXT, "Orders Active");
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BGCOLOR, C'70,130,180');
   } else {
      ObjectSetString(0, BTN_OPEN, OBJPROP_TEXT, "Open Orders");
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BGCOLOR, C'34,139,34');
   }
}

//+------------------------------------------------------------------+
//| Close All Orders                                                |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         ulong posMagic = PositionGetInteger(POSITION_MAGIC);
         if(posMagic == MagicNumber_1 || posMagic == MagicNumber_2)
         {
            trade.PositionClose(ticket);
         }
      }
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderSelect(ticket))
      {
         ulong orderMagic = OrderGetInteger(ORDER_MAGIC);
         if(orderMagic == MagicNumber_1 || orderMagic == MagicNumber_2)
         {
            trade.OrderDelete(ticket);
         }
      }
   }
   buyStopTicket1 = buyStopTicket2 = 0;
   sellStopTicket1 = sellStopTicket2 = 0;
}

//+------------------------------------------------------------------+
//| Delete UI                                                       |
//+------------------------------------------------------------------+
void DeleteUI()
{
   string objects_to_delete[] = {
      PANEL_NAME, HEADER_LABEL, LABEL_STATUS, BTN_OPEN, BTN_CLOSE, BTN_PRICE_TRACK,
      BTN_TRAILING_STOP, BTN_COUNTDOWN, BTN_CALC_LOT, LABEL_COUNTDOWN, LABEL_LOT_INFO,
      LABEL_TRAILING_INFO, LABEL_MARGIN_INFO, LABEL_CALC_LOT, "LABEL_PARAMS", "LABEL_POINTS", 
      "LABEL_TP_INFO", "LABEL_TRAILING1", "LABEL_TRAILING2", "LABEL_NEWS_TIME"
   };
   for(int i=0; i<ArraySize(objects_to_delete); i++)
      ObjectDelete(0, objects_to_delete[i]);
}
//+------------------------------------------------------------------+