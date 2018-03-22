Set-StrictMode -Version Latest

# Only prepend format data once - unloading a module doesn't undo the effects of prepending format data
if (!$Pscx:Session['FileSystem_PrependedFormatData'])
{
    $ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
    Write-Verbose "PSCX prepending format data $ScriptDir\Pscx.FileSystem.Format.ps1xml."
	if ($PSVersionTable.PSVersion.Major -le 4) {
		Update-FormatData -PrependPath "$ScriptDir\Pscx.FileSystem.Format.ps1xml"
	}
	else {
		Update-FormatData -PrependPath "$ScriptDir\Pscx.FileSystem.Format.5.0.ps1xml"
	}
    $Pscx:Session['FileSystem_PrependedFormatData'] = $true
}

<#
.SYNOPSIS
    Calculates the sizes of the specified directory and adds that size
    as a "Length" NoteProperty to the input DirectoryInfo object.
.DESCRIPTION
    Calculates the sizes of the specified directory and adds that size
    as a "Length" NoteProperty to the input DirectoryInfo object.  NOTE: Computing the
    size of a directory can noticeably impact performance. 
.PARAMETER InputObject
    The directory object (System.IO.DirectoryInfo) on which to add the Length property
.EXAMPLE
    C:\PS> Get-ChildItem . -Recurse | Add-DirectoryLength | Sort Length
    This example shows how you can compute the directory size for each directory passed via the pipeline
    and add that info to each DirectoryInfo object.
#>
function Add-DirectoryLength
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowNull()]
        [PSObject]
        $InputObject
    )

    Begin 
    {
        function ProcessFile([string]$path) {
            (get-item -LiteralPath $path -Force).Length
        }
        
        function ProcessDirectory([string]$path) {
            $dirSize = 0
            $items = get-childitem -LiteralPath $path -Force -ea $ErrorActionPreference | sort @{e={$_.PSIsContainer}}
            if ($items -eq $null) {
                return $null
            }
            foreach ($item in $items) {
                if ($item.PSIsContainer) {
                    $dirSize += ProcessDirectory($item.FullName)
                }
                else {
                    $dirSize += ProcessFile($item.FullName)
                }
            }
            $dirSize
        }
    }

    Process {
        if ($InputObject -is [System.IO.DirectoryInfo]) {
            $dirSize = ProcessDirectory($InputObject.FullName)
            Add-Member NoteProperty Length $dirSize -InputObject $InputObject
        }
        $InputObject
    }
}

<#
.SYNOPSIS
    Adds the file or directory's short path as a "ShortPath" NoteProperty to each input object. 
.DESCRIPTION
    Adds the file or directory's short path as a "ShortPath" NoteProperty to each input object.
    NOTE: This filter requires the PSCX cmdlet Get-ShortPath
.PARAMETER InputObject
    A DirectoryInfo or FileInfo object on which to add the ShortPath property
.EXAMPLE
    C:\PS> Get-ChildItem | Add-ShortPath | Format-Table ShortPath,FullName
    This example shows how you can add the short path to each DirectoryInfo or FileInfo object in the pipeline.
#>
function Add-ShortPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowNull()]
        [PSObject]
        $InputObject
    )

    Process {
        if ($InputObject -is [System.IO.FileSystemInfo]) {
            $shortPathInfo = Get-ShortPath -LiteralPath $_.Fullname 
            Add-Member NoteProperty ShortPath $shortPathInfo.ShortPath -InputObject $InputObject
        }
        $InputObject
    }
}

