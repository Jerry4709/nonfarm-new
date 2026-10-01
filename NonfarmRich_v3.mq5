//+------------------------------------------------------------------+
//|                         NonfarmRich_v2.mq5                       |
//|      EA MT5 - News Straddle Stop Orders                          |
//|      v2.0: Login + Auto-Update + Spike Guard + Cancel Toggle     |
//+------------------------------------------------------------------+
#property copyright "NonfarmRich"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//--- Version info
#define EA_VERSION       "3.0.0"
#define EA_BUILD         20261002

//--- Enums (must be declared before inputs)
enum ENUM_TIMEZONE_CITY
{
   BANGKOK,   // Bangkok (GMT+7)
   TOKYO,     // Tokyo (GMT+9)
   LONDON,    // London (GMT+0/+1)
   NEW_YORK,  // New York (GMT-5/-4)
   SYDNEY     // Sydney (GMT+10/+11)
};

enum ENUM_SPIKE_ACTION
{
   SPIKE_WIDEN_PENDING,      // Widen Pending Orders
   SPIKE_DISABLE_TRACKING,   // Disable Price Track
   SPIKE_BOTH                // Both (Widen + Disable Track)
};

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

//--- License
input group   "License Settings"
input string  LicenseKey        = "";        // License Key (NFARM-XXXXX-XXXXX)

//--- Auto-Update
input group   "Auto-Update"
input bool    EnableAutoUpdate   = true;      // Check for updates on startup
input string  GetUpdateURL()     = UPDATE_CHECK_URL; // Version check URL

//--- Pending Orders
input group   "Pending Orders"
input int     BuyStopPoints      = 3000;     // Buy Stop distance (points)
input int     SellStopPoints     = 3000;     // Sell Stop distance (points)
input int     SL_Points          = 0;        // Stop Loss (0 = use Emergency SL)
input int     EmergencySL_Points = 5000;     // Emergency SL when SL=0 (0=disabled)
input int     Order2GapPoints    = 10;       // Extra gap for order #2

//--- Cancel Opposite
input group   "Cancel Opposite Pending"
input bool    DefaultCancelOpposite = true;  // Default: cancel opposite when executed

//--- Take Profit
input group   "Take Profit Settings"
input int     TP_Points_Order1   = 600;      // TP for Order #1 (points)
input int     TP_Points_Order2   = 600;      // TP for Order #2 (points)

//--- Lot Size
input group   "Lot Size Settings"
input double  LotSize_Order1     = 0.1;      // Lot size order #1
input double  LotSize_Order2     = 0.1;      // Lot size order #2
input bool    UseCalculatedLots  = false;    // Use calculated lots from margin
input double  RiskPercentage     = 5.0;      // Risk % for lot calculation

//--- Trailing Stop Order 1
input group   "Trailing Stop - Order 1"
input int     TrailingStartPoints_1    = 300;  // Start when profit >= (points)
input int     TrailingStepPoints_1     = 100;  // Move SL by (points)
input int     TrailingDistancePoints_1 = 50;   // Keep SL distance from price

//--- Trailing Stop Order 2
input group   "Trailing Stop - Order 2"
input int     TrailingStartPoints_2    = 100;
input int     TrailingStepPoints_2     = 0;
input int     TrailingDistancePoints_2 = 0;

//--- News Countdown
input group   "News Countdown"
input ENUM_TIMEZONE_CITY Timezone = LONDON;
input int     NewsHour                      = 9;
input int     NewsMinute                    = 40;
input int     OpenBeforeSeconds             = 30;   // Open pending X sec before news
input int     ClosePriceTrackBeforeSeconds  = 20;   // Disable Price Track X sec before

//--- Spike Guard
input group   "Spike Guard (Pre-News Protection)"
input bool    DefaultSpikeGuardOn    = true;        // Default: Spike Guard ON
input int     SpikeGuardMinutesBefore = 5;          // Active X minutes before news
input int     SpikeThresholdPoints   = 300;         // Spike detection threshold (points)
input int     SpikeCheckPeriodSec    = 10;          // Check period (seconds)
input ENUM_SPIKE_ACTION SpikeAction  = SPIKE_BOTH;  // Action when spike detected
input int     SpikeWidenPoints       = 1000;        // Widen distance (points)

//--- Expert Settings
input group   "Expert Advisor Settings"
input ulong   MagicNumber_1      = 1111;
input ulong   MagicNumber_2      = 2222;

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

//--- License
bool isLicensed = false;

//--- Tickets
ulong buyStopTicket1 = 0, buyStopTicket2 = 0;
ulong sellStopTicket1 = 0, sellStopTicket2 = 0;

//--- Stored pending prices
double buyPendingPrice1 = 0.0;
double sellPendingPrice1 = 0.0;

//--- State flags
bool ordersOpened              = false;
bool priceTrackingEnabled      = true;
bool trailingStopActive        = true;
bool autoOrderPlaced           = false;
bool countdownEnabled          = true;
bool priceTrackDisabledByNews  = false;
bool cancelOppositePendingEnabled = true;   // runtime toggle
bool spikeGuardEnabled         = true;      // runtime toggle

//--- Trailing SL tracking
double lastBuySL_1 = 0.0, lastBuySL_2 = 0.0;
double lastSellSL_1 = 0.0, lastSellSL_2 = 0.0;

//--- Calculated lots
double calculatedLot1 = 0.0;
double calculatedLot2 = 0.0;

//--- Spike Guard state
double spikeReferencePrice = 0.0;
datetime spikeReferenceTime = 0;
bool   spikeGuardArmed = false;
bool   spikeDetected = false;

//--- Modify throttle
uint lastModifyTick = 0;
#define MODIFY_COOLDOWN_MS 500

//--- GlobalVariable persistence prefix
string GV_PREFIX;

//--- Update info
string updateInfo = "";

