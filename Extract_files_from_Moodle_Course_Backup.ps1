#Have yourself an *.mbz file somewhere browse-able and let fly. You'll see a couple of messages you have to acknowledge and a 
#couple of Windows dialogs to choose a destination folder and file. This update takes advantage of some new(er) tools in later versions of 
#Powershell and the addition of the "tar" command to Windows to streamline the process with more recent versions of Moodle.

 
#Prompt to create or choose destination folder
Add-Type -AssemblyName PresentationCore,PresentationFramework

[System.Windows.MessageBox]::Show('Choose or create a folder as a destination for the extracted Moodle files.')



Add-Type -AssemblyName System.Windows.Forms

$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    SelectedPath = 'c:\'
    ShowNewFolderButton = $true
}

[void]$FolderBrowser.ShowDialog()
$FolderBrowser.SelectedPath

$MyExtractFolder = $FolderBrowser.SelectedPath


# PowerShell script to extract the files from a Moodle course backup
# PF 2020-09-21

# Moodle changes the filenames of all uploaded files to strings of hex
# We can look at the database to work out what the original filename is, however
# the export course package (which is just a tar.gz) contains an XML file ('files.xml') which we can use as a database
# to convert the files back to their original name.

# Note the files are unchanged, just the filename is encoded.  It would have perhaps been rather obvious
# for Moodle to simply allow users to export all their uploaded files with the original names but what do I know.

# Note we need to flip / into \ for Windows.


#prompt to choose the mbz file

[System.Windows.MessageBox]::Show('Now choose the *.mbz file you would like to extract. Sit tight. Extracting takes a while.')

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $false # Multiple files can be chosen
	Filter = 'Moodle Backups (*.mbz)|*.mbz' # Specified file types
}
 
[void]$FileBrowser.ShowDialog()

$file = $FileBrowser.FileName;

If($FileBrowser.FileNames -like "*\*") {

	# Unzip the tar.gz file and rename 
	$FileBrowser.FileName #Lists selected files (optional)
    Copy-Item -Path $FileBrowser.FileName -Destination $FileBrowser.FileName.Replace(".mbz",".tar.gz")
    $infile = $FileBrowser.FileName.Replace(".mbz",".tar.gz")
    $outfile = ($infile -replace'\.gz$','')
    $input = New-Object System.IO.FileStream $infile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
        $buffer = New-Object byte[](1024)
    while($true){
        $read = $gzipstream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
        }

    $gzipStream.Close()
    $output.Close()
    $input.Close()
    tar -xkf $outfile -C $MyExtractFolder
   


	
}

else {
    Write-Host "Cancelled by user"
}

$MoodleBackupDir = $MyExtractFolder

$xml = [xml](Get-Content "$MoodleBackupDir\files.xml")

$xml.SelectNodes("files/file") | Where-Object -Property component -eq "mod_folder" | ForEach-Object {
    
    $sourceFile = $MoodleBackupDir + "\files\" + $_.contenthash.Substring(0,2) + "\" + $_.contenthash
    $destFolder = $MoodleBackupDir + "\export" + $_.filepath.Replace("/", "\") 

    # Check if the source file exists
    If (Test-Path $sourceFile) {
        write-host "Source file $sourceFile exists."

        # Create the destination folder if it does not exist
        If (Test-Path $destFolder) {
            write-host "Destination folder $destFolder already exists."
        } else {
            write-host "Destination folder $destFolder does not exist.  Attempting to create..."
            New-Item -ItemType directory $destFolder -Force
        }

        $destFile = $MoodleBackupDir + "\export" + $_.filepath.Replace("/", "\") + $_.filename

        # Copy the source file to it's renamed destination
        Copy-Item "$sourceFile" -Destination "$destFile"

    } else {
        write-host "!!! Source file $sourcefile DOES NOT EXIST."
    }


}
[System.Windows.MessageBox]::Show('All done! Go check ' + $MyExtractFolder + '\export')
