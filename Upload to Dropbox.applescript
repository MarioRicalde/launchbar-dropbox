-- Configuration
property dropbox_id : XXXXXXX -- Check your public URL's for http://dl.getdropbox.com/u/<id>

(*
   How to use?
   
   #1:
     - Bring the script to launchbar.
     - Press space.
      - Enter the name of the image
      - Enter the format (optional)
      > Example: myname, jpg
     - A cross-hair will appear. Select the region you want for the screenshot.
       or
       Press space to make a window screenshot.
     Bring this script in LaunchBar, press space and type the name that you would
     like to give to that screenshot and press return.
     You will see a cross-hair, you can start selecting the region that you want a
     screenshot of or you can press "space" key and take a screenshot of a window.
     This will generate screenshot named myname in jpg format in your Dropbox folder.
     You can also enter the format of the image
     e.g. myname, jpg
     note that the syntax is <name><comma><space><format>
   
   #2:
     - Bring the script to launchbar.
     - Hit return.
     - A cross-hair will appear. Select the region you want for the screenshot.
       or
       Press space to make a window screenshot.
     - This will generate screenshot with an automatic name in your Dropbox folder.
     
   #3:
     - Select a file using Launch bar and open it with this script by pressing tab, finding the script and pressing enter.
     - The file will be copied to the dropbox public folder


   Authors: 
    - iRounak (original)
    - aristidesfl (rewrite)
    - kuroir - http://github.com/kuroir (sub directories implementation, rewrote docs.)
*)

global current_action_type, shared_folder, y, mo, d, h, m, s

on resolve_shared_folder(action_type)
  set current_action_type to action_type
  set {year:y, month:mo, day:d, hours:h, minutes:m, seconds:s} to (current date)
  set shared_folder to (path to home folder from user domain) & "Dropbox:Public:"
  if action_type is "screenshot" then
    set shared_folder to shared_folder & "screenshots:" & y & ":" & mo * 1 & ":" as string
  else
    set shared_folder to shared_folder & "files:" & y & ":" as string
  end if
  -- Create the directory if it doesn't exist.'
  do shell script "/bin/mkdir -p " & quoted form of POSIX path of shared_folder
end resolve_shared_folder

on run
  try
    
    if application "Dropbox" is not running then launch application "Dropbox"
    tell application "LaunchBar" to hide
    
    resolve_shared_folder("screenshot")
    set theDate to (d & "-" & h & "h" & m & "m" & s & "s")
    
    set the_format to "jpg"
    set file_name to theDate & "." & the_format
    set the_file to ""
    set thecmd to my dupcheck(file_name, shared_folder, the_format, dropbox_id, the_file)
    
    
  on error e
    tell me to activate
    display dialog e
  end try
end run

on open (the_file)
  try
    
    if application "Dropbox" is not running then launch application "Dropbox"
    tell application "LaunchBar" to hide
    try
      set text item delimiters to ":"
      set file_name to last text item of (the_file as text)
      set text item delimiters to ""
    on error
      set text item delimiters to ""
    end try
    
    resolve_shared_folder("file")
    
    set the_format to "file"
    set thecmd to my dupcheck(file_name, shared_folder, the_format, dropbox_id, the_file)
    
    
  on error e
    tell me to activate
    display dialog e
  end try
  
  
end open

-- This handles the comma separated syntax and the files
on handle_string(thetext)
  try
    if application "Dropbox" is not running then launch application "Dropbox"
    tell application "LaunchBar" to hide
    
    set AppleScript's text item delimiters to ","
    set file_name to first text item of thetext
    set the_format to false
    try
      set the_format to text 2 thru -1 of second text item of thetext
    end try
    if the_format is false then set the_format to "png"
    set AppleScript's text item delimiters to ""
    set file_name to file_name & "." & the_format as text
    set the_file to ""
    
    resolve_shared_folder("string")
    
    set thecmd to my dupcheck(file_name, shared_folder, the_format, dropbox_id, the_file)
    
  on error e
    tell me to activate
    display dialog e
  end try
end handle_string


-------------------------------------------------------------------
--Handlers
-------------------------------------------------------------------