//+------------------------------------------------------------------+
//| UI Object Names                                                   |
//+------------------------------------------------------------------+
#define PANEL_NAME          "NR_Panel"
#define HEADER_LABEL        "NR_Header"
#define LABEL_STATUS        "NR_Status"
#define LABEL_LICENSE       "NR_License"
#define BTN_OPEN            "NR_BtnOpen"
#define BTN_CLOSE           "NR_BtnClose"
#define BTN_PRICE_TRACK     "NR_BtnPriceTrack"
#define BTN_TRAILING_STOP   "NR_BtnTrailing"
#define BTN_COUNTDOWN       "NR_BtnCountdown"
#define BTN_CANCEL_OPP      "NR_BtnCancelOpp"
#define BTN_SPIKE_GUARD     "NR_BtnSpikeGuard"
#define BTN_CALC_LOT        "NR_BtnCalcLot"
#define LABEL_LOT_INFO      "NR_LotInfo"
#define LABEL_MARGIN_INFO   "NR_MarginInfo"
#define LABEL_CALC_LOT      "NR_CalcLot"
#define LABEL_COUNTDOWN     "NR_Countdown"
#define LABEL_TRAILING_INFO "NR_TrailInfo"
#define LABEL_SPIKE_INFO    "NR_SpikeInfo"
#define LABEL_PARAMS        "NR_Params"
#define LABEL_POINTS        "NR_Points"
#define LABEL_TP_INFO       "NR_TPInfo"
#define LABEL_TRAIL1        "NR_Trail1"
#define LABEL_TRAIL2        "NR_Trail2"
#define LABEL_NEWS_TIME     "NR_NewsTime"
#define LABEL_SPIKE_PARAMS  "NR_SpikeParams"
#define LABEL_VERSION       "NR_Version"

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Init GlobalVariable prefix
   GV_PREFIX = StringFormat("NR%d_", (int)MagicNumber_1);

   //--- Validate magic numbers
   if(MagicNumber_1 == MagicNumber_2)
   {
      Alert("MagicNumber_1 and MagicNumber_2 must be different!");
      return(INIT_FAILED);
   }

   //--- License check
   isLicensed = ValidateLicenseKey(LicenseKey);

   //--- Set runtime toggles from inputs
   cancelOppositePendingEnabled = DefaultCancelOpposite;
   spikeGuardEnabled = DefaultSpikeGuardOn;

   //--- Restore state from GlobalVariables
   LoadTickets();

   //--- Create UI
   CreateUI();
   UpdateButtonStates();

   //--- Update license display
   if(isLicensed)
   {
      string masked = StringSubstr(LicenseKey, 0, 10) + "***";
      ObjectSetString(0, LABEL_LICENSE, OBJPROP_TEXT, "License: Valid (" + masked + ")");
      ObjectSetInteger(0, LABEL_LICENSE, OBJPROP_COLOR, C'34,139,34');
   }
   else
   {
      ObjectSetString(0, LABEL_LICENSE, OBJPROP_TEXT, "License: INVALID - Trading Disabled");
      ObjectSetInteger(0, LABEL_LICENSE, OBJPROP_COLOR, C'220,20,60');
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: INVALID LICENSE");
   }

   //--- Auto-update check (skip in tester)
   if(!MQLInfoInteger(MQL_TESTER) && EnableAutoUpdate)
      CheckForUpdates();

   ChartRedraw(0);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   SaveTickets();
   DeleteUI();
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Always update UI
   UpdateLabels();
   UpdateMarginInfo();

   if(countdownEnabled) UpdateCountdownLabel();
   else ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "Countdown: OFF");

   //--- Block trading if not licensed
   if(!isLicensed)
   {
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: INVALID LICENSE");
      return;
   }

   //--- Auto-order placement before news
   if(!autoOrderPlaced && !ordersOpened && countdownEnabled)
      CheckAndPlaceAutoOrders();

   //--- Auto price track disable before news
   if(countdownEnabled && priceTrackingEnabled && !priceTrackDisabledByNews)
      CheckAutoPriceTrackDisable();

   //--- Spike Guard (runs before Price Track)
   if(spikeGuardEnabled && ordersOpened)
      CheckSpikeGuard();

   //--- Price tracking (move pending with price)
   if(priceTrackingEnabled && ordersOpened)
      ModifyPendingOrders();

   //--- Check if pending orders were executed
   if(ordersOpened)
      CheckOrderExecution();

   //--- State sync (auto-detect all closed)
   SyncOrderState();

   //--- Trailing stop on open positions
   if(trailingStopActive)
      ApplyModifiedTrailingStop();

   //--- Update info labels
   UpdateTrailingInfo();
   UpdateSpikeGuardInfo();
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;

   if(sparam == BTN_OPEN)
   {
      if(isLicensed) HandleOpenOrders();
      else Alert("Invalid License! Cannot open orders.");
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_CLOSE)
   {
      HandleCloseOrders();
      ObjectSetInteger(0, BTN_CLOSE, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_PRICE_TRACK)
   {
      priceTrackingEnabled = !priceTrackingEnabled;
      priceTrackDisabledByNews = false;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_TRAILING_STOP)
   {
      trailingStopActive = !trailingStopActive;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_TRAILING_STOP, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_COUNTDOWN)
   {
      countdownEnabled = !countdownEnabled;
      priceTrackDisabledByNews = false;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_COUNTDOWN, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_CANCEL_OPP)
   {
      cancelOppositePendingEnabled = !cancelOppositePendingEnabled;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_CANCEL_OPP, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_SPIKE_GUARD)
   {
      spikeGuardEnabled = !spikeGuardEnabled;
      if(!spikeGuardEnabled)
      {
         spikeGuardArmed = false;
         spikeDetected = false;
         spikeReferencePrice = 0;
      }
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_STATE, 0);
   }
   else if(sparam == BTN_CALC_LOT)
   {
      CalculateLotSize();
      ObjectSetInteger(0, BTN_CALC_LOT, OBJPROP_STATE, 0);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| OnTradeTransaction - Event-driven execution detection             |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD ||
      trans.type == TRADE_TRANSACTION_ORDER_DELETE)
   {
      if(ordersOpened)
      {
         CheckOrderExecution();
         SyncOrderState();
         SaveTickets();
      }
   }
}

//+------------------------------------------------------------------+
//| DLL IMPORTS                                                      |
//+------------------------------------------------------------------+
#import "wininet.dll"
long InternetOpenW(string agent, int accessType, string proxyName, string proxyBypass, int flags);
long InternetOpenUrlW(long internetSession, string url, string headers, int headersLength, int flags, int context);
int  InternetReadFile(long file, uchar &buffer[], int numBytesToRead, int &numberOfBytesRead);
int  InternetCloseHandle(long inet);
#import

//+------------------------------------------------------------------+
//| URL & String Obfuscation (XOR Encrypted)                         |
//+------------------------------------------------------------------+
string DecryptString(const uchar &enc[])
{
   string res = "";
   for(int i = 0; i < ArraySize(enc); i++)
   {
      res += CharToString((uchar)(enc[i] ^ 0x7A));
   }
   return res;
}

string GetUpdateURL()
{
   uchar enc[] = {18,14,14,10,9,64,85,85,8,27,13,84,29,19,14,18,15,24,15,9,31,8,25,21,20,14,31,20,14,84,25,21,23,85,48,31,8,8,3,78,77,74,67,85,20,21,20,28,27,8,23,87,20,31,13,85,23,27,19,20,85,15,10,30,27,14,31,85,12,31,8,9,19,21,20,84,14,2,14};
   return DecryptString(enc);
}

string GetDownloadURL()
{
   uchar enc[] = {18,14,14,10,9,64,85,85,8,27,13,84,29,19,14,18,15,24,15,9,31,8,25,21,20,14,31,20,14,84,25,21,23,85,48,31,8,8,3,78,77,74,67,85,20,21,20,28,27,8,23,87,20,31,13,85,23,27,19,20,85,52,21,20,28,27,8,23,40,19,25,18,37,12,73,84,31,2,79};
   return DecryptString(enc);
}

string GetAppScriptURL()
{
   uchar enc[] = {18,14,14,10,9,64,85,85,9,25,8,19,10,14,84,29,21,21,29,22,31,84,25,21,23,85,23,27,25,8,21,9,85,9,85,59,49,28,3,25,24,3,16,44,37,79,56,31,54,8,31,46,67,74,21,0,11,16,25,79,50,2,34,2,59,46,3,54,22,12,19,67,54,57,42,43,63,42,51,17,15,72,30,24,66,53,47,57,24,66,79,47,20,16,74,49,34,0,27,0,24,48,27,30,57,49,24,63,13,85,31,2,31,25};
   return DecryptString(enc);
}

//+------------------------------------------------------------------+
//| DLL HTTP GETTER                                                  |
//+------------------------------------------------------------------+
bool HttpGetDLL(string url, string &outContent)
{
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED))
   {
      Alert("Please enable 'Allow DLL imports' in MT5 Settings (Ctrl+O -> Expert Advisors)");
      return false;
   }
   
   long hInternet = InternetOpenW("MT5", 0, NULL, NULL, 0);
   if(hInternet == 0) return false;
   
   long hUrl = InternetOpenUrlW(hInternet, url, NULL, 0, 0x80000000 | 0x00800000, 0);
   if(hUrl == 0)
   {
      InternetCloseHandle(hInternet);
      return false;
   }
   
   uchar buffer[1024];
   int bytesRead = 0;
   outContent = "";
   
   while(InternetReadFile(hUrl, buffer, 1024, bytesRead) != 0 && bytesRead > 0)
   {
      outContent += CharArrayToString(buffer, 0, bytesRead, CP_UTF8);
   }
   
   InternetCloseHandle(hUrl);
   InternetCloseHandle(hInternet);
   return true;
}

