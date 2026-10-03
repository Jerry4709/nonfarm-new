with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add Single Mode Anti-Whipsaw inputs
old_single_inputs = '''input int     Single_StopPoints      = 3000;     // Stop distance (points)
input int     Single_SL_Points       = 0;        // Stop Loss (0 = disabled)'''

new_single_inputs = '''input int     Single_StopPoints      = 3000;     // Stop distance (points)
input int     Single_SL_Points       = 0;        // Stop Loss (0 = disabled)
input bool    Single_EnableAntiWhipsaw       = true;        // Enable Breakeven Buffer (Anti-Whipsaw)
input int     Single_BreakevenAfterExecPts   = 30;          // Near-breakeven SL buffer (points)'''

content = content.replace(old_single_inputs, new_single_inputs)

# 2. Update mapping in OnInit
old_single_map = '''      EnableAntiWhipsaw     = false;
      EnableDelayedCancel   = false;
      DelayedCancelSec      = 0;
      BreakevenAfterExecPts = 0;
      ConfirmDirectionPts   = 0;'''

new_single_map = '''      EnableAntiWhipsaw     = Single_EnableAntiWhipsaw;
      EnableDelayedCancel   = false;
      DelayedCancelSec      = 0;
      BreakevenAfterExecPts = Single_BreakevenAfterExecPts;
      ConfirmDirectionPts   = 0;'''

content = content.replace(old_single_map, new_single_map)

# 3. Allow UI Toggling
old_ui_event = '''   else if(sparam == BTN_ANTI_WHIPSAW)
   {
      if(EnableAntiWhipsaw)
      {
         // Toggle freeze/delayed cancel at runtime is not meaningful
         // Show info instead
         Alert(StringFormat("Anti-Whipsaw Settings:\\n" +
            "Delayed Cancel: %s (%d sec)\\n" +
            "Breakeven SL Buffer: %d pts\\n" +
            "Confirm Direction: %d pts\\n\\n" +
            "When triggered: Set near-breakeven SL,\\n" +
            "keep opposite pending, wait to confirm.",
            EnableDelayedCancel ? "ON" : "OFF", DelayedCancelSec,
            BreakevenAfterExecPts, ConfirmDirectionPts));
      }
      else
         Alert("Anti-Whipsaw is DISABLED. Set EnableAntiWhipsaw=true in inputs.");
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 0);
   }'''

new_ui_event = '''   else if(sparam == BTN_ANTI_WHIPSAW)
   {
      EnableAntiWhipsaw = !EnableAntiWhipsaw;
      UpdateButtonStates();
      ObjectSetInteger(0, BTN_ANTI_WHIPSAW, OBJPROP_STATE, 0);
   }'''

content = content.replace(old_ui_event, new_ui_event)

# 4. Update CheckOrderExecution logic to trigger Breakeven even if DelayedCancel is false
old_check = '''   //--- Anti-Whipsaw: Delayed Cancel mode
   if(EnableAntiWhipsaw && EnableDelayedCancel)
   {
      if(hasBuyPos && !awaitingCancelConfirm && !buyExecutedFirst && !sellExecutedFirst)
      {
         //--- Buy was triggered -> set breakeven SL and delay cancel
         awaitingCancelConfirm = true;
         buyExecutedFirst      = true;
         executionTime         = TimeCurrent();
         executionEntryPrice   = GetPositionEntryByMagic(POSITION_TYPE_BUY);
         SetBreakevenOnPositions(POSITION_TYPE_BUY);
         Print("Anti-Whipsaw: Buy triggered. Delaying cancel of Sell Stop.");
      }
      else if(hasSellPos && !awaitingCancelConfirm && !buyExecutedFirst && !sellExecutedFirst)
      {
         //--- Sell was triggered -> set breakeven SL and delay cancel
         awaitingCancelConfirm = true;
         sellExecutedFirst     = true;
         executionTime         = TimeCurrent();
         executionEntryPrice   = GetPositionEntryByMagic(POSITION_TYPE_SELL);
         SetBreakevenOnPositions(POSITION_TYPE_SELL);
         Print("Anti-Whipsaw: Sell triggered. Delaying cancel of Buy Stop.");
      }
   }
   else if(!EnableAntiWhipsaw || !EnableDelayedCancel)
   {
      //--- Normal mode: Immediate cancel opposite
      if(hasBuyPos && !buyExecutedFirst && !sellExecutedFirst)
      {
         buyExecutedFirst = true;
         CancelAllSellPendingOrders();
         Print("Buy triggered -> Canceled all Sell pending orders.");
      }
      if(hasSellPos && !buyExecutedFirst && !sellExecutedFirst)
      {
         sellExecutedFirst = true;
         CancelAllBuyPendingOrders();
         Print("Sell triggered -> Canceled all Buy pending orders.");
      }
   }'''

