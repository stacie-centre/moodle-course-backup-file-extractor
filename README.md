# moodle-course-backup-file-extractor
This script will extract files from a Moodle exported course backup

Moodle changes the filenames of all uploaded files to strings of hex
We can look at the database to work out what the original filename is, however
the export course package (which is just a .zip) contains an XML file ('files.xml') which we can use as a database
to convert the files back to their original name.

Note the files are unchanged, just the filename is encoded.  It would have perhaps been rather obvious
for Moodle to simply allow users to export all their uploaded files with the original names but what do I know.

Note we need to flip / into \ for Windows.
