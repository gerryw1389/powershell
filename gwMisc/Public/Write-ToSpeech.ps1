<#######<Script>#######>
<#######<Header>#######>
# Name: Write-ToSpeech
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Write-ToSpeech
{
    <#
.Synopsis
Converts text to speech.
.Description
Converts text to speech.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Write-ToSpeech "Hello World"
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]$Text,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Write-ToSpeech.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log
    }
    
    Process
    {   
        Try
        {
            $Speaker = New-Object -ComObject Sapi.SpVoice
            $null = $Speaker.Speak($Text)
            Log "Converted to speech: $Text"

        }
        Catch
        {
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
    }

    End
    {
        Stop-Log  
    }

    <#
    .Note
    This is how you have remote speech on a remote computer. Taken from: https://stackoverflow.com/questions/255419/how-can-i-mute-unmute-my-sound-from-powershell
    NOTE: This takes a while to run and it spits errors at the end, but IT DOES WORK!!
.Code

Enter-PSSession -ComputerName AHoleUser -Credential (Get-Credential)
@'
Add-Type -Language CsharpVersion3 -TypeDefinition @'
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  // f(), g(), ... are unused COM method slots. Define these if you care
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
  int j();
  int GetMasterVolumeLevelScalar(out float pfLevel);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
  int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
  int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
  int f(); // Unused
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class Audio {
  static IAudioEndpointVolume Vol() {
    var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
    IMMDevice dev = null;
    Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
    IAudioEndpointVolume epv = null;
    var epvid = typeof(IAudioEndpointVolume).GUID;
    Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
    return epv;
  }
  public static float Volume {
    get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
    set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
  }
  public static bool Mute {
    get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
    set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
  }
}
'@
[Audio]::Mute = $false
[Audio]::Volume = 1
Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.Speak('Hey everyone Im looking at porn over here, come check me out! This is why Im not productive')
#>

}


<#######</Body>#######>
<#######</Script>#######>