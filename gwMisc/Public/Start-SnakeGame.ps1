<#######<Script>#######>
<#######<Header>#######>
# Name: Start-SnakeGame
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: https://www.reddit.com/r/PowerShell/comments/6wtlsc/i_wrote_a_snake_game_in_powershell_requires/
<#######</Header>#######>
<#######<Body>#######>

Using Assembly PresentationCore
Using Assembly PresentationFramework
Using Namespace System.Collections.Generic
Using Namespace System.ComponentModel
Using Namespace System.Linq
Using Namespace System.Reflection
Using Namespace System.Text
Using Namespace System.Windows
Using Namespace System.Windows.Input
Using Namespace System.Windows.Markup
Using Namespace System.Windows.Media
Using Namespace System.Windows.Threading

Function Start-SnakeGame
{
    <#
    .Synopsis
    Classic Snake game in Powershell!
    .Description
    Classic Snake game in Powershell!
    #>

    [Cmdletbinding()]
    
    Param
    (
    )
    
    Begin
    {
        ####################<Default Begin Block>####################
        # Force verbose because Write-Output doesn't look well in transcript files
        $VerbosePreference = "Continue"
        
        [String]$Logfile = $PSScriptRoot + '\PSLogs\' + (Get-Date -Format "yyyy-MM-dd") +
        "-" + $MyInvocation.MyCommand.Name + ".log"
        
        Function Write-Log
        {
            <#
            .Synopsis
            This writes objects to the logfile and to the screen with optional coloring.
            .Parameter InputObject
            This can be text or an object. The function will convert it to a string and verbose it out.
            Since the main function forces verbose output, everything passed here will be displayed on the screen and to the logfile.
            .Parameter Color
            Optional coloring of the input object.
            .Example
            Write-Log "hello" -Color "yellow"
            Will write the string "VERBOSE: YYYY-MM-DD HH: Hello" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Example
            Write-Log (cmd /c "ipconfig /all")
            Will write the string "VERBOSE: YYYY-MM-DD HH: ****ipconfig output***" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Notes
            2018-06-24: Initial script
            #>
            
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                # I usually set this to = "Green" since I use a black and green theme console
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color = "Green"
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
            If ($($Color.Length -gt 0))
            {
                $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = $Color
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
            }
            Else
            {
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
            }
            
        }

        Function Start-Log
        {
            <#
            .Synopsis
            Creates the log file and starts transcribing the session.
            .Notes
            2018-06-24: Initial script
            #>
            
            # Create transcript file if it doesn't exist
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
        
            # Clear it if it is over 10 MB
            [Double]$Sizemax = 10485760
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            If ($($Size.Sum -ge $SizeMax))
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            Else
            {
                Write-Verbose "Logfile was less than 10 MB"   
            }
            Start-Transcript -Path $Logfile -Append 
            Write-Log "####################<Function>####################"
            Write-Log "Function started on $env:COMPUTERNAME"

        }
        
        Function Stop-Log
        {
            <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
            Write-Log "Function completed on $env:COMPUTERNAME"
            Write-Log "####################</Function>####################"
            Stop-Transcript
       
            # Now we will clean up the transcript file as it contains filler info that needs to be removed...
            $Transcript = Get-Content $Logfile -raw

            # Create a tempfile
            $TempFile = $PSScriptRoot + "\PSLogs\temp.txt"
            New-Item -Path $TempFile -ItemType File | Out-Null
			
            # Get all the matches for PS Headers and dump to a file
            $Transcript | 
                Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
                Out-File -FilePath $TempFile -Append

            # Compare the two and put the differences in a third file
            $m1 = Get-Content -Path $Logfile
            $m2 = Get-Content -Path $TempFile
            $all = Compare-Object -ReferenceObject $m1 -DifferenceObject $m2 | Where-Object -Property Sideindicator -eq '<='
            $Array = [System.Collections.Generic.List[PSObject]]@()
            foreach ($a in $all)
            {
                [void]$Array.Add($($a.InputObject))
            }
            $Array = $Array -replace 'VERBOSE: ', ''

            Remove-Item -Path $Logfile -Force
            Remove-Item -Path $TempFile -Force
            # Finally, put the information we care about in the original file and discard the rest.
            $Array | Out-File $Logfile -Append -Encoding ASCII
            
        }
        
        Start-Log

        Function Set-Console
        {
            <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        This function sets background to black and foreground to green.
        Verbose is DarkCyan which is what I use often with logging in scripts.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
            Function Test-IsAdmin
            {
                <#
                .Synopsis
                Determines whether or not the user is a member of the local Administrators security group.
                .Outputs
                System.Bool
                #>

                [CmdletBinding()]
    
                $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $Principal = new-object System.Security.Principal.WindowsPrincipal(${Identity})
                $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
                Write-Output -InputObject $IsAdmin
            }

            $console = $host.UI.RawUI
            If (Test-IsAdmin)
            {
                $console.WindowTitle = "Administrator: Powershell"
            }
            Else
            {
                $console.WindowTitle = "Powershell"
            }
            $Background = "Black"
            $Foreground = "Green"
            $Messages = "DarkCyan"
            $Host.UI.RawUI.BackgroundColor = $Background
            $Host.UI.RawUI.ForegroundColor = $Foreground
            $Host.PrivateData.ErrorForegroundColor = $Messages
            $Host.PrivateData.ErrorBackgroundColor = $Background
            $Host.PrivateData.WarningForegroundColor = $Messages
            $Host.PrivateData.WarningBackgroundColor = $Background
            $Host.PrivateData.DebugForegroundColor = $Messages
            $Host.PrivateData.DebugBackgroundColor = $Background
            $Host.PrivateData.VerboseForegroundColor = $Messages
            $Host.PrivateData.VerboseBackgroundColor = $Background
            $Host.PrivateData.ProgressForegroundColor = $Messages
            $Host.PrivateData.ProgressBackgroundColor = $Background
            Clear-Host
        }
        Set-Console

        ####################</Default Begin Block>####################
   
    }
    
    Process
    {   
        Write-Output "Be aware that the game usually starts unfocused. Just press enter (after your first death) to start a new game. Enjoy!"
        Write-Output "All credits go to https://www.reddit.com/user/NuvolaGrande, I just wrote a wrapper function"
		
        Set-StrictMode -Version Latest

        [Int32] $boardWidth = 20
        [Int32] $boardHeight = 15
        [Int32] $fieldSizePixels = 30
        [Int32] $stepsMilliseconds = 75

        Class ViewModel : INotifyPropertyChanged
        {
            Hidden [PropertyChangedEventHandler] $PropertyChanged
            [Int32]      $BoardWidthPixels
            [Int32]      $BoardHeightPixels
            [Int32]      $FieldDisplaySizePixels
            [Int32]      $HalfFieldDisplaySizePixels
            [Int32]      $Score
            [Object]         $SnakeGeometry
            [Object]         $FoodCenter
            [Boolean]        $GameOverVisible
            [Boolean]        $WonVisible

            [Void] add_PropertyChanged([PropertyChangedEventHandler] $propertyChanged)
            {
                $this.PropertyChanged = [Delegate]::Combine($this.PropertyChanged, $propertyChanged)
            }

            [Void] remove_PropertyChanged([PropertyChangedEventHandler] $propertyChanged)
            {
                $this.PropertyChanged = [Delegate]::Remove($this.PropertyChanged, $propertyChanged)
            }

            Hidden [Void] NotifyPropertyChanged([String] $propertyName)
            {
                If ($this.PropertyChanged -cne $null)
                {
                    $this.PropertyChanged.Invoke($this, (New-Object PropertyChangedEventArgs $propertyName))
                }
            }

            [Void] SetScore([Int32] $score)
            {
                If ($this.Score -cne $score)
                {
                    $this.Score = $score
                    $this.NotifyPropertyChanged('Score');
                }
            }

            [Void] SetSnakeGeometry([Object] $snakeGeometry)
            {
                If ($this.SnakeGeometry -cne $snakeGeometry)
                {
                    $this.SnakeGeometry = $snakeGeometry
                    $this.NotifyPropertyChanged('SnakeGeometry')
                }
            }

            [Void] SetFoodCenter([Object] $foodCenter)
            {
                If ($this.FoodCenter -cne $foodCenter)
                {
                    $this.FoodCenter = $foodCenter
                    $this.NotifyPropertyChanged('FoodCenter')
                }
            }

            [Void] SetGameOverVisible([Boolean] $gameOverVisible)
            {
                If ($this.GameOverVisible -cne $gameOverVisible)
                {
                    $this.GameOverVisible = $gameOverVisible
                    $this.NotifyPropertyChanged('GameOverVisible')
                }
            }

            [Void] SetWonVisible([Boolean] $wonVisible)
            {
                If ($this.WonVisible -cne $wonVisible)
                {
                    $this.WonVisible = $wonVisible
                    $this.NotifyPropertyChanged('WonVisible')
                }
            }
        }

        Enum SnakeDirection
        {
            Left
            Right
            Up
            Down
        }

        Enum SnakeAction
        {
            Nothing
            Collision
            FoodEaten
        }

        Class SnakeSegment
        {
            [Int32]  $Length
            [SnakeDirection] $Direction

            SnakeSegment([Int32] $length, [SnakeDirection] $direction)
            {
                $this.Length = $length
                $this.Direction = $direction
            }

            [String] GetGeometryOperation([Int32] $fieldSizePixels)
            {
                [String] $directionChar = @('h', 'v')[$this.Direction -gt [SnakeDirection]::Right]
                [Int32] $directionFactor = $this.Direction % 2 * 2 - 1
                Return "$directionChar $($this.Length * $fieldSizePixels * $directionFactor)"
            }
        }

        Class Snake
        {
            Hidden [Int32]    $BoardWidth
            Hidden [Int32]    $BoardHeight
            Hidden [Int32]    $FieldSizePixels
            [Int32]   $HeadX
            [Int32]   $HeadY
            [Int32]   $TailX
            [Int32]   $TailY
            [List[SnakeSegment]]  $Segments
            [SnakeDirection]  $Direction

            Snake([Int32] $boardWidth, [Int32] $boardHeight, [Int32] $fieldSizePixels)
            {
                $this.BoardWidth = $boardWidth
                $this.BoardHeight = $boardHeight
                $this.FieldSizePixels = $fieldSizePixels
                $this.Reset()
            }

            [Void] Reset()
            {
                $this.TailX = $this.BoardWidth / 2 - 2
                $this.TailY = $this.BoardHeight / 2
                $this.HeadX = $this.TailX + 4
                $this.HeadY = $this.TailY
                $this.Segments = New-Object List[SnakeSegment]
                $this.Segments.Add((New-Object SnakeSegment 4, 'Right'))
                $this.Direction = 'Right'
            }

            [String] GetGeometryString()
            {
                [StringBuilder] $geometry = New-Object StringBuilder
                $geometry.Append("m $($this.TailX * $this.FieldSizePixels + $this.FieldSizePixels / 2) $($this.TailY * $this.FieldSizePixels + $this.FieldSizePixels / 2)")
                ForEach ($segment In $this.Segments)
                {
                    $geometry.Append($segment.GetGeometryOperation($this.FieldSizePixels))
                }
                Return $geometry.ToString()
            }

            [HashSet[Tuple[Int32, Int32]]] GetPoints()
            {
                [HashSet[Tuple[Int32, Int32]]] $points = New-Object 'HashSet[Tuple[Int32, Int32]]'
                [Int32] $x = $this.TailX
                [Int32] $y = $this.TailY
                $points.Add((New-Object 'Tuple[Int32, Int32]' $x, $y))
                ForEach ($segment In $this.Segments)
                {
                    1 .. $segment.Length `
                        | ForEach-Object {
                        Switch ($segment.Direction)
                        {
                            'Left'
                            {
                                $x-- 
                            }
                            'Right'
                            {
                                $x++ 
                            }
                            'Up'
                            {
                                $y-- 
                            }
                            'Down'
                            {
                                $y++ 
                            }
                        }
                        $points.Add((New-Object 'Tuple[Int32, Int32]' $x, $y))
                    }
                }
                return $points
            }

            [SnakeAction] Move([Food] $food)
            {
                [Int32] $currentHeadX = $this.HeadX
                [Int32] $currentHeadY = $this.HeadY
                # Move the head.
                Switch ($this.Direction)
                {
                    'Left'
                    {
                        $this.HeadX-- 
                    }
                    'Right'
                    {
                        $this.HeadX++ 
                    }
                    'Up'
                    {
                        $this.HeadY-- 
                    }
                    'Down'
                    {
                        $this.HeadY++ 
                    }
                }
                # Check OOB.
                If ($this.HeadX -lt 0 -or $this.HeadX -ge $this.BoardWidth -or $this.HeadY -lt 0 -or $this.HeadY -ge $this.BoardHeight)
                {
                    $this.HeadX = $currentHeadX
                    $this.HeadY = $currentHeadY
                    return [SnakeAction]::Collision
                }
                # Check collision.
                [HashSet[Tuple[Int32, Int32]]] $points = $this.GetPoints()
                If ($points.Contains((New-Object 'Tuple[Int32, Int32]' $this.HeadX, $this.HeadY)))
                {
                    $this.HeadX = $currentHeadX
                    $this.HeadY = $currentHeadY
                    return [SnakeAction]::Collision
                }
                # Check food.
                [SnakeAction] $result = @([SnakeAction]::Nothing, [SnakeAction]::FoodEaten)[
                $this.HeadX -ceq $food.FoodX -and $this.HeadY -ceq $food.FoodY
                ]
                # Handle head segment.
                [SnakeSegment] $headSegment = $this.Segments[-1]
                If ($headSegment.Direction -ceq $this.Direction)
                {
                    $headSegment.Length++
                }
                Else
                {
                    $this.Segments.Add((New-Object SnakeSegment 1, $this.Direction))
                }
                # Handle tail segment.
                If ($result -cne 'FoodEaten')
                {
                    [SnakeSegment] $tailSegment = $this.Segments[0]
                    $tailSegment.Length--
                    Switch ($tailSegment.Direction)
                    {
                        'Left'
                        {
                            $this.TailX-- 
                        }
                        'Right'
                        {
                            $this.TailX++ 
                        }
                        'Up'
                        {
                            $this.TailY-- 
                        }
                        'Down'
                        {
                            $this.TailY++ 
                        }
                    }
                    If ($tailSegment.Length -ceq 0)
                    {
                        $this.Segments.RemoveAt(0)
                    }
                }
                Return $result
            }
        }

        Class Food
        {
            Hidden [Int32]        $FieldSizePixels
            Hidden [Random]       $Random
            Hidden [HashSet[Tuple[Int32, Int32]]] $AllValidPoints
            [Int32]       $FoodX
            [Int32]       $FoodY

            Food([Int32] $boardWidth, [Int32] $boardHeight, [Int32] $fieldSizePixels)
            {
                $this.FieldSizePixels = $fieldSizePixels
                $this.Random = New-Object Random
                $this.AllValidPoints = New-Object 'HashSet[Tuple[Int32, Int32]]'
                For ([Int32] $x = 0; $x -lt $boardWidth; $x++)
                {
                    For ([Int32] $y = 0; $y -lt $boardHeight; $y++)
                    {
                        $this.AllValidPoints.Add((New-Object 'Tuple[Int32, Int32]' $x, $y))
                    }
                }
            }

            [Tuple[Int32, Int32]] GetGeometryLocation()
            {
                Return New-Object 'Tuple[Int32, Int32]' `
                ($this.FoodX * $this.FieldSizePixels + $this.FieldSizePixels / 2),
                ($this.FoodY * $this.FieldSizePixels + $this.FieldSizePixels / 2)
            }

            [Boolean] Move([Snake] $snake)
            {
                [HashSet[Tuple[Int32, Int32]]] $availablePoints = New-Object 'HashSet[Tuple[Int32, Int32]]' $this.AllValidPoints
                $availablePoints.ExceptWith($snake.GetPoints())
                If ($availablePoints.Count -ceq 0)
                {
                    Return $true
                }
                [Tuple[Int32, Int32]] $foodPoint = [Enumerable]::ElementAt($availablePoints, $this.Random.Next($availablePoints.Count))
                $this.FoodX = $foodPoint.Item1
                $this.FoodY = $foodPoint.Item2
                Return $false
            }
        }

        [Window] $mainWindow = [XamlReader]::Parse(@'
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="{Binding Score, StringFormat={}Snake - {0}}"
    SizeToContent="WidthAndHeight"
    ResizeMode="NoResize"
    >
    <Window.Resources>
    <BooleanToVisibilityConverter x:Key="VisibilityConverter" />
    </Window.Resources>
    <Grid Margin="5">
    <Grid.RowDefinitions>
    <RowDefinition Height="Auto" />
    <RowDefinition Height="*" />
    </Grid.RowDefinitions>
    <DockPanel Grid.Row="0" LastChildFill="True" Margin="0 0 0 5">
    <TextBlock DockPanel.Dock="Left"
       Text="{Binding Score, StringFormat={}Score: {0}}"
       Margin="0 0 5 0"
    />
    <TextBlock DockPanel.Dock="Left"
       Text="GAME OVER"
       FontWeight="Bold"
       Visibility="{Binding GameOverVisible, Converter={StaticResource VisibilityConverter}}"
    />
    <TextBlock DockPanel.Dock="Left"
       Text="YOU WON"
       FontWeight="Bold"
       Foreground="DarkGreen"
       Visibility="{Binding WonVisible, Converter={StaticResource VisibilityConverter}}"
    />
    <TextBlock Text="Use arrow keys to move, Enter to reset." TextAlignment="Right" />
    </DockPanel>
    <Border Grid.Row="1" BorderBrush="Black" BorderThickness="1">
    <Canvas Width="{Binding BoardWidthPixels}" Height="{Binding BoardHeightPixels}">
    <Path Stroke="DarkGreen"
      StrokeThickness="{Binding FieldDisplaySizePixels}"
      StrokeStartLineCap="Round"
      StrokeEndLineCap="Round"
      StrokeLineJoin="Round"
      Data="{Binding SnakeGeometry}"
    />
    <Path Fill="DarkRed">
        <Path.Data>
        <EllipseGeometry Center="{Binding FoodCenter}"
            RadiusX="{Binding HalfFieldDisplaySizePixels}"
            RadiusY="{Binding HalfFieldDisplaySizePixels}"
        />
        </Path.Data>
    </Path>
    </Canvas>
    </Border>
    </Grid>
    </Window>
'@)

        [ViewModel] $viewModel = New-Object ViewModel -Property @{
            BoardWidthPixels           = $boardWidth * $fieldSizePixels
            BoardHeightPixels          = $boardHeight * $fieldSizePixels
            FieldDisplaySizePixels     = $fieldSizePixels - 2
            HalfFieldDisplaySizePixels = ($fieldSizePixels - 2) / 2
        }
        $mainWindow.DataContext = $viewModel

        [DispatcherTimer] $timer = New-Object DispatcherTimer -Property @{
            Interval = New-Object TimeSpan 0, 0, 0, 0, $stepsMilliseconds
        }

        [Snake] $snake = New-Object Snake $boardWidth, $boardHeight, $fieldSizePixels
        [Food] $food = New-Object Food $boardWidth, $boardHeight, $fieldSizePixels
        $food.Move($snake) | Out-Null

        Function Update-View()
        {
            $viewModel.SetSnakeGeometry([Geometry]::Parse($snake.GetGeometryString()))
            [Tuple[Int32, Int32]] $foodLocation = $food.GetGeometryLocation()
            $viewModel.SetFoodCenter((New-Object Point $foodLocation.Item1, $foodLocation.Item2))
        }


        $mainWindow.add_Loaded( {
                Update-View
                $timer.Start()
            })

        $timer.Tag = [SnakeAction]::Nothing
        $timer.add_Tick( {
                [SnakeAction] $action = $snake.Move($food)
                Switch ($action)
                {
                    'Collision'
                    {
                        if ($timer.Tag -ceq 'Collision')
                        {
                            $viewModel.SetGameOverVisible($true)
                            $timer.Stop()
                        }
                        Break
                    }
                    'FoodEaten'
                    {
                        $viewModel.SetScore($viewModel.Score + 1)
                        If ($food.Move($snake))
                        {
                            $viewModel.SetWonVisible($true)
                            $timer.Stop()
                        }
                        Break
                    }
                }
                Update-View
                $timer.Tag = $action
            })

        [EventManager]::RegisterClassHandler([Window], [Keyboard]::KeyDownEvent, [KeyEventHandler] {
                Param ([Object] $sender, [KeyEventArgs] $eventArgs)
                Switch ($eventArgs.Key)
                {
                    'Left'
                    {
                        If ($snake.Segments[-1].Direction -cne 'Right')
                        {
                            $snake.Direction = 'Left'
                        }
                        Break
                    }
                    'Right'
                    {
                        If ($snake.Segments[-1].Direction -cne 'Left')
                        {
                            $snake.Direction = 'Right'
                        }
                        Break
                    }
                    'Up'
                    {
                        If ($snake.Segments[-1].Direction -cne 'Down')
                        {
                            $snake.Direction = 'Up'
                        }
                        Break
                    }
                    'Down'
                    {
                        If ($snake.Segments[-1].Direction -cne 'Up')
                        {
                            $snake.Direction = 'Down'
                        }
                        Break
                    }
                    'Return'
                    {
                        $snake.Reset()
                        $food.Move($snake)

                        $viewModel.SetScore(0)
                        $viewModel.SetGameOverVisible($false)
                        $viewModel.SetWonVisible($false)
                        Update-View

                        $timer.Start()
                        Break
                    }
                    'Q'
                    {
                        If (-not $timer.IsEnabled)
                        {
                            'Cheater ;)' | Out-Host
                            $viewModel.SetGameOverVisible($false)
                            $timer.Start()
                        }
                        Break
                    }
                }
            })

        [Application] $application = New-Object Application
        $application.Run($mainWindow) | Out-Null
        $timer.Stop()   
    
    }

    End
    {
        Stop-Log
    }

}

<#######</Body>#######>
<#######</Script>#######>