Export-ModuleMember -Alias * -Function *
# SIG # Begin signature block
# MIIfUwYJKoZIhvcNAQcCoIIfRDCCH0ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFpSUu8/IQjHoqK0BOMPaXJNZ
# vIKgghqFMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkqhkiG9w0B
# AQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVk
# IElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBHMQswCQYD
# VQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRp
# bWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ
# 2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2ULf1ErNz
# lgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkC
# YYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/sjAw2W3rB
# erh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM
# 0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8GA1UdIASC
# AbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkA
# IAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUA
# IABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAA
# bwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEA
# bgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIA
# ZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkA
# bABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUA
# ZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglg
# hkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0wHQYDVR0O
# BBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMDig
# NqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# QS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcNAQEFBQAD
# ggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xaFjkAneNs
# hORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuX
# x/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2
# FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPlVRbwuwqr
# HNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitrwlHCCkiv
# sNRu4PQUCjob4489yq9qjXvc2EQwggabMIIFg6ADAgECAhAK3lreshTkdg4UkQS9
# ucecMA0GCSqGSIb3DQEBBQUAMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURp
# Z2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwHhcNMTMwOTEwMDAw
# MDAwWhcNMTYwOTE0MTIwMDAwWjBnMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ08x
# FTATBgNVBAcTDEZvcnQgQ29sbGluczEZMBcGA1UEChMQNkw2IFNvZnR3YXJlIExM
# QzEZMBcGA1UEAxMQNkw2IFNvZnR3YXJlIExMQzCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAI/YYNDd/Aw4AcjlGyyL+qjbxgXi1x6uw7Qmsjst/Z1yx0ES
# BQb29HmGeka3achcbRPgmBTt3Jn6427FDhvKOXhk7dPJ2mFxfv3NACa+Knvq/sz9
# xClrULvhpyOba8lOgXm5A9zWWBmUgYISVYz0jiS+/jl8x3yEEzplkTYrDsaiFiA0
# 9HSpKCqvdnhBjIL6MGJeS13rFXjlY5KlfwPJAV5txn4WM8/6cjGRDa550Cg7dygd
# SyDv7oDH7+AFqKakiE6Z+4yuBGhWQEBFnL9MZvlp3hkGK6Wlqy0Dfg3qkgqggcGx
# MS+CpdbfXF+pdCbSpuYu4FrCuDb+ae1TbyTiTBECAwEAAaOCAzkwggM1MB8GA1Ud
# IwQYMBaAFHtozimqwBe+SXrh5T/Wp/dFjzUyMB0GA1UdDgQWBBTpFzY/nfuGUb9f
# L83BlRNclRNsizAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# cwYDVR0fBGwwajAzoDGgL4YtaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL2Fzc3Vy
# ZWQtY3MtMjAxMWEuY3JsMDOgMaAvhi1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
# YXNzdXJlZC1jcy0yMDExYS5jcmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG
# /WwDATCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3Nz
# bC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5
# ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABl
# ACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAg
# AG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABh
# AG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwBy
# AGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBp
# AGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABl
# AGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYIG
# CCsGAQUFBwEBBHYwdDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEwGCCsGAQUFBzAChkBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURDb2RlU2lnbmluZ0NBLTEuY3J0MAwGA1UdEwEB/wQCMAAw
# DQYJKoZIhvcNAQEFBQADggEBAANu3/2PhW9plSTLJBR7SZBv4XqKxMzAJOw9GzNB
# uj4ihsyn/cRt1HV/ey7J9vM2mKZ5dZhU6rpb/cRnnKzEHDSSYnaogUDWbnBAw43P
# 6q6T9xKktrCpWhZRqbCRquix/VZN4dphqkdwpS//b/YnKnHi2da3MB1GqzQw6PQd
# mCWGHm+/CZWWI6GWZxdnRrDSkpMbkPYwdupQMVFFqQWWl/vJddLSM6bim0GD/XlU
# sz8hvYdOnOUT9g8+I3SegouqnrAOqu9Yj046iM29/6tkwyOCOKKeVl+uulpXnJRi
# nRkpczbl0OMMmIakVF1OTG/A/g2PPd6Xp4NDAWIKnsCdh64wggajMIIFi6ADAgEC
# AhAPqEkGFdcAoL4hdv3F7G29MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMTAy
# MTExMjAwMDBaFw0yNjAyMTAxMjAwMDBaMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNV
# BAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCcfPmgjwrKiUtTmjzsGSJ/DMv3SETQ
# PyJumk/6zt/G0ySR/6hSk+dy+PFGhpTFqxf0eH/Ler6QJhx8Uy/lg+e7agUozKAX
# EUsYIPO3vfLcy7iGQEUfT/k5mNM7629ppFwBLrFm6aa43Abero1i/kQngqkDw/7m
# JguTSXHlOG1O/oBcZ3e11W9mZJRru4hJaNjR9H4hwebFHsnglrgJlflLnq7MMb1q
# WkKnxAVHfWAr2aFdvftWk+8b/HL53z4y/d0qLDJG2l5jvNC4y0wQNfxQX6xDRHz+
# hERQtIwqPXQM9HqLckvgVrUTtmPpP05JI+cGFvAlqwH4KEHmx9RkO12rAgMBAAGj
# ggNDMIIDPzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHD
# BgNVHSAEggG6MIIBtjCCAbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUF
# BwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMG
# CCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2
# hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMB0GA1UdDgQWBBR7aM4pqsAXvkl64eU/1qf3RY81MjAfBgNVHSMEGDAW
# gBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAe3IdZP+I
# yDrBt+nnqcSHu9uUkteQWTP6K4feqFuAJT8Tj5uDG3xDxOaM3zk+wxXssNo7ISV7
# JMFyXbhHkYETRvqcP2pRON60Jcvwq9/FKAFUeRBGJNE4DyahYZBNur0o5j/xxKqb
# 9to1U0/J8j3TbNwj7aqgTWcJ8zqAPTz7NkyQ53ak3fI6v1Y1L6JMZejg1NrRx8iR
# ai0jTzc7GZQY1NWcEDzVsRwZ/4/Ia5ue+K6cmZZ40c2cURVbQiZyWo0KSiOSQOiG
# 3iLCkzrUm2im3yl/Brk8Dr2fxIacgkdCcTKGCZlyCXlLnXFp9UH/fzl3ZPGEjb6L
# HrJ9aKOlkLEM/zCCBs0wggW1oAMCAQICEAb9+QOWA63qAArrPye7uhswDQYJKoZI
# hvcNAQEFBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNz
# dXJlZCBJRCBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTIxMTExMDAwMDAwMFow
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBD
# QS0xMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBz
# QHDSnlZUXKnE0kEGj8kz/E1FkVyBn+0snPgWWd+etSQVwpi5tHdJ3InECtqvy15r
# 7a2wcTHrzzpADEZNk+yLejYIA6sMNP4YSYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD
# /6b3+6LNb3Mj/qxWBZDwMiEWicZwiPkFl32jx0PdAug7Pe2xQaPtP77blUjE7h6z
# 8rwMK5nQxl0SQoHhg26Ccz8mSxSQrllmCsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2
# zkBdXPao8S+v7Iki8msYZbHBc63X8djPHgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9
# BwSiCQIDAQABo4IDejCCA3YwDgYDVR0PAQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsG
# AQUFBwMBBggrBgEFBQcDAgYIKwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDCDCC
# AdIGA1UdIASCAckwggHFMIIBtAYKYIZIAYb9bAABBDCCAaQwOgYIKwYBBQUHAgEW
# Lmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5odG0w
# ggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgA
# aQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQA
# ZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcA
# aQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwA
# eQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkA
# YwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEA
# cgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIA
# eQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQI
# MAYBAf8CAQAweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgw
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwHQYDVR0OBBYEFBUAEisTmLKZB+0e36K+
# Vw0rZwLNMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3
# DQEBBQUAA4IBAQBGUD7Jtygkpzgdtlspr1LPUukxR6tWXHvVDQtBs+/sdR90OPKy
# XGGinJXDUOSCuSPRujqGcq04eKx1XRcXNHJHhZRW0eu7NoR3zCSl8wQZVann4+er
# Ys37iy2QwsDStZS9Xk+xBdIOPRqpFFumhjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+c
# dkvtX8JLFuRLcEwAiR78xXm8TBJX/l/hHrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeS
# DY2xaYxP+1ngIw/Sqq4AfO6cQg7PkdcntxbuD8O9fAqg7iwIVYUiuOsYGk38KiGt
# STGDR5V3cdyxG0tLHBCcdxTBnU8vWpUIKRAmMYIEODCCBDQCAQEwgYMwbzELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTEuMCwGA1UEAxMlRGlnaUNlcnQgQXNzdXJlZCBJRCBDb2RlIFNp
# Z25pbmcgQ0EtMQIQCt5a3rIU5HYOFJEEvbnHnDAJBgUrDgMCGgUAoHgwGAYKKwYB
# BAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAc
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUkbe3
# HGETkVRj2nSUerIC6F88EiMwDQYJKoZIhvcNAQEBBQAEggEAPpH1l6Yt1kphJCVS
# a+sWjEP11SSPBuB7zzUswuMoVReT+f+jhbaoNfSJxUPy0maDKJDkuphTzzuRi9D4
# xl71vVFCTVB6FITtoMF+SZYT/tVIgXMnxzjg446AzbunCOCwAQmYOS383xTMo+12
# Zbi81rCzfcVO3pLUt+anOLry0XSE5oGz6Tp++Wjz/cMykHWCSSRT9eIfKJcPqUOm
# Oz6vVBg250ydYEsoAG1/DvJv0KYDgTQn2xxl9JimujW6oZpb7UqP7ODu6YOdFK+8
# aVDnwwvbSLEpG9zkMYvRda/9nu+Ikh7JVxwRSyNnD8t3am/2QM1u4uwZseAoRgzW
# poY1HqGCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGaAjr/
# WLFr1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEH
# ATAcBgkqhkiG9w0BCQUxDxcNMTYwNjMwMDM1OTEzWjAjBgkqhkiG9w0BCQQxFgQU
# bl8rB0DHMgLrVVyDn6Y+c+kUG+4wDQYJKoZIhvcNAQEBBQAEggEAT1Bx5yib2EZ2
# gBZsHO3RFCDagSrzf0xbi0+Xfjbt5WrLux5N/Av3etK3Cd4DpQ7vgNBwCF6xnhyE
# 0VJt+GR4+K9xZ4NFTLjslqySXyarrcY46W7bDIQStnEVdsVHkZiAm8zQLZilKqbL
# TS51DnqmWKkhD9GPWOq8nzL9zvk/9zigguWcQvIlu4+az3yLwZle5/ZBtN+pZvFi
# l/UEjhw1uzkJfxSmQum1HWj5WuohU2TOqWbQLltG9n8ouZ87pntLQzMAn8/au0jr
# fRI49VQs+eQx/tEVWAdZ7YPXC49NVxSQPKvcb1veeyOSLmRQnyzyU0bZ0WUuj4/4
# 5L5QGsrODQ==
# SIG # End signature block
