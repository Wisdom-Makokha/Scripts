param (
    [string]$sourceDirectory = "C:\Users\Dev Ark\Downloads\",
    [string]$destinationDirectory = "s:\Pictures\Temp"
)

while (-not(Test-Path($sourceDirectory))) {
    Write-Host "The source directory file path was not found or is invalid" -ForegroundColor Red.\categories
    Write-Host "   " $sourceDirectory -ForegroundColor Blue
    $sourceDirectory = Read-Host "Enter the path for your source directory"
}

while (-not(Test-Path($destinationDirectory))) {
    Write-Host "The source directory file path was not found or is invalid" -ForegroundColor Red.\categories
    Write-Host "   " $destinationDirectory -ForegroundColor Blue
    $destinationDirectory = Read-Host "Enter the path for your source directory"
}

$files = Get-ChildItem -Path $sourceDirectory -File

$logsPath = Join-Path -Path $destinationDirectory -ChildPath "Scripts\organizer-log.txt"
if (-not(Test-Path -Path $logsPath)) {
    New-Item -Path $logsPath -ItemType "file" 
}

$initialFileCount = 0

if ($files.Count -ne $initialFileCount) {
    #  this is the hash table for each category as the key and the number of files added as the value
    $sortStats = @{}
    # this is the hash table for each unique directory and a number for a choice
    $categoryPick = @{}

    [string[]]$unkownExtensions = @()

    # read the hash table from a file on the same directory using the .\read_hash_from_file script
    # if the first read fails try from another file which is the backup
    $categoriesFilePath = Join-Path -Path $pwd -ChildPath "categories"
    $categoriesBackUpFilePath = Join-Path -Path $env:USERPROFILE -ChildPath "\Documents\MyBackups\categories"
    $categories = @{}
    try {
        [hashtable]$categories = .\read_hash_from_file.ps1 -filePath $categoriesFilePath -ErrorAction Stop
    }
    catch {
        try {
            $categoriesFilePath = Join-Path -Path $env:USERPROFILE -ChildPath "\Documents\MyBackups\categories"
            [hashtable]$categories = .\read_hash_from_file.ps1 -filePath $categoriesFilePath -ErrorAction Stop
        } 
        catch {
            Write-Host "Unable to find category records for the sorting script" -ForegroundColor Red
            return
        }
    }

    #excluded file types 
    $excludedExtensions = @('.tmp', '.bak', '.log', '.crdownload')
    $sortStats.Add('Excluded', $initialFileCount)
    $sortStats.Add('Other', $initialFileCount)

    $index = 1
    Write-Host "Checking destination folder for category directories" -ForegroundColor Yellow
    foreach ($category in $categories.Values | Select-Object -Unique) {        
        $destinationFolder = Join-Path -Path $destinationDirectory -ChildPath $category
        if (-not(Test-Path -Path $destinationFolder)) {
            Write-Host $category -NoNewline
            Write-Host " directory not found" -ForegroundColor Red
            Write-Host "Creating new directory named: " -ForegroundColor Yellow -NoNewline
            Write-Host $category -ForegroundColor Cyan
            New-Item -Path $destinationFolder -ItemType "directory"
        }
        else {
            Write-Host $category -ForegroundColor Cyan -NoNewline
            Write-Host " directory present" -ForegroundColor Green
        }

        $categoryPick.Add($index.ToString(), $category)
        $index += 1
        #add the unique folder names to evaluate how the files are being moved
        $sortStats.Add($category, $initialFileCount)
    }

    #Move files to their respective subdirectories
    $files | ForEach-Object {
        $extension = $_.Extension.ToLower()

        if ($excludedExtensions.Contains($extension)) {
            Add-Content $logsPath -Value "Excluded extension"
            Write-Host "Excluded extension" -ForegroundColor Yellow -NoNewline
            Write-Host $extension -ForegroundColor Cyan

            $sortStats['Excluded'] = $sortStats['Excluded'] + 1;
        }
        #Next check that the file is in our list of recognised extensions
        elseif ($categories.ContainsKey($extension)) {
            $destinationFolder = Join-Path -Path $destinationDirectory -ChildPath $categories[$extension]
                
            #try is used to check and make sure that the file is not being used by another process
            try {
                #organise the folder
                Move-Item $_.FullName $destinationFolder -ErrorAction Stop
                Write-Host "Moved " -ForegroundColor Green -NoNewline
                Write-Host $($_.Name) -ForegroundColor Cyan -NoNewline
                Write-Host " to " -ForegroundColor Green -NoNewline
                Write-Host $destinationFolder -ForegroundColor Cyan

                $sortStats[$categories[$extension]] = $sortStats[$categories[$extension]] + 1;
            }
            catch {
                Add-Content $logsPath -Value "Error moving file: $($_.Name) - $($_.Exception.Message)"
                Write-Host "Error moving file: " -ForegroundColor Red -NoNewline
                Write-Host $_.Name -ForegroundColor Blue -NoNewline
                Write-Host " - " -ForegroundColor Red -NoNewline
                Write-Host $_.Exception.Message -ForegroundColor Blue
            }
        }
            
        #Next if the extension is unrecognised then put it in other
        else {
            $unkownExtensions += $extension
            Add-Content $logsPath -Value "Extension moved to Other: "
            Add-Content $logsPath -Value $extension
            Write-Host "Extension moved to Other: " -ForegroundColor Yellow -NoNewline
            Write-Host $extension -ForegroundColor Cyan

            $destinationFolder = Join-Path -Path $destinationDirectory -ChildPath 'Other'
            if (-not(Test-Path -Path $destinationFolder)) {
                New-Item -Path $destinationFolder -ItemType "directory"
            }

            try {
                Move-Item $_.FullName $destinationFolder -ErrorAction Stop

                Write-Host "Moved " -ForegroundColor Red -NoNewline
                Write-Host $($_.Name) -ForegroundColor Blue -NoNewline
                Write-Host " to " -ForegroundColor Red -NoNewline
                Write-Host $destinationFolder -ForegroundColor Blue

                $sortStats['Other'] = $sortStats['Other'] + 1
            }
            catch {
                Add-Content $logsPath -Value "Error moving file: $($_.Name) - $($_.Exception.Message)"
                Write-Host "Error moving file: " -ForegroundColor Yellow -NoNewline
                Write-Host $_.Name -ForegroundColor Cyan -NoNewline
                Write-Host " - " -ForegroundColor Yellow -NoNewline
                Write-Host $_.Exception.Message -ForegroundColor Cyan
            } 
        }
    }

    Add-Content $logsPath -Value "Done organizing files!"
    Write-Host "Done organizing files" -ForegroundColor Green
    $sortStats.Keys | ForEach-Object {
        $directory = "  {0}:" -f $_
        Write-Host $directory -ForegroundColor Green -NoNewline
        Write-Host $sortStats[$_] -ForegroundColor Cyan
    }
    Write-Host "Total files sorted: " -ForegroundColor Green -NoNewline
    Write-Host $files.Count -ForegroundColor Blue

    #add check for if any files have been added to other then ask which category it should be added to
    if ($sortStats['Other'] -gt $initialFileCount ) {
        Write-Host "Some unknown file extensions were found" -ForegroundColor Yellow
        Write-Host "There is no special function for if weird or wrong values are picked for now" -ForegroundColor Red
        foreach ($checkExtension in $unkownExtensions | Select-Object -Unique) {
            Write-Host $checkExtension -ForegroundColor Cyan -NoNewline
            Write-Host " is the unkown extension." -ForegroundColor Yellow
            Write-Host "Pick the directory to categorise into by entering the number corresponding to your choice: " 

            $categoryPick.Keys | ForEach-Object {
                $selection = "  {0} - {1}" -f $_, $categoryPick[$_]
                Write-Host $selection
            }

            $userChoice = Read-Host "Enter choice"
            
            if ($categoryPick.ContainsKey($userChoice)) {
                Write-Host "'" -ForegroundColor Green -NoNewline
                Write-Host $checkExtension -ForegroundColor Blue -NoNewline
                Write-Host "' will be added to category '" -ForegroundColor Green -NoNewline
                Write-Host $categoryPick[$userChoice] -ForegroundColor Blue -NoNewline
                Write-Host "'" -ForegroundColor Yellow

                $categories.Add($checkExtension, $categoryPick[$userChoice])
            }
            else {
                Write-Host $userChoice -ForegroundColor DarkBlue -NoNewline
                Write-Host ": Unknown user choice selected" -ForegroundColor Red
                Write-Host "Nothing was added to categories hash table" -ForegroundColor Red
            }
        }

        # update the stored lists
        .\print_hash_to_file_script.ps1 -filePath $categoriesFilePath -hash_to_print $categories
        .\print_hash_to_file_script.ps1 -filePath $categoriesBackUpFilePath -hash_to_print $categories
    }
}
else {
    Write-Host "No files in directory to sort" -ForegroundColor Green
}