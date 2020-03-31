# Powershell
This is my "prod" for Powershell scripts.

To install the modules:
1. Choose "Download Zip" at the top of this page.
2. Extract the zip.
3. Double click the "install-modules.bat" file inside the "Other" folder. 
This script will:
* Copy the folders from the zip to your Modules path
* Copy the import-module command to your clipboard that loads the modules.
* Pull up your Powershell profile and assume that you will paste in my clipboard command (save and close notepad).
* Launch Powershell.

At this point you may want to run `Get-Command -Mod gw*` to see what all imported.

You may be wondering, *"What is with all these 'gw' prefixes?"*
Well the reason I do this is because 'ActiveDirectory' is a pretty generic name for a module. Also, Mr. Powershell, Don Jones, and many others taught me early on to put prefixes in names and it just kinda stuck with me.

### DISCLAIMER 

Please do not use these scripts in a production environment without reading them over first. Please see the MIT [license](./LICENSE) for more information.