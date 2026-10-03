with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

import_str = '''#import "wininet.dll"
long InternetOpenW(string agent, int accessType, string proxyName, string proxyBypass, uint flags);
long InternetOpenUrlW(long internetSession, string url, string headers, int headersLength, uint flags, long context);
int  InternetReadFile(long file, uchar &buffer[], int numBytesToRead, int &numberOfBytesRead);
int  InternetCloseHandle(long inet);
#import

#import "kernel32.dll"
int CopyFileW(string lpExistingFileName, string lpNewFileName, int bFailIfExists);
#import'''
content = content.replace('#import "wininet.dll"\nlong InternetOpenW(string agent, int accessType, string proxyName, string proxyBypass, uint flags);\nlong InternetOpenUrlW(long internetSession, string url, string headers, int headersLength, uint flags, long context);\nint  InternetReadFile(long file, uchar &buffer[], int numBytesToRead, int &numberOfBytesRead);\nint  InternetCloseHandle(long inet);\n#import', import_str)

download_old = '''         if(DownloadUpdate(downloadUrl))
         {
            Alert("NonfarmRich EA Update Downloaded!\\n\\n",
                  "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n",
                  "Changes: ", changelog, "\\n\\n",
                  "File saved to: MQL5\\\\Files\\\\NonfarmRich_v3_update.ex5\\n",
                  "Copy to MQL5\\\\Experts\\\\ and recompile to apply.");
         }'''

download_new = '''         if(DownloadUpdate(downloadUrl))
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
content = content.replace(download_old, download_new)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated update deployment script.')
