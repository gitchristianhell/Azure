# Load required modules
Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Monitor

# Authenticate using managed identity
$AzureContext = (Connect-AzAccount -Identity).Context

function Update-CreatedByTag {
    param (
        [ValidateSet('true', 'false')]
        [string]$WriteTags = 'true'
    )

    $WriteTagsBool = [System.Convert]::ToBoolean($WriteTags)

    # Get all the subscriptions that the managed identity has access to
    $Subscriptions = Get-AzSubscription -TenantId $AzureContext.Tenant.Id -ErrorAction SilentlyContinue | Where-Object State -eq 'Enabled' | Sort-Object Name

    Write-Output "Found $($Subscriptions.Count) subscription$(If ($Subscriptions.Count -ne 1){'s'})"

    # Loop through all the subscriptions
    $Subscriptions | ForEach-Object {
        Write-Output "Processing subscription: $($_.Name) - $($_.Id)"

        # Set the context to the current subscription
        Set-AzContext -SubscriptionId $_.Id -ErrorAction SilentlyContinue

        $resources = Get-AzResource

        # Filter resources that don't have 'createdBy' tag
        $resourcesWithoutCreatedByTag = $resources | Where-Object { -not ($_.Tags -and $_.Tags.ContainsKey('createdBy')) }

        $tagUpdates = @()

        Foreach ($resource in $resourcesWithoutCreatedByTag) {

            # Retrieve logs for the resource
            $logs = Get-AzLog -ResourceId $resource.ResourceId -StartTime (Get-Date).AddDays(-90) -EndTime (Get-Date) -WarningAction SilentlyContinue

            # Filter logs with non-Microsoft callers and OperationName like '*Create*'
            $filteredLogs = $logs | Where-Object { $_.Caller -notlike 'Microsoft*' -and $_.OperationName -like '*Create*' }

            # Get the latest log
            $latestLog = $filteredLogs | Sort-Object -Property EventTimestamp | Select-Object -First 1

            if (!$latestLog) {
                Write-Warning "No logs for resource: $($resource.Name) - $($resource.ResourceId)"
            }
            else {
                $createdBy = $latestLog.Caller
                $createdDate = $latestLog.EventTimestamp

                if ([string]::IsNullOrEmpty($createdBy)) {
                    Write-Output "Caller is empty for resource: $($resource.Name) - $($resource.ResourceId)"
                }
                else {
                    Write-Output "Found resource: $($resource.Name) - $($resource.ResourceId) with createdBy = $createdBy and createdDate = $createdDate"

                    # Check if the caller is a GUID
                    if ($createdBy -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                        # Resolve the GUID to a service principal name
                        $servicePrincipal = Get-AzADServicePrincipal -ObjectId $createdBy

                        if ($servicePrincipal) {
                            $createdBy = "Service Principal - Name: $($servicePrincipal.DisplayName), ID: $($servicePrincipal.ID)"
                        }
                        else {
                            $createdBy = "Unknown (Object ID: $createdBy)"
                        }
                    }
                    else {
                        # The caller is not a GUID, so assume it's a UPN
                        # You can add additional validation or error checking here if needed
                        $createdBy = $latestLog.Caller
                    }

                    # Add tag update to the list
                    $tagUpdates += @{ResourceId = $resource.ResourceId; Tags = @{ createdBy = $createdBy; createdDate = $createdDate } }
                }
            }
        }

        # Update tags if WriteTags is set to true
        if ($WriteTagsBool) {
            $tagUpdates | ForEach-Object {
                Update-AzTag -ResourceId $_.ResourceId -Tag $_.Tags -Operation Merge
                Write-Output "Tagged resource: $($_.ResourceId)"
            }
        }

        # Display summary of the execution
        Write-Output "Total resources tagged: $($tagUpdates.Count) in subscription: $($_.Name)"
    }

}
# Run the function

Update-CreatedByTag
