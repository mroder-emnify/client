#Requires -Version 5

# Automatic Mondoo downloader to be used with
# Set-ExecutionPolicy RemoteSigned -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex (new-object net.webclient).downloadstring('https://mondoo.com/download.ps1')

function fail($msg, [int] $exit_code=1) { Write-Host $msg -f red; exit $exit_code }
function info($msg) {  Write-Host $msg -f white }
function success($msg) { Write-Host $msg -f darkgreen }
function purple($msg) { Write-Host $msg -f magenta }

purple "Mondoo Binary Download Script"
purple "
                        .-.            
                        : :            
,-.,-.,-. .--. ,-.,-. .-`' : .--.  .--.
: ,. ,. :`' .; :: ,. :`' .; :`' .; :`' .; :
:_;:_;:_;``.__.`':_;:_;``.__.`'``.__.`'``.__.
"
                 
info "Welcome to the Mondoo Binary Download Script. It downloads the Mondoo binary for
Windows into $ENV:UserProfile\mondoo and adds the path to the user's environment PATH. If 
you are experiencing any issues, please do not hesitate to reach out: 

  * Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions

This script source is available at: https://github.com/mondoohq/client
"

# Any subsequent commands which fails will stop the execution of the shell script
$previous_erroractionpreference = $erroractionpreference
$erroractionpreference = 'stop'

# verify powershell pre-conditions
if(($PSVersionTable.PSVersion.Major) -lt 5) {
  fail "
The install script requires PowerShell 5 or later.
To upgrade PowerShell visit https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell
"
}

# show notification to change execution policy:
if((Get-ExecutionPolicy) -gt 'RemoteSigned' -or (Get-ExecutionPolicy) -eq 'ByPass') {
  fail "
PowerShell requires an execution policy of 'RemoteSigned'. Please change the policy by running:
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
"
}

# we only support x86_64 at this point, stop if we got arm
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
  fail "
Your processor architecture $env:PROCESSOR_ARCHITECTURE is not supported yet. Contact hello@mondoo.com or join the Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions
"
}

function Get-UserAgent() {
    return "MondooDownloadScript/1.0 (+https://mondoo.com/) PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) (Windows NT $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor);$PSEdition)"
}

function download($url,$to) {
    $wc = New-Object Net.Webclient
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $wc.downloadFile($url,$to)
}

function determine_latest() {
  $url = 'https://releases.mondoo.com/mondoo/latest.json'
  $wc = New-Object Net.Webclient
  $wc.Headers.Add('User-Agent', (Get-UserAgent))
  $latest = $wc.DownloadString($url) | ConvertFrom-Json 
  $entry = $latest.files | where { $_.platform -eq "windows" -and $_.filename -match 'zip$' }
  $entry.filename
}

function getenv($name,$global) {
    $target = 'User'; if($global) {$target = 'Machine'}
    [System.Environment]::GetEnvironmentVariable($name,$target)
}

function setenv($name,$value,$global) {
  $target = 'User'; if($global) {$target = 'Machine'}
  [System.Environment]::SetEnvironmentVariable($name,$value,$target)
}

$dir = Get-Location

# manual override
# $version = '5.2.0'
# $arch = 'amd64'
# $releaseurl = "https://releases.mondoo.com/mondoo/${version}/mondoo_${version}_windows_${arch}.zip"

# automatic
$releaseurl = determine_latest

# download windows binary zip
$releasezipfile = "$dir\mondoo.zip"
info " * Downloading mondoo from $releaseurl to $releasezipfile"
download $releaseurl $releasezipfile

info ' * Extracting zip...'
# remove older version if it is still there
Remove-Item "$dir\mondoo.exe" -Force -ErrorAction Ignore
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($releasezipfile,$dir)
Remove-Item $releasezipfile -Force

success ' * Mondoo was downloaded successfully!'

# Display final message
info "Thank you for downloading Mondoo!"
info "
If you need support, contact hello@mondoo.com or join the Mondoo Community on GitHub Discussion:

  * https://github.com/orgs/mondoohq/discussions
"

# reset erroractionpreference
$erroractionpreference = $previous_erroractionpreference