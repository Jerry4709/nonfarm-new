import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace the old Pending and Anti-Whipsaw inputs
old_pending = '''//--- Pending Orders
input group   "--- ⚠️ PENDING MODE ONLY (Modes 1,2,3) ---"
input int     BuyStopPoints      = 3000;     // Buy Stop distance (points)
input int     SellStopPoints     = 3000;     // Sell Stop distance (points)
input int     SL_Points          = 0;        // Stop Loss (0 = disabled)
input int     Order2GapPoints    = 10;       // Extra gap for order #2'''

old_aw = '''//--- Anti-Whipsaw (Fake Spike Protection)
input group   "--- ⚠️ STRADDLE MODE ONLY: Anti-Whipsaw ---"
input bool    EnableAntiWhipsaw       = true;        // Enable Anti-Whipsaw System
input bool    EnableDelayedCancel     = true;        // Don't cancel opposite immediately
input int     DelayedCancelSec        = 5;           // Wait X sec before canceling opposite
input int     BreakevenAfterExecPts   = 30;          // Near-breakeven SL buffer (points)
input int     ConfirmDirectionPts     = 200;         // Confirm when price > X pts from entry'''

new_inputs = '''//--- โหมด STANDARD
input group   "========== 🟢 โหมด STANDARD (ดัก 2 ฝั่ง) =========="
input int     Std_BuyStopPoints      = 3000;     // Buy Stop distance (points)
input int     Std_SellStopPoints     = 3000;     // Sell Stop distance (points)
input int     Std_SL_Points          = 0;        // Stop Loss (0 = disabled)
input int     Std_Order2GapPoints    = 10;       // Extra gap for order #2
input bool    Std_EnableAntiWhipsaw       = true;        // Enable Anti-Whipsaw System
input bool    Std_EnableDelayedCancel     = true;        // Don't cancel opposite immediately
input int     Std_DelayedCancelSec        = 5;           // Wait X sec before canceling opposite
input int     Std_BreakevenAfterExecPts   = 30;          // Near-breakeven SL buffer (points)
input int     Std_ConfirmDirectionPts     = 200;         // Confirm when price > X pts from entry

//--- โหมด SINGLE STOP
input group   "========== 🔵 โหมด STOP ดักฝั่งเดียว (BUY หรือ SELL) =========="
input int     Single_StopPoints      = 3000;     // Stop distance (points)
input int     Single_SL_Points       = 0;        // Stop Loss (0 = disabled)

//--- โหมด MARKET
input group   "========== 🔴 โหมด MARKET (ยิงสดทันที) =========="
input int     Market_SL_Points       = 0;        // Stop Loss (0 = disabled)

//--- Global Shadow Variables for Active Settings
int     BuyStopPoints;
int     SellStopPoints;
int     SL_Points;
int     Order2GapPoints;
bool    EnableAntiWhipsaw;
bool    EnableDelayedCancel;
int     DelayedCancelSec;
int     BreakevenAfterExecPts;
int     ConfirmDirectionPts;'''

content = content.replace(old_pending, new_inputs)
content = content.replace(old_aw, '// (Moved to Standard Mode Inputs)')

# 2. Inject assignment inside OnInit
# Find isLicensed = ValidateLicenseKey(activeKey);
# and insert after if(isLicensed) { ... } or just after spikeGuardEnabled = DefaultSpikeGuardOn;
assign_code = '''
   //--- Dynamic Input Assignment based on Mode
   if(ActiveTradeMode == MODE_STANDARD)
   {
      BuyStopPoints         = Std_BuyStopPoints;
      SellStopPoints        = Std_SellStopPoints;
      SL_Points             = Std_SL_Points;
      Order2GapPoints       = Std_Order2GapPoints;
      EnableAntiWhipsaw     = Std_EnableAntiWhipsaw;
      EnableDelayedCancel   = Std_EnableDelayedCancel;
      DelayedCancelSec      = Std_DelayedCancelSec;
      BreakevenAfterExecPts = Std_BreakevenAfterExecPts;
      ConfirmDirectionPts   = Std_ConfirmDirectionPts;
   }
   else if(ActiveTradeMode == MODE_BUY_STOP_ONLY || ActiveTradeMode == MODE_SELL_STOP_ONLY)
   {
      BuyStopPoints         = Single_StopPoints;
      SellStopPoints        = Single_StopPoints;
      SL_Points             = Single_SL_Points;
      Order2GapPoints       = 0;
      EnableAntiWhipsaw     = false;
      EnableDelayedCancel   = false;
      DelayedCancelSec      = 0;
      BreakevenAfterExecPts = 0;
      ConfirmDirectionPts   = 0;
   }
   else if(ActiveTradeMode == MODE_MARKET_BUY || ActiveTradeMode == MODE_MARKET_SELL)
   {
      BuyStopPoints         = 0;
      SellStopPoints        = 0;
      SL_Points             = Market_SL_Points;
      Order2GapPoints       = 0;
      EnableAntiWhipsaw     = false;
      EnableDelayedCancel   = false;
      DelayedCancelSec      = 0;
      BreakevenAfterExecPts = 0;
      ConfirmDirectionPts   = 0;
   }
'''

content = content.replace('spikeGuardEnabled = DefaultSpikeGuardOn;', 'spikeGuardEnabled = DefaultSpikeGuardOn;' + assign_code)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print('Separated inputs.')
