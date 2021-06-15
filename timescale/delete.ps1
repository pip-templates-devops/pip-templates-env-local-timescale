#!/usr/bin/env pwsh

param
(
    [Alias("c", "Config")]
    [Parameter(Mandatory=$true, Position=0)]
    [string] $ConfigPath,

    [Parameter(Mandatory=$false, Position=1)]
    [string] $ConfigPrefix = "timescale",

    [Alias("r", "Resources")]
    [Parameter(Mandatory=$false, Position=2)]
    [string] $ResourcePath,

    [Parameter(Mandatory=$false, Position=3)]
    [string] $ResourcePrefix
)

# Stop on error
$ErrorActionPreference = "Stop"

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../common/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Set default parameter values
if (($ResourcePath -eq $null) -or ($ResourcePath -eq ""))
{
    $ResourcePath = ConvertTo-EnvResourcePath -ConfigPath $ConfigPath
}
if (($ResourcePrefix -eq $null) -or ($ResourcePrefix -eq "")) 
{ 
    $ResourcePrefix = $ConfigPrefix 
}

# Read config and resources
$config = Read-EnvConfig -ConfigPath $ConfigPath
$resources = Read-EnvResources -ResourcePath $ResourcePath

###################################################################
# Skip if resource wasn't created
if ((Test-EnvMapValue -Map $resources -Key "$ResourcePrefix") -and (Test-EnvMapValue -Map $resources -Key "$ResourcePrefix.port"))
{
    # Check k8s yml file exists
    if (!(Test-Path -Path "$($path)/../temp/timescale.yml")) {
        Write-Error "Missing timescale's yml file in the 'temp' folder. Try recreating the component to generate the yml file."
    }

    # Notify user about start of the task
    Write-Host "`n***** Started deleting timescale component. *****`n"

    Switch-Kubecontext
    kubectl delete -f "$($path)/../temp/timescale.yml"

    if ($LastExitCode -ne 0){
        Write-Error "There were errors deleting timescale, Watch logs above"
    }

    # Delete results and save resource file to disk
    Remove-EnvMapValue -Map $resources -Key "$ResourcePrefix.port"
    Remove-EnvMapValue -Map $resources -Key "$ResourcePrefix.host"
    Remove-EnvMapValue -Map $resources -Key "$ResourcePrefix.endpoint"

    Write-EnvResources -ResourcePath $ResourcePath -Resources $resources

    # Notify user about end of the task
    Write-Host "`n***** Completed deleting timescale component. *****`n"

}
else 
{
    Write-Host "Timescale cluster doesn't exists. Deletion skipped."
    exit 0
}
###################################################################