//+------------------------------------------------------------------+
//| VALIDATE LICENSE (ONLINE GOOGLE SHEET VIA DLL)                   |
//+------------------------------------------------------------------+
bool ValidateLicenseKey(string key)
{
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
      return true;

   Print("Checking license online with Google Sheets (DLL)...");
   
   string appUrl = GetAppScriptURL();
   string accLogin = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string broker = AccountInfoString(ACCOUNT_COMPANY);
   
   StringReplace(broker, " ", "%20");
   StringReplace(broker, "&", "%26");
   
   string reqUrl = appUrl + "?key=" + key + "&acc=" + accLogin + "&broker=" + broker;
   
   string respText = "";
   if(!HttpGetDLL(reqUrl, respText))
   {
      Print("License server connection failed via DLL.");
      return false;
   }
   
   if(StringFind(respText, "VALID") >= 0)
   {
      Print("License Validated Online! Welcome.");
      return true;
   }
   else
   {
      Print("License Error: ", respText);
      Alert("License Error: ", respText);
      return false;
   }
}

//+------------------------------------------------------------------+
//| AUTO-UPDATE FUNCTIONS                                            |
//+------------------------------------------------------------------+
void CheckForUpdates()
{
   string content = "";
   if(!HttpGetDLL(GetUpdateURL(), content))
   {
      Print("Auto-Update: Connection failed via DLL");
      return;
   }

   //--- Parse version.txt
   string remoteVersion = ParseUpdateValue(content, "VERSION");
   int remoteBuild      = (int)StringToInteger(ParseUpdateValue(content, "BUILD"));
   string downloadUrl   = ParseUpdateValue(content, "DOWNLOAD");
   string changelog     = ParseUpdateValue(content, "CHANGELOG");

   if(remoteBuild > EA_BUILD)
   {
      Print("Update available: v", remoteVersion, " (Build ", remoteBuild, ")");
      updateInfo = "Update v" + remoteVersion + " available";
      
      if(MessageBox("New update available! (v" + remoteVersion + ")\n\n" + changelog + "\n\nDo you want to download it now?",
                    "NonfarmRich Update", MB_YESNO | MB_ICONINFORMATION) == IDYES)
      {
         if(DownloadUpdate(downloadUrl))
         {
            Alert("NonfarmRich EA Update Downloaded!\n\n",
                  "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\n",
                  "Changes: ", changelog, "\n\n",
                  "File saved to: MQL5\\Files\\NonfarmRich_v3_update.ex5\n",
                  "Copy to MQL5\\Experts\\ and recompile to apply.");
         }
      }
   }
   else
   {
      Print("EA is up to date (v", EA_VERSION, " build ", EA_BUILD, ")");
      updateInfo = "Up to date";
   }
}

string ParseUpdateValue(string &content, string key)
{
   string search = key + "=";
   int pos = StringFind(content, search);
   if(pos < 0) return "";

   int startPos = pos + StringLen(search);
   int endPos = StringFind(content, "\n", startPos);
   if(endPos < 0) endPos = StringLen(content);

   string value = StringSubstr(content, startPos, endPos - startPos);
   StringTrimRight(value);
   StringTrimLeft(value);
   return value;
}

bool DownloadUpdate(string url)
{
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) return false;
   
   long hInternet = InternetOpenW("MT5", 0, NULL, NULL, 0);
   if(hInternet == 0) return false;
   
   long hUrl = InternetOpenUrlW(hInternet, url, NULL, 0, 0x80000000 | 0x00800000, 0);
   if(hUrl == 0) { InternetCloseHandle(hInternet); return false; }
   
   int fileHandle = FileOpen("NonfarmRich_v3_update.ex5", FILE_WRITE | FILE_BIN);
   if(fileHandle == INVALID_HANDLE)
   {
      Print("Cannot create update file: ", GetLastError());
      InternetCloseHandle(hUrl);
      InternetCloseHandle(hInternet);
      return false;
   }
   
   uchar buffer[1024];
   int bytesRead = 0;
   
   while(InternetReadFile(hUrl, buffer, 1024, bytesRead) != 0 && bytesRead > 0)
   {
      FileWriteArray(fileHandle, buffer, 0, bytesRead);
   }
   
   FileClose(fileHandle);
   InternetCloseHandle(hUrl);
   InternetCloseHandle(hInternet);
   
   Print("Update downloaded: MQL5\\Files\\NonfarmRich_v3_update.ex5");
   return true;
}
//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingType()
{
   uint filling = (uint)SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
   if((filling & SYMBOL_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

double GetEffectiveSL(double entryPrice, bool isBuy)
{
   int slPts = (SL_Points > 0) ? SL_Points : EmergencySL_Points;
   if(slPts <= 0) return 0.0;

   if(isBuy) return NormalizeDouble(entryPrice - slPts * _Point, _Digits);
   else      return NormalizeDouble(entryPrice + slPts * _Point, _Digits);
}

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
//| LOT SIZE CALCULATION                                              |
//+------------------------------------------------------------------+
void CalculateLotSize()
{
   double margin       = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long   leverage     = AccountInfoInteger(ACCOUNT_LEVERAGE);
   double price        = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize == 0) contractSize = 100;

   double marginPerLot = (contractSize * price) / (double)leverage;
   double riskAmount   = margin * (RiskPercentage / 100.0);
   double totalLots    = riskAmount / marginPerLot;

   calculatedLot1 = NormalizeDouble(totalLots / 2.0, 2);
   calculatedLot2 = NormalizeDouble(totalLots / 2.0, 2);

   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if(calculatedLot1 < minLot) calculatedLot1 = minLot;
   if(calculatedLot2 < minLot) calculatedLot2 = minLot;

   ObjectSetString(0, LABEL_CALC_LOT, OBJPROP_TEXT,
      StringFormat("Calc Lots: %.2f / %.2f (Risk %.1f%%)",
                   calculatedLot1, calculatedLot2, RiskPercentage));

   Alert(StringFormat("Lot Calculation:\nMargin: $%.2f\nPrice: $%.2f\nLeverage: 1:%d\nRisk: %.1f%%\nLot1: %.2f\nLot2: %.2f",
         margin, price, (int)leverage, RiskPercentage, calculatedLot1, calculatedLot2));
}

//+------------------------------------------------------------------+
//| ORDER MANAGEMENT                                                  |
//+------------------------------------------------------------------+
void HandleOpenOrders()
{
   if(ordersOpened) return;

   PlaceAllPendingOrders();
   ordersOpened    = true;
   autoOrderPlaced = true;
   spikeDetected   = false;
   SaveTickets();
   ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: Orders opened");
   UpdateButtonStates();
}

void HandleCloseOrders()
{
   CloseAllOrders();
   ordersOpened              = false;
   autoOrderPlaced           = false;
   priceTrackDisabledByNews  = false;
   spikeDetected             = false;
   spikeGuardArmed           = false;
   spikeReferencePrice       = 0;
   buyPendingPrice1 = 0; sellPendingPrice1 = 0;
   lastBuySL_1 = 0; lastBuySL_2 = 0;
   lastSellSL_1 = 0; lastSellSL_2 = 0;
   SaveTickets();
   ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: All orders closed");
   UpdateButtonStates();
}

void PlaceAllPendingOrders()
{
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double lot1 = GetEffectiveLot1();
   double lot2 = GetEffectiveLot2();

   //--- BUY STOP orders
   double buyPrice1 = NormalizeDouble(ask + BuyStopPoints * _Point, _Digits);
   double buyPrice2 = NormalizeDouble(buyPrice1 + Order2GapPoints * _Point, _Digits);
   buyPendingPrice1 = buyPrice1;

   double buyTp1  = NormalizeDouble(buyPrice1 + TP_Points_Order1 * _Point, _Digits);
   double buyTp2  = NormalizeDouble(buyPrice2 + TP_Points_Order2 * _Point, _Digits);
   double buySl1  = GetEffectiveSL(buyPrice1, true);
   double buySl2  = GetEffectiveSL(buyPrice2, true);

   buyStopTicket1 = SendPendingOrder(ORDER_TYPE_BUY_STOP, lot1, buyPrice1, buySl1, buyTp1, MagicNumber_1);
   buyStopTicket2 = SendPendingOrder(ORDER_TYPE_BUY_STOP, lot2, buyPrice2, buySl2, buyTp2, MagicNumber_2);

   //--- SELL STOP orders
   double sellPrice1 = NormalizeDouble(bid - SellStopPoints * _Point, _Digits);
   double sellPrice2 = NormalizeDouble(sellPrice1 - Order2GapPoints * _Point, _Digits);
   sellPendingPrice1 = sellPrice1;

   double sellTp1  = NormalizeDouble(sellPrice1 - TP_Points_Order1 * _Point, _Digits);
   double sellTp2  = NormalizeDouble(sellPrice2 - TP_Points_Order2 * _Point, _Digits);
   double sellSl1  = GetEffectiveSL(sellPrice1, false);
   double sellSl2  = GetEffectiveSL(sellPrice2, false);

   sellStopTicket1 = SendPendingOrder(ORDER_TYPE_SELL_STOP, lot1, sellPrice1, sellSl1, sellTp1, MagicNumber_1);
   sellStopTicket2 = SendPendingOrder(ORDER_TYPE_SELL_STOP, lot2, sellPrice2, sellSl2, sellTp2, MagicNumber_2);
}

ulong SendPendingOrder(ENUM_ORDER_TYPE orderType, double lots, double price,
                       double sl, double tp, ulong magic)
{
   if(lots <= 0) return 0;

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action       = TRADE_ACTION_PENDING;
   req.symbol       = Symbol();
   req.volume       = lots;
   req.price        = price;
   req.tp           = tp;
   req.sl           = sl;
   req.deviation    = 50;
   req.type         = orderType;
   req.type_filling = GetFillingType();
   req.magic        = magic;

   //--- Retry logic
   for(int attempt = 0; attempt < 3; attempt++)
   {
      ResetLastError();
      if(OrderSend(req, res))
      {
         if(res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED)
         {
            Print("Order placed: type=", EnumToString(orderType),
                  " lots=", lots, " price=", price,
                  " ticket=", res.order, " magic=", magic);
            return res.order;
         }
      }

      int err = GetLastError();
      Print("SendPendingOrder attempt ", attempt + 1, " failed: ", err,
            " retcode=", res.retcode);

      if(res.retcode == TRADE_RETCODE_TIMEOUT || res.retcode == TRADE_RETCODE_REQUOTE ||
         res.retcode == TRADE_RETCODE_PRICE_CHANGED)
      {
         Sleep(200 * (attempt + 1));
         //--- Refresh price
         if(orderType == ORDER_TYPE_BUY_STOP)
            req.price = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK) + BuyStopPoints * _Point, _Digits);
         else
            req.price = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID) - SellStopPoints * _Point, _Digits);
         continue;
      }
      break;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| PRICE TRACKING (with throttle fix)                                |
