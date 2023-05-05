# Connect to Azure with Managed Identity
Connect-AzAccount -Identity

# Set the management group ID
$managementGroupId = "MG-ironstone-managed"

# Set the policy definition ID and filter
$policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/ba0df93e-e4ac-479a-aac2-134bbae39a1a"
$filter = "PolicyDefinitionId eq '$policyDefinitionId' and ComplianceState eq 'NonCompliant'"

# Print the management group ID for debugging purposes
Write-Host "Getting non-compliant resources for Management Group: $managementGroupId"

# Get the non-compliant resources for the specified management group and filter
$nonCompliantResources = Get-AzPolicyState -ManagementGroupName $managementGroupId -Filter $filter

# Check if there are any non-compliant resources
if ($nonCompliantResources.Count -gt 0) {
    # Print the number of non-compliant resources
    Write-Host "Non-compliant resources found: $($nonCompliantResources.Count)"

    # Loop through each non-compliant resource
    foreach ($policy in $nonCompliantResources) {
        # Get the policy assignment name
        $policyAssignmentName = $policy.PolicyAssignmentName

        # Generate the remediation name
        $remediationName = "Remediation-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + $policyAssignmentName

        # Print the policy assignment ID and name for debugging purposes
        Write-Host "Policy Assignment ID: $($policy.PolicyAssignmentId)"
        Write-Host "Policy Assignment Name: $policyAssignmentName"

        # Print the remediation name for debugging purposes
        Write-Host "Starting remediation with Remediation Name: $remediationName"

        # Start the remediation and store the result
        $remediationResult = Start-AzPolicyRemediation -ManagementGroupName $managementGroupId -Name $remediationName -PolicyAssignmentId $policy.PolicyAssignmentId

        # Print the remediation ID for debugging purposes
        Write-Host "Remediation started with ID: $($remediationResult.RemediationId)"
    }
} else {
    # If there are no non-compliant resources, print a message
    Write-Host "No non-compliant resources found."
}
