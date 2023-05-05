# Login to your Azure account using managed identity
Connect-AzAccount -Identity

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Resource providers to enable
$resourceProvidersToEnable = @("Microsoft.PolicyInsights", "Microsoft.Insights")

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the active subscription
    Set-AzContext -SubscriptionId $subscription.Id

    foreach ($resourceProviderToEnable in $resourceProvidersToEnable) {
        # Check if the Resource Provider is already registered
        $resourceProvider = Get-AzResourceProvider -ProviderNamespace $resourceProviderToEnable

        if ($resourceProvider.RegistrationState -ne "Registered") {
            # Register the Resource Provider
            Write-Host "Registering $resourceProviderToEnable in subscription $($subscription.Id)"
            Register-AzResourceProvider -ProviderNamespace $resourceProviderToEnable
        }
        else {
            Write-Host "$resourceProviderToEnable is already registered in subscription $($subscription.Id)"
        }
    }
}