//+------------------------------------------------------------------+
void ModifyPendingOrders()
{
   //--- Throttle: don't modify more than once per MODIFY_COOLDOWN_MS
   if(GetTickCount() - lastModifyTick < MODIFY_COOLDOWN_MS) return;

   bool modified = false;

   //--- BUY STOP tracking
   if(buyStopTicket1 != 0 && OrderSelect(buyStopTicket1))
   {
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP &&
         OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
      {
         double newPrice1 = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK) + BuyStopPoints * _Point, _Digits);
         double oldPrice  = OrderGetDouble(ORDER_PRICE_OPEN);

         if(MathAbs(newPrice1 - oldPrice) >= 5 * _Point)
         {
            buyPendingPrice1 = newPrice1;
            double newPrice2 = NormalizeDouble(newPrice1 + Order2GapPoints * _Point, _Digits);
            double tp1 = NormalizeDouble(newPrice1 + TP_Points_Order1 * _Point, _Digits);
            double tp2 = NormalizeDouble(newPrice2 + TP_Points_Order2 * _Point, _Digits);
            double sl1 = GetEffectiveSL(newPrice1, true);
            double sl2 = GetEffectiveSL(newPrice2, true);

            trade.OrderModify(buyStopTicket1, newPrice1, sl1, tp1, ORDER_TIME_GTC, 0);
            if(buyStopTicket2 != 0)
               trade.OrderModify(buyStopTicket2, newPrice2, sl2, tp2, ORDER_TIME_GTC, 0);
            modified = true;
         }
      }
   }

   //--- SELL STOP tracking
   if(sellStopTicket1 != 0 && OrderSelect(sellStopTicket1))
   {
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP &&
         OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
      {
         double newPrice1 = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID) - SellStopPoints * _Point, _Digits);
         double oldPrice  = OrderGetDouble(ORDER_PRICE_OPEN);

         if(MathAbs(newPrice1 - oldPrice) >= 5 * _Point)
         {
            sellPendingPrice1 = newPrice1;
            double newPrice2 = NormalizeDouble(newPrice1 - Order2GapPoints * _Point, _Digits);
            double tp1 = NormalizeDouble(newPrice1 - TP_Points_Order1 * _Point, _Digits);
            double tp2 = NormalizeDouble(newPrice2 - TP_Points_Order2 * _Point, _Digits);
            double sl1 = GetEffectiveSL(newPrice1, false);
            double sl2 = GetEffectiveSL(newPrice2, false);

            trade.OrderModify(sellStopTicket1, newPrice1, sl1, tp1, ORDER_TIME_GTC, 0);
            if(sellStopTicket2 != 0)
               trade.OrderModify(sellStopTicket2, newPrice2, sl2, tp2, ORDER_TIME_GTC, 0);
            modified = true;
         }
      }
   }

   if(modified) lastModifyTick = GetTickCount();
}

//+------------------------------------------------------------------+
//| SPIKE GUARD                                                       |
//+------------------------------------------------------------------+
void CheckSpikeGuard()
{
   if(!spikeGuardEnabled || !ordersOpened) return;

   //--- Only active within X minutes before news (when countdown is on)
   if(countdownEnabled)
   {
      datetime currentTime = GetCurrentTimeInZone();
      datetime newsTime    = GetNextNewsTime();
      long secondsToNews   = (long)(newsTime - currentTime);

      if(secondsToNews > SpikeGuardMinutesBefore * 60 || secondsToNews <= 0)
      {
         if(spikeGuardArmed)
         {
            spikeGuardArmed = false;
            spikeReferencePrice = 0;
         }
         return;
      }
   }

   double currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   datetime now = TimeCurrent();

   //--- Initialize reference price
   if(spikeReferencePrice == 0.0)
   {
      spikeReferencePrice = currentBid;
      spikeReferenceTime  = now;
      spikeGuardArmed     = true;
      Print("Spike Guard ARMED. Reference: ", spikeReferencePrice);
      return;
   }

   //--- Calculate movement since reference
   double movement = MathAbs(currentBid - spikeReferencePrice) / _Point;

   //--- Check for spike (continuous)
   if(movement >= SpikeThresholdPoints && !spikeDetected)
   {
      HandleSpikeDetected(movement);
      spikeReferencePrice = currentBid;
      spikeReferenceTime  = now;
      return;
   }

   //--- Reset reference periodically
   if((long)(now - spikeReferenceTime) >= SpikeCheckPeriodSec)
   {
      spikeReferencePrice = currentBid;
      spikeReferenceTime  = now;
   }
}

