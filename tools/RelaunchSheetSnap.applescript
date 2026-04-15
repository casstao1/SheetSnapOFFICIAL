set relaunchScript to POSIX path of "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL/tools/relaunch_sheetsnap.sh"

try
	do shell script "/bin/zsh " & quoted form of relaunchScript
on error errMsg
	display dialog errMsg buttons {"OK"} default button "OK" with title "SheetSnap Relauncher"
end try
