with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

urlmon_import = '''#import "urlmon.dll"
int URLDownloadToFileW(int pCaller, string szURL, string szFileName, int dwReserved, int lpfnCB);
#import'''

# Add urlmon import right after wininet import
content = content.replace('#import "wininet.dll"', urlmon_import + '\n\n#import "wininet.dll"')

download_func_old = '''bool DownloadUpdate(string url)
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
   
   Print("Update downloaded: MQL5\\\\Files\\\\NonfarmRich_v3_update.ex5");
   return true;
}'''

download_func_new = '''bool DownloadUpdate(string url, string destPath)
{
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) return false;
   
   int res = URLDownloadToFileW(0, url, destPath, 0, 0);
   if(res == 0) // S_OK
   {
      Print("Update downloaded directly to: ", destPath);
      return true;
   }
   else
   {
      Print("URLDownloadToFileW failed with error: ", res);
      return false;
   }
}'''

content = content.replace(download_func_old, download_func_new)

check_func_old = '''           if(DownloadUpdate(downloadUrl))
           {
              string src = TerminalInfoString(TERMINAL_DATA_PATH) + "\\\\MQL5\\\\Files\\\\NonfarmRich_v3_update.ex5";
              string dest = TerminalInfoString(TERMINAL_DATA_PATH) + "\\\\MQL5\\\\Experts\\\\NonfarmRich_v" + remoteVersion + ".ex5";
              
              if(CopyFileW(src, dest, 0) != 0)
              {
                 Alert("🔥 NonfarmRich EA Update SUCCESS!\\n\\n",
                       "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n",
                       "Changes: ", changelog, "\\n\\n",
                       "✅ The new version has been auto-installed to your Experts folder!\\n",
                       "Please right-click in Navigator and click 'Refresh', then attach the new version to your chart.");
              }
              else
              {
                 Alert("Update Downloaded to Files folder!\\n\\n",
                       "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n\\n",
                       "Auto-copy to Experts failed. Please manually move it from:\\n",
                       "MQL5\\\\Files\\\\NonfarmRich_v3_update.ex5\\nto your Experts folder.");
              }
           }'''

check_func_new = '''           string dest = TerminalInfoString(TERMINAL_DATA_PATH) + "\\\\MQL5\\\\Experts\\\\NonfarmRich_v" + remoteVersion + ".ex5";
           if(DownloadUpdate(downloadUrl, dest))
           {
                 Alert("🔥 NonfarmRich EA Update SUCCESS!\\n\\n",
                       "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n",
                       "Changes: ", changelog, "\\n\\n",
                       "✅ The new version has been auto-installed to your Experts folder!\\n",
                       "Please right-click in Navigator and click 'Refresh', then attach the new version to your chart.");
           }
           else
           {
                 Alert("❌ Auto-Update Failed!\\n\\n",
                       "Could not download the file to the Experts folder.\\n",
                       "Please check your internet connection or anti-virus.");
           }'''

content = content.replace(check_func_old, check_func_new)

# Bump version to 4.3.0
content = content.replace('string EA_VERSION = "4.2.0";', 'string EA_VERSION = "4.3.0";')
content = content.replace('int    EA_BUILD   = 20261006;', 'int    EA_BUILD   = 20261007;')
content = content.replace('#define EA_VERSION       "4.1.0"', '#define EA_VERSION       "4.3.0"')
content = content.replace('#define EA_BUILD         20261005', '#define EA_BUILD         20261007')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed DownloadUpdate via urlmon.dll')