void HandleSpikeDetected(double movement)
{
   spikeDetected = true;
   Print("!!! SPIKE DETECTED !!! Movement: ", movement, " pts. Action: ", EnumToString(SpikeAction));

   if(SpikeAction == SPIKE_WIDEN_PENDING || SpikeAction == SPIKE_BOTH)
      WidenPendingOrders();

   //--- Always disable price tracking on spike (prevent undoing the widen)
   priceTrackingEnabled = false;
   UpdateButtonStates();

   ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT,
      StringFormat("Status: SPIKE! %.0f pts - Protected", movement));
}

void WidenPendingOrders()
{
   Print("Widening pending orders by ", SpikeWidenPoints, " points");

   //--- Widen Buy Stops (move higher)
   if(buyStopTicket1 != 0 && OrderSelect(buyStopTicket1) &&
      OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
   {
      double curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      double newPrice = NormalizeDouble(curPrice + SpikeWidenPoints * _Point, _Digits);
      double newTP    = NormalizeDouble(newPrice + TP_Points_Order1 * _Point, _Digits);
      double newSL    = GetEffectiveSL(newPrice, true);
      trade.OrderModify(buyStopTicket1, newPrice, newSL, newTP, ORDER_TIME_GTC, 0);
   }
   if(buyStopTicket2 != 0 && OrderSelect(buyStopTicket2) &&
      OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
   {
      double curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      double newPrice = NormalizeDouble(curPrice + SpikeWidenPoints * _Point, _Digits);
      double newTP    = NormalizeDouble(newPrice + TP_Points_Order2 * _Point, _Digits);
      double newSL    = GetEffectiveSL(newPrice, true);
      trade.OrderModify(buyStopTicket2, newPrice, newSL, newTP, ORDER_TIME_GTC, 0);
   }

   //--- Widen Sell Stops (move lower)
   if(sellStopTicket1 != 0 && OrderSelect(sellStopTicket1) &&
      OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
   {
      double curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      double newPrice = NormalizeDouble(curPrice - SpikeWidenPoints * _Point, _Digits);
      double newTP    = NormalizeDouble(newPrice - TP_Points_Order1 * _Point, _Digits);
      double newSL    = GetEffectiveSL(newPrice, false);
      trade.OrderModify(sellStopTicket1, newPrice, newSL, newTP, ORDER_TIME_GTC, 0);
   }
   if(sellStopTicket2 != 0 && OrderSelect(sellStopTicket2) &&
      OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
   {
      double curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      double newPrice = NormalizeDouble(curPrice - SpikeWidenPoints * _Point, _Digits);
      double newTP    = NormalizeDouble(newPrice - TP_Points_Order2 * _Point, _Digits);
      double newSL    = GetEffectiveSL(newPrice, false);
      trade.OrderModify(sellStopTicket2, newPrice, newSL, newTP, ORDER_TIME_GTC, 0);
   }
}

void UpdateSpikeGuardInfo()
{
   if(!spikeGuardEnabled)
   {
      ObjectSetString(0, LABEL_SPIKE_INFO, OBJPROP_TEXT, "Spike Guard: OFF");
      ObjectSetInteger(0, LABEL_SPIKE_INFO, OBJPROP_COLOR, C'128,128,128');
      return;
   }

   if(spikeDetected)
   {
      ObjectSetString(0, LABEL_SPIKE_INFO, OBJPROP_TEXT, "Spike Guard: TRIGGERED!");
      ObjectSetInteger(0, LABEL_SPIKE_INFO, OBJPROP_COLOR, C'220,20,60');
   }
   else if(spikeGuardArmed)
   {
      double currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double movement = (spikeReferencePrice > 0) ?
         MathAbs(currentBid - spikeReferencePrice) / _Point : 0;

      ObjectSetString(0, LABEL_SPIKE_INFO, OBJPROP_TEXT,
         StringFormat("Spike Guard: ARMED (%.0f / %d pts)", movement, SpikeThresholdPoints));
      ObjectSetInteger(0, LABEL_SPIKE_INFO, OBJPROP_COLOR, C'255,140,0');
   }
   else
   {
      ObjectSetString(0, LABEL_SPIKE_INFO, OBJPROP_TEXT, "Spike Guard: Standby");
      ObjectSetInteger(0, LABEL_SPIKE_INFO, OBJPROP_COLOR, C'100,149,237');
   }
}

//+------------------------------------------------------------------+
//| AUTO PRICE TRACK DISABLE                                          |
//+------------------------------------------------------------------+
void CheckAutoPriceTrackDisable()
{
   if(ClosePriceTrackBeforeSeconds <= 0) return;

   datetime currentTimeInZone = GetCurrentTimeInZone();
   datetime newsDateTimeInZone = GetNextNewsTime();
   long secondsLeft = (long)(newsDateTimeInZone - currentTimeInZone);

   if(secondsLeft > 0 && secondsLeft <= ClosePriceTrackBeforeSeconds)
   {
      priceTrackingEnabled = false;
      priceTrackDisabledByNews = true;
      UpdateButtonStates();
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: Price Track OFF (News)");
      Print("Price Track disabled. ", secondsLeft, "s before news.");
   }
}

//+------------------------------------------------------------------+
//| ORDER EXECUTION CHECK (with Cancel Opposite toggle)               |
//+------------------------------------------------------------------+
void CheckOrderExecution()
{
   bool hasBuyPos  = HasPositionByMagic(POSITION_TYPE_BUY);
   bool hasSellPos = HasPositionByMagic(POSITION_TYPE_SELL);

   //--- If cancel opposite is disabled, skip
   if(!cancelOppositePendingEnabled) return;

   //--- Both sides executed (extreme volatility) - don't cancel
   if(hasBuyPos && hasSellPos) return;

   if(hasBuyPos)
   {
      CancelAllSellPendingOrders();
      Print("Buy executed -> Cancelled Sell pending orders");
   }

   if(hasSellPos)
   {
      CancelAllBuyPendingOrders();
      Print("Sell executed -> Cancelled Buy pending orders");
   }
}

bool HasPositionByMagic(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            ((ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber_1 ||
             (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber_2) &&
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == posType)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| CANCEL HELPERS (with state check)                                 |
//+------------------------------------------------------------------+
void SafeCancelOrder(ulong &ticket)
{
   if(ticket == 0) return;
   if(OrderSelect(ticket) && OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
      trade.OrderDelete(ticket);
   ticket = 0;
}

void CancelAllBuyPendingOrders()
{
   SafeCancelOrder(buyStopTicket1);
   SafeCancelOrder(buyStopTicket2);
   SaveTickets();
}

void CancelAllSellPendingOrders()
{
   SafeCancelOrder(sellStopTicket1);
   SafeCancelOrder(sellStopTicket2);
   SaveTickets();
}

//+------------------------------------------------------------------+
//| STATE SYNC - Auto detect when all orders/positions are gone       |
//+------------------------------------------------------------------+
void SyncOrderState()
{
   if(!ordersOpened) return;

   bool hasOrders    = false;
   bool hasPositions = false;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderSelect(ticket))
      {
         ulong magic = (ulong)OrderGetInteger(ORDER_MAGIC);
         if((magic == MagicNumber_1 || magic == MagicNumber_2) &&
            OrderGetString(ORDER_SYMBOL) == Symbol())
         { hasOrders = true; break; }
      }
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
         if((magic == MagicNumber_1 || magic == MagicNumber_2) &&
            PositionGetString(POSITION_SYMBOL) == Symbol())
         { hasPositions = true; break; }
      }
   }

   if(!hasOrders && !hasPositions)
   {
      ordersOpened = false;
      autoOrderPlaced = false;
      priceTrackDisabledByNews = false;
      spikeDetected = false;
      spikeGuardArmed = false;
      spikeReferencePrice = 0;
      buyStopTicket1 = buyStopTicket2 = 0;
      sellStopTicket1 = sellStopTicket2 = 0;
      lastBuySL_1 = lastBuySL_2 = 0;
      lastSellSL_1 = lastSellSL_2 = 0;
      SaveTickets();
      UpdateButtonStates();
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, "Status: All closed (auto-detected)");
      Print("Auto-detected: All orders/positions closed.");
   }
}

//+------------------------------------------------------------------+
//| MODIFIED TRAILING STOP                                            |
//+------------------------------------------------------------------+
void ApplyModifiedTrailingStop()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

      long   posType   = PositionGetInteger(POSITION_TYPE);
      ulong  posMagic  = (ulong)PositionGetInteger(POSITION_MAGIC);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      int trailingStart, trailingStep, trailingDist;

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

      double newSL = 0.0;

      if(posType == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double profitPts = (bid - entryPrice) / _Point;

         if(profitPts >= trailingStart)
         {
            newSL = NormalizeDouble(bid - trailingDist * _Point, _Digits);
            if(trailingDist == 0) newSL = entryPrice;

            bool shouldModify = (currentSL == 0 || 
               (newSL > currentSL && (newSL - currentSL) >= trailingStep * _Point));

            if(shouldModify)
            {
               if(posMagic == MagicNumber_1)
               {
                  if(newSL != lastBuySL_1)
                  {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                     {
                        lastBuySL_1 = newSL;
                        Print("BUY (Magic ", posMagic, ") SL -> ", newSL);
                     }
                  }
               }
               else
               {
                  if(newSL != lastBuySL_2)
                  {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                     {
                        lastBuySL_2 = newSL;
                        Print("BUY (Magic ", posMagic, ") SL -> ", newSL);
                     }
                  }
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double profitPts = (entryPrice - ask) / _Point;

         if(profitPts >= trailingStart)
         {
            newSL = NormalizeDouble(ask + trailingDist * _Point, _Digits);
            if(trailingDist == 0) newSL = entryPrice;

            bool shouldModify = (currentSL == 0 ||
               (newSL < currentSL && (currentSL - newSL) >= trailingStep * _Point));

            if(shouldModify)
            {
               if(posMagic == MagicNumber_1)
               {
                  if(newSL != lastSellSL_1)
                  {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                     {
                        lastSellSL_1 = newSL;
                        Print("SELL (Magic ", posMagic, ") SL -> ", newSL);
                     }
                  }
               }
               else
               {
                  if(newSL != lastSellSL_2)
                  {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                     {
                        lastSellSL_2 = newSL;
                        Print("SELL (Magic ", posMagic, ") SL -> ", newSL);
                     }
                  }
               }
            }
         }
      }
   }
}

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
      if(ticket <= 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

      long   posType  = PositionGetInteger(POSITION_TYPE);
      ulong  posMagic = (ulong)PositionGetInteger(POSITION_MAGIC);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      int trailingStart = 0;
      string orderId = "";

      if(posMagic == MagicNumber_1)      { trailingStart = TrailingStartPoints_1; orderId = "#1"; }
      else if(posMagic == MagicNumber_2) { trailingStart = TrailingStartPoints_2; orderId = "#2"; }
      else continue;

      if(posType == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double pts = (bid - entryPrice) / _Point;
         if(pts >= trailingStart)
            trailingText = StringFormat("Trailing: ACTIVE (BUY %s +%.0f)", orderId, pts);
         else
            trailingText = StringFormat("Trailing: BUY %s %.0f/%d pts", orderId, pts, trailingStart);
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double pts = (entryPrice - ask) / _Point;
         if(pts >= trailingStart)
            trailingText = StringFormat("Trailing: ACTIVE (SELL %s +%.0f)", orderId, pts);
         else
            trailingText = StringFormat("Trailing: SELL %s %.0f/%d pts", orderId, pts, trailingStart);
      }
      break;
   }

   ObjectSetString(0, LABEL_TRAILING_INFO, OBJPROP_TEXT, trailingText);
}

//+------------------------------------------------------------------+
//| NEWS COUNTDOWN & TIMEZONE                                         |
//+------------------------------------------------------------------+
datetime GetCurrentTimeInZone()
{
   return TimeGMT() + (GetTimezoneOffset() * 3600);
}

datetime GetNextNewsTime()
{
   datetime now_gmt = TimeGMT();
   long tz_offset_sec = (long)GetTimezoneOffset() * 3600;
   datetime now_tz = (datetime)(now_gmt + tz_offset_sec);
   datetime today_start = (datetime)(now_tz - (now_tz % 86400));
   datetime today_news = (datetime)(today_start + NewsHour * 3600 + NewsMinute * 60);

   if(now_tz > today_news)
      return (datetime)(today_news + 86400);
   return today_news;
}

void UpdateCountdownLabel()
{
   datetime currentTime = GetCurrentTimeInZone();
   datetime newsTime    = GetNextNewsTime();
   long secTotal = (long)(newsTime - currentTime);

   if(secTotal >= 0)
   {
      int s = (int)(secTotal % 60);
      int m = (int)((secTotal / 60) % 60);
      int h = (int)(secTotal / 3600);
      ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT,
         StringFormat("News in: %02d:%02d:%02d", h, m, s));
   }
   else
      ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "News: Event passed");
}

void CheckAndPlaceAutoOrders()
{
   if(!countdownEnabled) return;

   datetime currentTime = GetCurrentTimeInZone();
   datetime newsTime    = GetNextNewsTime();
   datetime openTime    = (datetime)(newsTime - OpenBeforeSeconds);

   if(currentTime >= openTime && currentTime < newsTime)
   {
      HandleOpenOrders();
      countdownEnabled = false;
      UpdateButtonStates();
      ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "Countdown: OFF (auto-triggered)");
   }
}

