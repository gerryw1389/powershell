<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileAssociations
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileAssociations
{
    <#
    .Synopsis
    Sets file associations in Windows using the assoc and ftype commands.
    .Description
    Sets file associations in Windows using the assoc and ftype commands.
    .Parameter Fileextensions
    Mandatory. This string or set of strings defines the file extensions you want to associate with a program.
    .Parameter OpenAppPath
    Mandatory. This string defines the path to a program.
    
    .Example
    Set-FileAssociations -Fileextensions .Png, .Jpeg, .Jpg -Openapppath "C:\Program Files\Imageglass\Imageglass.Exe"
    Sets file associations in Windows using the assoc and ftype commands.
    In this case, the extensions ".png, .jpeg, and .jpg" are associated with a program called ImageGlass.
    

#>   
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Fileextensions,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Openapppath,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-FileAssociations.Log"
    )

    Begin
    {
        
    
    }
    
    Process
    {   
        If (-Not (Test-Path $Openapppath))
        {
            Write-Output "$Openapppath Does Not Exist."
        }   
    
        Foreach ($Extension In $Fileextensions)
        {
            $Filetype = (cmd /c "Assoc $Extension")
            $Filetype = $Filetype.Split("=")[-1] 
            cmd /c "ftype $Filetype=""$Openapppath"" ""%1"""
            Write-Output "$Fileextensions set for $Filetype"
        }   
    }

    End
    {
        
    }
}

<#######</Body>#######>
<#######</Script>#######>