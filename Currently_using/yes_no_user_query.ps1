# A script to simply ask a user query
# it returns
#  1 for yes 
#  2 for no
#  3 for unkown response
param (
    [string]$query
)

# expected responses
$positiveResponse = @("y", "yes")
$negativeResponse  = @("n", "no")
$response = $positiveResponse + $negativeResponse

Write-Host $query -ForegroundColor Yellow
$userResponse = Read-Host "User reply options - (yes/y or no/n)"

[int]$returnValue = 3

if($response.Contains($userResponse))
{
    if($positiveResponse.Contains($userResponse))
    {
        # Write-Host "Positive" -ForegroundColor Green
        $returnValue = 1
    }
    elseif ($negativeResponse.Contains($userResponse))
    {
        # Write-Host "Negative" -ForegroundColor Red
        $returnValue = 2
    }
}
else
{
    Write-Host "Unknown user response: " -ForegroundColor Magenta -NoNewline
    Write-Host $userResponse -ForegroundColor Blue
    $returnValue = 3
}

return $returnValue