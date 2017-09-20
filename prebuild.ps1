Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function GetLibrary
{
    param([string]$url)

    $path = "dlls.zip"

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile( $url, $path )

    Unzip "dlls.zip" "."

    Remove-Item "dlls.zip"
    Remove-Item "*.txt"
}

GetLibrary "https://www.libsdl.org/release/SDL2-2.0.5-win32-x86.zip"
GetLibrary "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14-win32-x86.zip"
GetLibrary "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.1-win32-x86.zip"
GetLibrary "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1-win32-x86.zip"
