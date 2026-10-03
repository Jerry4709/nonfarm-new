import re

with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_block = r'''         if\(DownloadUpdate\(downloadUrl\)\)
         \{
            string src = TerminalInfoString\(TERMINAL_DATA_PATH\) \+ "\\\\MQL5\\\\Files\\\\NonfarmRich_v3_update\.ex5";
            string dest = TerminalInfoString\(TERMINAL_DATA_PATH\) \+ "\\\\MQL5\\\\Experts\\\\NonfarmRich_v" \+ remoteVersion \+ "\.ex5";
            
            if\(CopyFileW\(src, dest, 0\) != 0\)
            \{
               Alert\("🔥 NonfarmRich EA Update SUCCESS!\\n\\n",
                     "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n",
                     "Changes: ", changelog, "\\n\\n",
                     "✅ The new version has been auto-installed to your Experts folder!\\n",
                     "Please right-click in Navigator and click 'Refresh', then attach the new version to your chart\."\);
            \}
            else
            \{
               Alert\("Update Downloaded to Files folder!\\n\\n",
                     "Current: v", EA_VERSION, " -> New: v", remoteVersion, "\\n\\n",
                     "Auto-copy to Experts failed\. Please manually move it from:\\n",
                     "MQL5\\\\Files\\\\NonfarmRich_v3_update\.ex5\\nto your Experts folder\."\);
            \}
         \}'''

new_block = '''         string dest = TerminalInfoString(TERMINAL_DATA_PATH) + "\\\\MQL5\\\\Experts\\\\NonfarmRich_v" + remoteVersion + ".ex5";
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

content = re.sub(old_block, new_block, content, flags=re.MULTILINE)

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed check block.')
