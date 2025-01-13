$categoriesFilePath = "c:\Users\Dev Ark\Documents\MyBackups\categories"

$categories = @{
    '.jpg' = 'Pics'
    '.png' = 'Pics'
    '.jpeg' = 'Pics'
    '.jfif' = 'Pics'
    '.bmp' = 'Pics'
    '.gif' = 'GIFs'
    '.mp4' = 'Videos'
    '.avi' = 'Videos'
    '.mkv' = 'Videos'
    '.doc' = 'Documents'
    '.docx' = 'Documents'
    '.pdf' = 'Documents'
    '.txt' = 'Documents'
    '.pptx' = 'Documents'
    '.xlsx' = 'Documents'
    '.exe' = 'Software'
    '.msi' = 'Software'
    '.zip' = 'Compressed'
    '.rar' = 'Compressed'
    '.7z' = 'Compressed'
    '.gz' = 'Compressed'
    '.ps1' = 'Scripts'
    '.bat' = 'Scripts'
    '.mp3' = 'Audio'
    '.flac' = 'Audio'
    '.wav' = 'Audio'
}

try {
    .\print_hash_to_file_script.ps1 -hash_to_print $categories -filePath $categoriesFilePath -ErrorAction Stop
}
catch {
    Write-Host $_
}