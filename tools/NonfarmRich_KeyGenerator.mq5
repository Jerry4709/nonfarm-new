//+------------------------------------------------------------------+
//|                    NonfarmRich_KeyGenerator.mq5                   |
//|                    License Key Generator Script                    |
//|                    Run as Script in MT5                            |
//+------------------------------------------------------------------+
#property script_show_inputs
#property strict

input string Serial = "TEST1";  // Enter 5-char serial (A-Z, 0-9 only)

//+------------------------------------------------------------------+
void OnStart()
{
   //--- Validate serial length
   if(StringLen(Serial) != 5)
   {
      Alert("Serial must be exactly 5 characters! (A-Z, 0-9)");
      return;
   }

   //--- Validate characters
   string upperSerial = Serial;
   StringToUpper(upperSerial);
   for(int i = 0; i < 5; i++)
   {
      ushort ch = StringGetCharacter(upperSerial, i);
      if(!((ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')))
      {
         Alert("Invalid character '", StringSubstr(upperSerial, i, 1),
               "' at position ", i, ". Use only A-Z and 0-9.");
         return;
      }
   }

   //--- djb2 hash of serial
   ulong hash = 5381;
   for(int i = 0; i < StringLen(upperSerial); i++)
      hash = ((hash << 5) + hash) + (ulong)StringGetCharacter(upperSerial, i);

   //--- XOR with magic constant
   hash ^= 0x4E465249;

   //--- Generate check code
   string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
   int charsLen = StringLen(chars);
   string checkCode = "";
   for(int i = 0; i < 5; i++)
   {
      int idx = (int)((hash >> (i * 5)) & 0x1F) % charsLen;
      checkCode += StringSubstr(chars, idx, 1);
   }

   //--- Build license key
   string key = "NFARM-" + upperSerial + "-" + checkCode;

   //--- Output
   Print("============================================");
   Print("  Serial:      ", upperSerial);
   Print("  License Key: ", key);
   Print("============================================");

   Alert("License Key Generated!\n\n" + key + "\n\nCopy this key to the EA's LicenseKey input.");
   Comment("License Key: " + key);
}
//+------------------------------------------------------------------+
