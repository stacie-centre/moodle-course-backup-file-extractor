# PowerShell script to extract the files from a Moodle course backup
# PF 2020-09-21

# Moodle changes the filenames of all uploaded files to strings of hex
# We can look at the database to work out what the original filename is, however
# the export course package (which is just a .zip) contains an XML file ('files.xml') which we can use as a database
# to convert the files back to their original name.

# Note the files are unchanged, just the filename is encoded.  It would have perhaps been rather obvious
# for Moodle to simply allow users to export all their uploaded files with the original names but what do I know.

# Note we need to flip / into \ for Windows.

# UNZIP the backup (just rename it to add .zip) and feed the directory to this variable

$MoodleBackupDir = "C:\Extracted-moodle-course-backup"

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