//--- DST Functions
datetime GetNthWeekdayOfMonth(int year, int month, int weekday, int n)
{
   MqlDateTime dt;
   dt.year = year; dt.mon = month; dt.day = 1;
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime firstDay = StructToTime(dt);
   TimeToStruct(firstDay, dt);

   int daysToAdd = weekday - dt.day_of_week;
   if(daysToAdd < 0) daysToAdd += 7;
   daysToAdd += (n - 1) * 7;

   return (datetime)(firstDay + daysToAdd * 86400);
}

int GetNewYorkOffset()
{
   MqlDateTime now;
   TimeToStruct(TimeGMT(), now);
   datetime dst_start = (datetime)(GetNthWeekdayOfMonth(now.year, 3, SUNDAY, 2) + 2 * 3600);
   datetime dst_end   = (datetime)(GetNthWeekdayOfMonth(now.year, 11, SUNDAY, 1) + 2 * 3600);

   if(TimeGMT() >= dst_start && TimeGMT() < dst_end) return -4;
   return -5;
}

int GetLondonOffset()
{
   MqlDateTime now_struct;
   TimeToStruct(TimeGMT(), now_struct);

   MqlDateTime dt_s;
   dt_s.year = now_struct.year; dt_s.mon = 3; dt_s.day = 31;
   dt_s.hour = 0; dt_s.min = 0; dt_s.sec = 0;
   datetime lastMarch = StructToTime(dt_s);
   MqlDateTime dt_st;
   TimeToStruct(lastMarch, dt_st);
   datetime dst_start = (datetime)(lastMarch - (long)dt_st.day_of_week * 86400 + 1 * 3600);

   MqlDateTime dt_e;
   dt_e.year = now_struct.year; dt_e.mon = 10; dt_e.day = 31;
   dt_e.hour = 0; dt_e.min = 0; dt_e.sec = 0;
   datetime lastOct = StructToTime(dt_e);
   MqlDateTime dt_et;
   TimeToStruct(lastOct, dt_et);
   datetime dst_end = (datetime)(lastOct - (long)dt_et.day_of_week * 86400 + 1 * 3600);

   if(TimeGMT() >= dst_start && TimeGMT() < dst_end) return 1;
   return 0;
}