on dupcheck(file_name, shared_folder, the_format, dropbox_id, the_file)
  set thedupcheck to shared_folder & file_name
  tell me to activate
  
  tell application "Finder" to if not (exists (POSIX path of thedupcheck) as POSIX file) then
    --Changed Lines******************************************************   
    set the_result to my processitem(file_name, shared_folder, the_format, dropbox_id, the_file)
  else
    tell me to activate
    set thedisplay to display dialog "An item with the name \"" & file_name & "\" already exists in the destination" buttons {"Cancel ", "Rename", "Replace"} default button "Replace"
    
    if button returned of thedisplay is "Replace" then
      my processreplace(file_name, shared_folder, the_format, dropbox_id, the_file)
    else if button returned of thedisplay is "Rename" then
      my processrename(file_name, shared_folder, the_format, dropbox_id, the_file)
    else
      return "Canceled"
      
    end if
  end if
end dupcheck

on processitem(file_name, shared_folder, the_format, dropbox_id, the_file)
  growlRegister()
  if the_format = "file" then
    tell application "Finder" to copy file the_file to folder shared_folder
    growlNotify("Uploading file ", file_name)
    
  else if the_format = "filerename" then
    set thecmd to "cp " & (POSIX path of the_file) & " " & (POSIX path of shared_folder) & file_name
    do shell script thecmd
    growlNotify("Uploading file ", file_name)
  else
    set ifile to shared_folder & file_name
    set qifile to quoted form of (POSIX path of ifile)
    set thecmd to "screencapture -i -t " & the_format & " " & qifile
    do shell script thecmd
    growlNotify("Uploading screenshot ", file_name)
    
  end if
  my processurl(file_name, dropbox_id)
end processitem

on processreplace(file_name, shared_folder, the_format, dropbox_id, the_file)
  set ifile to shared_folder & file_name
  set qifile to quoted form of (POSIX path of ifile)
  do shell script "rm -r " & qifile
  set qshared_folder to quoted form of (POSIX path of shared_folder)
  my processitem(file_name, shared_folder, the_format, dropbox_id, the_file)
end processreplace

on processrename(file_name, shared_folder, the_format, dropbox_id, the_file)
  repeat
    set AppleScript's text item delimiters to "."
    set theonlyname to text items 1 thru -2 of file_name
    set file_nameextension to last text item of file_name
    set AppleScript's text item delimiters to ""
    tell me to activate
    set file_name to text returned of (display dialog "Enter the new name: (This dialog box will reappear if an item with the new name you specified also exists in the destination folder)" default answer theonlyname)
    set file_name to file_name & "." & file_nameextension
    set thenewcheck to shared_folder & file_name
    
    if the_format = "file" then set the_format to "filerename"
    
    tell application "Finder" to if not (exists (POSIX path of thenewcheck) as POSIX file) then
      my processitem(file_name, shared_folder, the_format, dropbox_id, the_file)
			exit repeat
		end if
	end repeat
end processrename

on processurl(file_name, dropbox_id)
  set file_name to file_name as text
	try
		set AppleScript's text item delimiters to " "
		set file_name to text items of file_name
		set AppleScript's text item delimiters to "%20"
		set file_name to file_name as text
		set AppleScript's text item delimiters to ""
	end try
	set {year:y, month:mo, day:d, hours:h, minutes:m, seconds:s} to (current date)
	set theurl to "http://dl.getdropbox.com/u/" & dropbox_id & "/"
	if current_action_type is "screenshot" then
    set theurl to theurl & "screenshots/" & y & "/" & mo * 1 & "/" & file_name
  else
    set theurl to theurl & "files/" & y & "/" & file_name as string
  end if
	
	-- set curlCMD to ¬
	-- "curl --stderr /dev/null \"http://is.gd/api.php?longurl=" & theurl & "\""
	-- set theurl to (do shell script curlCMD)
	set the clipboard to theurl
	tell application "LaunchBar"
		set selection as text to theurl
		activate
	end tell
end processurl



-- additional scripting for Growlnotification
using terms from application "GrowlHelperApp"
	on growlRegister()
		tell application "GrowlHelperApp"
			register as application "Share with Dropbox" all notifications {"Alert"} default notifications {"Alert"} icon of application "Dropbox.app"
		end tell
	end growlRegister
	on growlNotify(grrTitle, grrDescription)
		tell application "GrowlHelperApp"
			notify with name "Alert" title grrTitle description grrDescription application name "Share with Dropbox"
		end tell
	end growlNotify
end using terms from