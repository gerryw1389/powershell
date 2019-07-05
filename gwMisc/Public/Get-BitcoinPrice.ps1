<#######<Script>#######>
<#######<Header>#######>
# Name: Get-BitcoinPrice
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Get-BitcoinPrice
{
    <#
.Synopsis
Gets the current price of Bitcoin using CoinMarketCap API.
.Description
Gets the current price of Bitcoin using CoinMarketCap API.
.Example
Get-BitcoinPrice
Returns an object with various information about current bitcoin prices.
.Example
Get-BitcoinPrice -Price
Returns just the current price of bitcoin.
.Notes
All credit goes to: https://www.powershellgallery.com/packages/CoinMarketCap/1.0.1
This is just a wrapper function
#>

    [CmdletBinding()]
    PARAM(
        [Switch]$Price
    )
    Begin 
    {
        function Get-Coin
        {
            <#
.SYNOPSIS
    Retrieve one or multiple Cryprocurrencies information 
.DESCRIPTION
    Retrieve one or multiple Cryprocurrencies information 
.PARAMETER CoinID
    Specify the Cryptocurrency you want to retrieve
.PARAMETER Convert
    Show the value in a fiat currency
.PARAMETER Online
    Show the CoinMarketCap to the coin specified
.EXAMPLE
    Get-Coin
.EXAMPLE
    Get-Coin -id bitcoin

    Retrieve the current Bitcoin information
.EXAMPLE
    Get-Coin -convert EUR

    Retrieve all cryptocurrencies with EURO conversion.
.EXAMPLE
    Get-Coin -id btc

    Retrieve the current Bitcoin information
.EXAMPLE
    Get-Coin -id btc -convert eur

    Retrieve the current Bitcoin information with EURO conversion.
.EXAMPLE
    Coin btc

    Retrieve the current Bitcoin information
.EXAMPLE
    Coin btc -online

    Shows the CoinMarketCap page for Bitcoin
.NOTES
    https://github.com/lazywinadmin/CoinMarketCap
#>
            [CmdletBinding()]
            PARAM(
                [Parameter()]
                $CoinId,
                [Parameter()]
                [ValidateSet("AUD", "BRL", "CAD", "CHF", "CLP", "CNY",
                    "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "IDR", "ILS",
                    "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP",
                    "PKR", "PLN", "RUB", "SEK", "SGD", "THB", "TRY", "TWD",
                    "ZAR")]
                $Convert,
                [switch]$Online
            )

            TRY
            {
                [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
                
                $FunctionName = $MyInvocation.MyCommand

                Write-Verbose -Message "[$FunctionName] Build Splatting"
                $Splat = @{
                    Uri = 'https://api.coinmarketcap.com/v1/ticker'
                }

                if ($CoinID)
                {
                    if ($Convert)
                    {
                        Write-Verbose -Message "[$FunctionName] Coin '$CoinID' with Currency '$Convert'"
                        $Splat.Uri = "https://api.coinmarketcap.com/v1/ticker/$CoinID/?convert=$Convert"
                        Write-Verbose -Message "[$FunctionName] Uri '$($Splat.Uri)'"
                    }
                    else
                    {
                        Write-Verbose -Message "[$FunctionName] Coin '$CoinID'"
                        $Splat.Uri = "https://api.coinmarketcap.com/v1/ticker/$CoinID/"
                        Write-Verbose -Message "[$FunctionName] Uri '$($Splat.Uri)'"
                    }
                }
                elseif ($Convert -and -not $CoinID)
                {
                    Write-Verbose -Message "[$FunctionName] Currency '$Convert'"
                    $Splat.Uri = "https://api.coinmarketcap.com/v1/ticker/?convert=$Convert"
                    Write-Verbose -Message "[$FunctionName] Uri '$($Splat.Uri)'"
                }

                try
                {
                    Write-Verbose -Message "[$FunctionName] Querying API..."
                    $Out = [pscustomobject](invoke-restmethod @splat -ErrorAction Stop -ErrorVariable Result)
    
                    if ($Online)
                    {
                        Write-Verbose -Message "[$FunctionName] Opening page"
                        start-process -filepath "https://coinmarketcap.com/currencies/$CoinId/"
                    }
                    else
                    {
                        Write-Verbose -Message "[$FunctionName] Show Output"
                        Write-Output $Out 
                    }
                }
                catch
                {
                    if ($_ -match 'id not found')
                    {
                        Write-Verbose -Message "[$FunctionName] did not find the CoinID '$CoinId', looking up for Symbol '$CoinId'..."
                        if ($Convert)
                        {
                            if ($Online)
                            {
                                $Coins = Get-Coin -Convert $Convert | Where-Object { $_.Symbol -eq $CoinId }
                                start-process -filepath "https://coinmarketcap.com/currencies/$($Coins.id)/"
                            }
                            else
                            {
                                Get-Coin -Convert $Convert | Where-Object { $_.Symbol -eq $CoinId }
                            }
                        }
                        else
                        {
                            if ($Online)
                            {
                                $Coins = Get-Coin | Where-Object { $_.Symbol -eq $CoinId }
                                start-process -filepath "https://coinmarketcap.com/currencies/$($Coins.id)/"
                            }
                            else
                            {
                                Get-Coin | Where-Object { $_.Symbol -eq $CoinId }
                            }
                        }
                    }
                    else { throw $_ }
                }
        
            }
            CATCH
            {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
    Process
    {
        
        If ($Price)
        {
            $a = (Get-Coin -CoinId Bitcoin).price_usd
            $b = [math]::Round($a)
            Write-Output "`$$b"
        }
        Else
        {
            Get-Coin -CoinId Bitcoin

        }
    }
    End
    {

    }
}

<#######</Body>#######>
<#######</Script>#######>