int GetSydneyOffset()
{
   MqlDateTime now;
   TimeToStruct(TimeGMT(), now);
   datetime dst_start = (datetime)(GetNthWeekdayOfMonth(now.year, 10, SUNDAY, 1) + 2 * 3600);
   datetime dst_end   = (datetime)(GetNthWeekdayOfMonth(now.year, 4, SUNDAY, 1) + 3 * 3600);

   if(now.mon >= 10 || now.mon < 4)
   {
      if(TimeGMT() >= dst_start || TimeGMT() < dst_end) return 11;
   }
   return 10;
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
   string city;
   switch(Timezone)
   {
      case BANGKOK:  city = "Bangkok";  break;
      case TOKYO:    city = "Tokyo";    break;
      case LONDON:   city = "London";   break;
      case NEW_YORK: city = "New York"; break;
      case SYDNEY:   city = "Sydney";   break;
   }
   if(offset >= 0) return StringFormat("%s / GMT+%d", city, offset);
   else            return StringFormat("%s / GMT%d", city, offset);
}

//+------------------------------------------------------------------+
//| GLOBALVARIABLE PERSISTENCE                                        |
//+------------------------------------------------------------------+
void SaveTickets()
{
   GlobalVariableSet(GV_PREFIX + "BT1",  (double)buyStopTicket1);
   GlobalVariableSet(GV_PREFIX + "BT2",  (double)buyStopTicket2);
   GlobalVariableSet(GV_PREFIX + "ST1",  (double)sellStopTicket1);
   GlobalVariableSet(GV_PREFIX + "ST2",  (double)sellStopTicket2);
   GlobalVariableSet(GV_PREFIX + "OPEN", ordersOpened ? 1.0 : 0.0);
}

void LoadTickets()
{
   if(!GlobalVariableCheck(GV_PREFIX + "BT1")) return;

   buyStopTicket1  = (ulong)GlobalVariableGet(GV_PREFIX + "BT1");
   buyStopTicket2  = (ulong)GlobalVariableGet(GV_PREFIX + "BT2");
   sellStopTicket1 = (ulong)GlobalVariableGet(GV_PREFIX + "ST1");
   sellStopTicket2 = (ulong)GlobalVariableGet(GV_PREFIX + "ST2");
   ordersOpened    = (GlobalVariableGet(GV_PREFIX + "OPEN") > 0.5);

   //--- Validate loaded tickets
   ValidateTicket(buyStopTicket1);
   ValidateTicket(buyStopTicket2);
   ValidateTicket(sellStopTicket1);
   ValidateTicket(sellStopTicket2);

   if(ordersOpened)
      Print("Restored state: BT1=", buyStopTicket1, " BT2=", buyStopTicket2,
            " ST1=", sellStopTicket1, " ST2=", sellStopTicket2);
}

void ValidateTicket(ulong &ticket)
{
   if(ticket == 0) return;

   //--- Check if still a pending order
   if(OrderSelect(ticket)) return;

   //--- Check if it became a position
   if(PositionSelectByTicket(ticket)) return;

   //--- Ticket is gone
   Print("Ticket ", ticket, " no longer valid, clearing.");
   ticket = 0;
}

//+------------------------------------------------------------------+
//| UI CREATION                                                       |
//+------------------------------------------------------------------+
void CreateUI()
{
   int panelW = 420, panelH = 760;

   //--- Panel background
   ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, panelW);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, panelH);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, C'30,30,40');
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BGCOLOR, C'30,30,40');
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_COLOR, C'60,60,80');

   //--- Header
   CreateLabel(HEADER_LABEL, 25, 22, "NonfarmRich EA v2.0", C'0,200,255', 16, "Arial Bold");

   //--- Status
   CreateLabel(LABEL_STATUS, 25, 50, "Status: Ready", C'0,255,100', 12, "Arial Bold");

   //--- License
   CreateLabel(LABEL_LICENSE, 25, 75, "License: Checking...", C'200,200,200', 10, "Arial");

   //--- Buttons
   int btnW = 170, btnH = 40, btnFullW = 365;

   CreateButton(BTN_OPEN,          25,  100, btnW, btnH, "Open Orders",        C'34,139,34',  clrWhite);
   CreateButton(BTN_CLOSE,         205, 100, btnW, btnH, "Close All",          C'220,20,60',  clrWhite);
   CreateButton(BTN_PRICE_TRACK,   25,  150, btnFullW, 35, "Price Track: ON",   C'34,139,34',  clrWhite);
   CreateButton(BTN_TRAILING_STOP, 25,  192, btnFullW, 35, "Trailing Stop: ON", C'34,139,34',  clrWhite);
   CreateButton(BTN_COUNTDOWN,     25,  234, btnFullW, 35, "Countdown: ON",     C'70,130,180', clrWhite);
   CreateButton(BTN_CANCEL_OPP,    25,  276, btnFullW, 35, "Cancel Opposite: ON", C'34,139,34', clrWhite);
   CreateButton(BTN_SPIKE_GUARD,   25,  318, btnFullW, 35, "Spike Guard: ON",   C'178,102,0',  clrWhite);
   CreateButton(BTN_CALC_LOT,      25,  360, btnFullW, 35, "Calculate Lot Size", C'100,100,180', clrWhite);

   //--- Info labels
   CreateLabel(LABEL_LOT_INFO,      25, 405, GetLotDisplayText(),       C'255,180,0',   13, "Arial Bold");
   CreateLabel(LABEL_MARGIN_INFO,   25, 428, "Margin: Loading...",      C'100,180,255', 11, "Arial Bold");
   CreateLabel(LABEL_CALC_LOT,      25, 448, "Calc Lots: Not calculated", C'150,150,150', 10, "Arial");
   CreateLabel(LABEL_COUNTDOWN,     25, 473, "News in: --:--:--",       C'255,50,50',   16, "Arial Bold");
   CreateLabel(LABEL_TRAILING_INFO, 25, 503, "Trailing: Waiting...",    C'0,180,200',   12, "Arial Bold");
   CreateLabel(LABEL_SPIKE_INFO,    25, 528, "Spike Guard: Standby",    C'100,149,237', 12, "Arial Bold");

   //--- Parameters section
   CreateLabel(LABEL_PARAMS, 25, 558, "--- Trading Parameters ---", C'100,150,255', 12, "Arial Bold");

   CreateLabel(LABEL_POINTS, 25, 580,
      StringFormat("Stop: B%d/S%d | SL: %d (Emg: %d)", BuyStopPoints, SellStopPoints, SL_Points, EmergencySL_Points),
      C'140,140,160', 10, "Arial");

   CreateLabel(LABEL_TP_INFO, 25, 600,
      StringFormat("TP#1: %d | TP#2: %d | Gap: %d", TP_Points_Order1, TP_Points_Order2, Order2GapPoints),
      C'140,140,160', 10, "Arial");

   CreateLabel(LABEL_TRAIL1, 25, 620,
      StringFormat("Trail#1: Start %d | Step %d | Dist %d",
                   TrailingStartPoints_1, TrailingStepPoints_1, TrailingDistancePoints_1),
      C'140,140,160', 10, "Arial");

   CreateLabel(LABEL_TRAIL2, 25, 640,
      StringFormat("Trail#2: Start %d | Step %d | Dist %d",
                   TrailingStartPoints_2, TrailingStepPoints_2, TrailingDistancePoints_2),
      C'140,140,160', 10, "Arial");

   CreateLabel(LABEL_NEWS_TIME, 25, 660,
      StringFormat("News: %02d:%02d (%s)", NewsHour, NewsMinute, GetTimezoneString()),
      C'255,200,0', 10, "Arial");

   CreateLabel(LABEL_SPIKE_PARAMS, 25, 680,
      StringFormat("Spike: Thr %d | Widen %d | %dm before",
                   SpikeThresholdPoints, SpikeWidenPoints, SpikeGuardMinutesBefore),
      C'140,140,160', 10, "Arial");

   CreateLabel(LABEL_VERSION, 25, 705,
      StringFormat("v%s | Build %d", EA_VERSION, EA_BUILD),
      C'80,80,100', 9, "Arial");
}

