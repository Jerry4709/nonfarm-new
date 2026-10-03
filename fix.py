with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
in_check_block = False
for line in lines:
    if 'string dest = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Experts\\NonfarmRich_v" + remoteVersion + ".ex5";' in line:
        in_check_block = True
    if '         if(DownloadUpdate(downloadUrl, dest))' in line and not in_check_block:
        in_check_block = True
        
    if in_check_block:
        if '         }' in line and 'Please check your internet connection or anti-virus.' in out[-1] if out else False:
            in_check_block = False
            continue
        # wait, it's easier to just git checkout the file, and do it safely using replace with raw strings
