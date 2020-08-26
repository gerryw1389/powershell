<#######<Script>#######>
<#######<Header>#######>
# Name: Set-VPN
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function New-Runspace
{
     <#
.Synopsis
This script serves as a template to run jobs asynchronously.
.Description
This script serves as a template to run jobs asynchronously.
.Parameter Threads
Specifies the number of threads. Default is 100.
.Example
New-Runspace
Creates a runspace so that the script can run jobs asynchronously.
.Notes
2017-09-08: v1.0 Initial script 
#>

   [Cmdletbinding()]
    Param(

        [Parameter(Position = 0)]
        [Int32]$Threads = 100
    )

    Begin
    {
    
    } 

    Process
    {       
        ### Scriptblock (This Code Will Run Asynchron In The Runspacepool)
        [System.Management.Automation.Scriptblock]$Scriptblock = {
            Param(
                ### Scriptblock Parameter
                $Parameter1,
                $Parameter2
            )
            #######################################
            ## Enter
            ## Code
            ## Here,
            ## Which
            ## Should
            ## Run
            ## Asynchron
            #######################################
		
            ### Built Custom Psobject And Return It
            [Pscustomobject] @{
                Parameter1 = Result1
                Parameter2 = Result2
            }		
        }

        # Create Runspacepool And Jobs	
        Write-Verbose "Setting Up Runspacepool..." 
        Write-Verbose "Running With Max $Threads Threads"
   
        $Runspacepool = [System.Management.Automation.Runspaces.Runspacefactory]::Createrunspacepool(1, $Threads, $Host)
        $Runspacepool.Open()
        [System.Collections.Arraylist]$Jobs = @()

        Write-Verbose "Setting Up Jobs..."
        
        # Setting Up Jobs
        For ($I = $Startrange; $I -Le $Endrange; $I++)
        {
            # Hashtable To Pass Parameters
            $Scriptparams = @{
                Parameter1 = $Parameter1
                Parameter2 = $Parameter2
            }

            # Catch When Trying To Divide Through Zero
            Try
            {
                $Progress_Percent = ($I / ($Endrange - $Startrange)) * 100 # Calulate Some Percent 
            } 
            Catch
            { 
                $Progress_Percent = 100 
            }

            Write-Progress -Activity "Setting Up Jobs..." -Id 1 -Status "Current Job: $I"  -Percentcomplete ($Progress_Percent)
        
            # Create New Job
            $Job = [System.Management.Automation.Powershell]::Create().Addscript($Scriptblock).Addparameters($Scriptparams)
            $Job.Runspacepool = $Runspacepool
        
            $Jobobj = [Pscustomobject] @{
                Runnum = $I - $Startrange
                Pipe   = $Job
                Result = $Job.Begininvoke()
            }

            # Add Job To Collection
            [Void]$Jobs.Add($Jobobj)
        }

        Write-Verbose "Waiting For Jobs To Complete & Starting To Process Results..."

        # Total Jobs To Calculate Percent Complete, Because Jobs Are Removed After They Are Processed
        $Jobs_Total = $Jobs.Count

        # Process Results, While Waiting For Other Jobs
        Do
        {
            # Get All Jobs, Which Are Completed
            $Jobs_Toprocess = $Jobs | Where-Object {$_.Result.Iscompleted}

            # If No Jobs Finished Yet, Wait 500 Ms And Try Again
            If ($Jobs_Toprocess -Eq $Null)
            {
                Write-Verbose "No Jobs Completed, Wait 500ms..."

                Start-Sleep -Milliseconds 500
                Continue
            }
        
            # Get Jobs, Which Are Not Complete Yet
            $Jobs_Remaining = ($Jobs | Where-Object {$_.Result.Iscompleted -Eq $False}).Count

            # Catch When Trying To Divide Through Zero
            Try
            {            
                $Progress_Percent = 100 - (($Jobs_Remaining / $Jobs_Total) * 100) 
            }
            Catch
            {
                $Progress_Percent = 100
            }

            Write-Progress -Activity "Waiting For Jobs To Complete... ($($Threads - $($Runspacepool.Getavailablerunspaces())) Of $Threads Threads Running)" `
                -Id 1 -Percentcomplete $Progress_Percent -Status "$Jobs_Remaining Remaining..."
    
            Write-Verbose "Processing $(If($Jobs_Toprocess.Count -Eq $Null){"1"}Else{$Jobs_Toprocess.Count}) Job(S)..."


            Foreach ($Job In $Jobs_Toprocess)
            {       
                $Job_Result = $Job.Pipe.Endinvoke($Job.Result)
                $Job.Pipe.Dispose()

                $Jobs.Remove($Job)
        
                If ($Job_Result -Ne $Null)
                {       
                    $Job_Result    
                }
            } 

        } 
        While ($Jobs.Count -Gt 0)
    
        Write-Verbose "Closing Runspacepool And Free Resources..."
        $Runspacepool.Close()
        $Runspacepool.Dispose()
    }

    End
    {

    }
}

# New-Runspace

<#######</Body>#######>
<#######</Script>#######>