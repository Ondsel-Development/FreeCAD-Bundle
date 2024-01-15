import json
import os
import platform
import sys
import freecad
import FreeCAD as App
import AddonManager
from addonmanager_installer import AddonInstaller

conda_env=os.path.join(os.getcwd(),sys.argv[1])
if platform.system() != 'Windows':
    modspath = os.path.join(conda_env,'Mod')
    prefpackspath = os.path.join(conda_env,'share','Gui','PreferencePacks')
else:
    modspath = os.path.join(conda_env,'Library','Mod')
    prefpackspath = os.path.join(conda_env,'Library','data','Gui','PreferencePacks')

# params = App.ParamGet("User parameter:BaseApp/Preferences/Addons")
# params.SetBool('disableGit', True)

def install_mod(name,url,installation_path = modspath):
    installer = AddonInstaller(AddonManager.Addon(name,url))
    installer.installation_path = installation_path
    installer.run()

install_mod('Ondsel-FirstRun','https://github.com/Ondsel-Development/Ondsel-FirstRun')

mods_json = os.path.join(modspath,'Ondsel-FirstRun','mods.json')
with open(mods_json, "r") as fp:
    mods = json.load(fp)

for mod in mods["addons"]:
    install_mod(name=mod["name"],url=mod["url"])

for mod in mods["preferencePacks"]:
    install_mod(name=mod["name"],url=mod["url"],installation_path=prefpackspath)
