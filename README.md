# Powershell Repo
This is my "prod" for Powershell scripts.

To install the modules, download my modules, extract it, and run the "install-modules.bat" file. This script will:
* Copy the folders from your downloads to your Modules path
* Copy the import-module command to your clipboard
* Pull up your Powershell profile and assume that you will paste in my modules (save and close notepad).
* Launch Powershell.

At this point you may want to run `Get-Command -Mod gw*` to see what all imported.

You may be wondering, *"What is with all these 'gw' prefixes?"*
Well the reason I do this is because 'ActiveDirectory' is a pretty generic name for a module. Also, Mr. Powershell, Don Jones, and many others taught me early on to put prefixes in names and it just kinda stuck with me.

If you have any questions, comments, or concerns please send me a message and thanks for stopping by.
