$Password = Read-Host -AsSecureString
$params = @{
    Name        = 'TaskUser'
    Password    = $Password
    FullName    = 'Task User'
    Description = 'Local user for task scheduler demos'
}
New-LocalUser @params