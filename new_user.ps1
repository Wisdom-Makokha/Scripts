$password = Read-Host -AsSecureString "Enter your password: "

$username = Read-Host "Enter your username: "
$fullName = Read-Host "Enter your name: "
New-LocalUser -Name $username -Password $password -FullName $fullName -Description "standard user account"