void CreateButton(string name, int x, int y, int w, int h, string text, color bgColor, color txtColor)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txtColor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bgColor);
}

void CreateLabel(string name, int x, int y, string text, color txtColor, int fontSize, string fontName)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, fontName);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txtColor);
}

//+------------------------------------------------------------------+
//| UI UPDATE FUNCTIONS                                               |
//+------------------------------------------------------------------+
void UpdateLabels()
{
   ObjectSetString(0, LABEL_NEWS_TIME, OBJPROP_TEXT,
      StringFormat("News: %02d:%02d (%s)", NewsHour, NewsMinute, GetTimezoneString()));
   ObjectSetString(0, LABEL_LOT_INFO, OBJPROP_TEXT, GetLotDisplayText());
   ObjectSetString(0, LABEL_TP_INFO, OBJPROP_TEXT,
      StringFormat("TP#1: %d | TP#2: %d | Gap: %d", TP_Points_Order1, TP_Points_Order2, Order2GapPoints));
}

void UpdateMarginInfo()
{
   double margin   = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long   leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   double price    = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   int    spread   = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);

   ObjectSetString(0, LABEL_MARGIN_INFO, OBJPROP_TEXT,
      StringFormat("Free: $%.0f | Price: %.2f | Sprd: %d", margin, price, spread));
}

string GetLotDisplayText()
{
   double lot1 = GetEffectiveLot1();
   double lot2 = GetEffectiveLot2();
   string mode = UseCalculatedLots ? " (Calc)" : " (Manual)";
   return StringFormat("Lots: %.2f / %.2f%s", lot1, lot2, mode);
}

void UpdateButtonStates()
{
   //--- Price Track
   string text = "Price Track: " + (priceTrackingEnabled ? "ON" : "OFF");
   color  bg   = priceTrackingEnabled ? C'34,139,34' : C'80,80,80';
   ObjectSetString(0, BTN_PRICE_TRACK, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_PRICE_TRACK, OBJPROP_BORDER_COLOR, bg);

   //--- Trailing Stop
   text = "Trailing Stop: " + (trailingStopActive ? "ON" : "OFF");
   bg   = trailingStopActive ? C'34,139,34' : C'80,80,80';
   ObjectSetString(0, BTN_TRAILING_STOP, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_TRAILING_STOP, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_TRAILING_STOP, OBJPROP_BORDER_COLOR, bg);

   //--- Countdown
   text = "Countdown: " + (countdownEnabled ? "ON" : "OFF");
   bg   = countdownEnabled ? C'70,130,180' : C'80,80,80';
   ObjectSetString(0, BTN_COUNTDOWN, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_COUNTDOWN, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_COUNTDOWN, OBJPROP_BORDER_COLOR, bg);

   //--- Cancel Opposite
   text = "Cancel Opposite: " + (cancelOppositePendingEnabled ? "ON" : "OFF");
   bg   = cancelOppositePendingEnabled ? C'34,139,34' : C'80,80,80';
   ObjectSetString(0, BTN_CANCEL_OPP, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_CANCEL_OPP, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_CANCEL_OPP, OBJPROP_BORDER_COLOR, bg);

   //--- Spike Guard
   text = "Spike Guard: " + (spikeGuardEnabled ? "ON" : "OFF");
   bg   = spikeGuardEnabled ? C'178,102,0' : C'80,80,80';
   ObjectSetString(0, BTN_SPIKE_GUARD, OBJPROP_TEXT, text);
   ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_SPIKE_GUARD, OBJPROP_BORDER_COLOR, bg);

   //--- Open button
   if(ordersOpened)
   {
      ObjectSetString(0, BTN_OPEN, OBJPROP_TEXT, "Orders Active");
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BGCOLOR, C'70,130,180');
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BORDER_COLOR, C'70,130,180');
   }
   else
   {
      ObjectSetString(0, BTN_OPEN, OBJPROP_TEXT, "Open Orders");
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BGCOLOR, C'34,139,34');
      ObjectSetInteger(0, BTN_OPEN, OBJPROP_BORDER_COLOR, C'34,139,34');
   }
}

//+------------------------------------------------------------------+
//| CLOSE ALL ORDERS                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   //--- Close positions first
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
         if(magic == MagicNumber_1 || magic == MagicNumber_2)
            trade.PositionClose(ticket);
      }
   }

   //--- Delete pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderSelect(ticket))
      {
         ulong magic = (ulong)OrderGetInteger(ORDER_MAGIC);
         if(magic == MagicNumber_1 || magic == MagicNumber_2)
            trade.OrderDelete(ticket);
      }
   }

   buyStopTicket1 = buyStopTicket2 = 0;
   sellStopTicket1 = sellStopTicket2 = 0;
}

//+------------------------------------------------------------------+
//| DELETE UI                                                         |
//+------------------------------------------------------------------+
void DeleteUI()
{
   string objs[] = {
      PANEL_NAME, HEADER_LABEL, LABEL_STATUS, LABEL_LICENSE,
      BTN_OPEN, BTN_CLOSE, BTN_PRICE_TRACK, BTN_TRAILING_STOP,
      BTN_COUNTDOWN, BTN_CANCEL_OPP, BTN_SPIKE_GUARD, BTN_CALC_LOT,
      LABEL_LOT_INFO, LABEL_MARGIN_INFO, LABEL_CALC_LOT,
      LABEL_COUNTDOWN, LABEL_TRAILING_INFO, LABEL_SPIKE_INFO,
      LABEL_PARAMS, LABEL_POINTS, LABEL_TP_INFO,
      LABEL_TRAIL1, LABEL_TRAIL2, LABEL_NEWS_TIME,
      LABEL_SPIKE_PARAMS, LABEL_VERSION
   };

   for(int i = 0; i < ArraySize(objs); i++)
      ObjectDelete(0, objs[i]);

   ChartRedraw(0);
}
//+------------------------------------------------------------------+








