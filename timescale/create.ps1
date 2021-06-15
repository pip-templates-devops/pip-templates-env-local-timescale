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
    [string] $ResourcePrefix,

    [Parameter(Mandatory=$false, Position=4)]
    [string] $KubernetesPrefix = "k8s"
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
# Skip if already installed
if (!((Test-EnvMapValue -Map $resources -Key "$ResourcePrefix") -and (Test-EnvMapValue -Map $resources -Key "$ResourcePrefix.port"))) 
{
    # Verify that k8s cluster created
    if ((Test-EnvMapValue -Map $resources -Key "$KubernetesPrefix") -and (Test-EnvMapValue -Map $resources -Key "$KubernetesPrefix.type"))
    {
        # Notify user about start of the task
        Write-Host "`n***** Started creating timescale component. *****`n"
        Switch-Kubecontext
        $namespace = Get-EnvMapValue -Map $config -Key "$KubernetesPrefix.namespace"
        $pg_version = Get-EnvMapValue -Map $config -Key "$ConfigPrefix.pg_version"
        $name = Get-EnvMapValue -Map $config -Key "$ConfigPrefix.name"
        $username = Get-EnvMapValue -Map $config -Key "$ConfigPrefix.username"
        $password = Get-EnvMapValue -Map $config -Key "$ConfigPrefix.password"

        # Set variables from config
        $templateParams = @{ 
            namespace=$namespace; 
            pg_version=$pg_version; 
            name=$name; 
            username=$username; 
            password=$password
        }
        Build-EnvTemplate -InputPath "$($path)/templates/timescale.yml" -OutputPath "$($path)/../temp/timescale.yml" -Params1 $templateParams
        # Create k8s component
        kubectl apply -f "$($path)/../temp/timescale.yml"

        # Notify user about end of the task
        Write-Host "`n***** Completed creating timescale component. *****`n"

        # Record results and save them to disk
        $port = kubectl get svc timescale -n $namespace -o=jsonpath="{.spec.ports[0].targetPort}"
        $serviceHost = $ConfigPrefix + "." + $namespace + ".svc.cluster.local"
        $endpoint = "$($serviceHost):$($port)"

        Set-EnvMapValue -Map $resources -Key "$ResourcePrefix.port" -Value $port
        Set-EnvMapValue -Map $resources -Key "$ResourcePrefix.host" -Value $serviceHost
        Set-EnvMapValue -Map $resources -Key "$ResourcePrefix.endpoint" -Value $endpoint

        Write-EnvResources -ResourcePath $ResourcePath -Resources $resources
    }
    else
    {
        Write-Error "Missing kuberentes cluster. Please install kubernetes first."
    }
} else
{
    Write-Host "Timescale component already installed. Installation skipped."
}
###################################################################
