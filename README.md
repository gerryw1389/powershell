
# Powershell
This repo contains multiple modules for Powershell scripts I have written over time. Many of these may be out of date and need to be read over and improved so please do not use in production. Also, many of the functions have articles that go with them from my blog at [https://automationadmin.com](https://automationadmin.com).

### To install some of the modules:

1. Choose "Download Zip" at the top of this page.

2. Extract the zip.

3. Copy the module to your user Powershell Modules folder at `C:\Users\yourUserName\Documents\WindowsPowerShell\Modules`

4. Open powershell and type `import-module modulename`. If you copied more than one, do this for each one.

5. At this point you may want to run `Get-Command -Mod gw*` to see what all imported.

6. If you want these to be imported automatically, type `notepad $profile` and then paste in the same commands (`import-module modulename` one for each module). Save and close.

### To install all the modules:

1. Choose "Download Zip" at the top of this page.

2. Extract the zip.

3. Double click the "install-modules.bat" file inside the "Other" folder. 

   - This script will:
   - Copy the folders from the zip to your Modules path
   - Copy the import-module command to your clipboard that loads the modules.
   - Pull up your Powershell profile and assume that you will paste in my clipboard command (save and close notepad).
   - Launch Powershell.

4. At this point you may want to run `Get-Command -Mod gw*` to see what all imported.

   - You may be wondering, *"What is with all these 'gw' prefixes?"* Well the reason I do this is because 'ActiveDirectory' is a pretty generic name for a module. Also, Mr. Powershell, Don Jones, and many others taught me early on to put prefixes in names and it just kinda stuck with me.

### Why the long `Begin{}` Block? / Why is 80% of your functions for logging?

1. You will notice that I went through the trouble of putting each of these functions into a module only to have duplicate code in each script. I know this and at one point had the logging functions in the `private` folder called `helpers.psm1` located [here](https://github.com/gerryw1389/powershell/blob/master/Other/templates/old-helpers-w-logging.psm1). I would then import that function to my public functions and have a much cleaner begin block as seen [here](https://github.com/gerryw1389/powershell/blob/master/Other/templates/old-template-w-logging-module-req.ps1)

2. The problem was that other admins I worked with preferred single `.ps1` scripts since it's much easier to copy a single file than a zip/extract/import-module setup. I plan to bring this back in the future with some kind of Nuget repo with a CI/CD pipeline release per [this reddit post](https://www.reddit.com/r/PowerShell/comments/gl28tc/building_a_pipeline_for_scripts/) but I have lots to learn first!

3. In addition, I have been through many changes in logging itself like trying to make it [optional](https://github.com/gerryw1389/powershell/blob/master/Other/templates/old-template-w-logging-optional.ps1) or writing to the [Windows Event Log](https://github.com/gerryw1389/powershell/blob/master/Other/templates/old-helpers-w-eventlog.psm1). Eventually I just stuck with the `create PSLogs folder in same directory with yyyy-MM-dd-function-name.log`.


### DISCLAIMER 

Please do not use these scripts in a production environment without reading them over first. Please see the MIT [license](./LICENSE) for more information.