new_check = '''   //--- Anti-Whipsaw: Breakeven & Delayed Cancel mode
   if(EnableAntiWhipsaw)
   {
      if(hasBuyPos && !awaitingCancelConfirm && !buyExecutedFirst && !sellExecutedFirst)
      {
         //--- Buy was triggered -> set breakeven SL
         buyExecutedFirst      = true;
         executionTime         = TimeCurrent();
         executionEntryPrice   = GetPositionEntryByMagic(POSITION_TYPE_BUY);
         SetBreakevenOnPositions(POSITION_TYPE_BUY);
         
         if(EnableDelayedCancel)
         {
            awaitingCancelConfirm = true;
            Print("Anti-Whipsaw: Buy triggered. Breakeven set. Delaying cancel of Sell Stop.");
         }
         else
         {
            CancelAllSellPendingOrders();
            Print("Anti-Whipsaw: Buy triggered. Breakeven set. Normal cancel opposite.");
         }
      }
      else if(hasSellPos && !awaitingCancelConfirm && !buyExecutedFirst && !sellExecutedFirst)
      {
         //--- Sell was triggered -> set breakeven SL
         sellExecutedFirst     = true;
         executionTime         = TimeCurrent();
         executionEntryPrice   = GetPositionEntryByMagic(POSITION_TYPE_SELL);
         SetBreakevenOnPositions(POSITION_TYPE_SELL);
         
         if(EnableDelayedCancel)
         {
            awaitingCancelConfirm = true;
            Print("Anti-Whipsaw: Sell triggered. Breakeven set. Delaying cancel of Buy Stop.");
         }
         else
         {
            CancelAllBuyPendingOrders();
            Print("Anti-Whipsaw: Sell triggered. Breakeven set. Normal cancel opposite.");
         }
      }
   }
   else
   {
      //--- Normal mode: Immediate cancel opposite, no breakeven
      if(hasBuyPos && !buyExecutedFirst && !sellExecutedFirst)
      {
         buyExecutedFirst = true;
         CancelAllSellPendingOrders();
         Print("Buy triggered -> Canceled all Sell pending orders.");
      }
      if(hasSellPos && !buyExecutedFirst && !sellExecutedFirst)
      {
         sellExecutedFirst = true;
         CancelAllBuyPendingOrders();
         Print("Sell triggered -> Canceled all Buy pending orders.");
      }
   }'''

content = content.replace(old_check, new_check)

# Bump to 4.7.0
content = content.replace('#define EA_VERSION       "4.6.0"', '#define EA_VERSION       "4.7.0"')
content = content.replace('#define EA_BUILD         20261010', '#define EA_BUILD         20261011')
content = content.replace('string EA_VERSION = "4.6.0";', 'string EA_VERSION = "4.7.0";')
content = content.replace('int    EA_BUILD   = 20261010;', 'int    EA_BUILD   = 20261011;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated Anti-Whipsaw functionality!")
