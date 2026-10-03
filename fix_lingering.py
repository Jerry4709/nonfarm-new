with open('NonfarmRich_v3.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

old_create = '''void CreateUI()
{
   int panelW = 420, panelH = 820;
   
   //--- Panel background'''

new_create = '''void CreateUI()
{
   // Force cleanup of any lingering objects from older EA versions
   DeleteUI();
   
   // Also specifically delete the stubborn Mode label just in case
   ObjectDelete(0, "NR_Mode");

   int panelW = 420, panelH = 820;
   
   //--- Panel background'''

content = content.replace(old_create, new_create)

# Bump to 4.6.0
content = content.replace('#define EA_VERSION       "4.5.0"', '#define EA_VERSION       "4.6.0"')
content = content.replace('#define EA_BUILD         20261009', '#define EA_BUILD         20261010')
content = content.replace('string EA_VERSION = "4.5.0";', 'string EA_VERSION = "4.6.0";')
content = content.replace('int    EA_BUILD   = 20261009;', 'int    EA_BUILD   = 20261010;')

with open('NonfarmRich_v3.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
print("Added forced cleanup!")
