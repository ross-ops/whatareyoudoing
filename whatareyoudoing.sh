#!/bin/sh

# Get a datestamp
dstamp=$(date +%y%m%d)

# Set lockfile 
lockfile="$HOME/.whatareyoudoing/lock-${dstamp}"

# If lockfile does not exist, create it.
# Else, exit because script is already running. 
if [ ! -f "$lockfile" ]; then
    touch "$lockfile"
else
    echo "WAYD already running"
    exit
fi

# WAYD specific formatting for zenity
zenity_format() {
    zenity "$1" --text "$2" --title "WAYD" "$3" --window-icon="$HOME/.local/share/icons/720x720-WAYD.png" --name='WAYD' --class='WAYD'
}

# Specific text format
zenity_text() {
    zenity_format '--entry' "$1" "--entry-text=$2"
}

# Specific question format
zenity_question() {
    zenity_format '--question' "$1"
}

# Test id cancel button has been pressed
test_cancel() {
    if [ -z "$1" ]; then
        if zenity_question "Want to quit?"; then
            rm -rf "$lockfile"
            exit 0
        fi
    fi
}


# Ask where you want timesheets saved
timesheet_location=$(zenity_text "Where would you like to write your timesheet files? Default:" "$HOME/timesheets")

# See if last popup was 'canceled'
test_cancel "$timesheet_location"

# If timesheet directory location isn't set, default it
if [ -z "$timesheet_location" ]; then
    timesheet_location="$HOME/timesheets"
fi

# Set timesheet file
timesheet="$timesheet_location/timesheet-$dstamp"

# What you _were_ doing
wywd=""

# If timesheet directory doesn't exist, make it
if [ ! -d "$timesheet_location" ]; then
    mkdir "$timesheet_location"
elif [ ! -f "$timesheet" ]; then
    # If timesheet file doesn't exist, make it
    touch "$timesheet"
else
    # Timesheet already exists, grab the last thing you did
    wywd=$(tail -n1 "$timesheet" | sed -r 's/^[0-9]{2}:[0-9]{2}:[0-9]{2}\s//')
fi

# Ask how often you want to be prompted
frequency=$(zenity_text "How often should I ask you (in minutes)? Default:" "15")

# See if last popup was 'canceled'
test_cancel "$frequency"

#  If frequency not explicitly set, default it
if [ -z "$frequency" ]; then
    frequency=15
fi

# Get frequency in seconds for sleep
frequency_secs=$((frequency * 60))

# Ask What Are You Doing and lock until answered
ask_wayd() {
    
    # If lock isn't set, then we can ask what you are doing
    if [ -z "$lock" ]; then
        lock=1

        # If what are you doing is answered, then unlock
        if wayd=$(zenity_text "What are you doing?" "$wywd"); then
            lock=''
        fi
        
        # Test if last popup was 'cancled'
        test_cancel "$wayd"

        # If WAYD entry not set, default it
        if [ -z "$wayd" ]; then
            wayd='ditto'
        fi 

        # Get time of entry write
        now=$(date +"%T")
        # Write time and message to timesheet
        echo "$now $wayd" >> "$timesheet"
        # Get last line of timesheet for next default and strip timestamp
        wywd=$(tail -n1 "$timesheet" | sed -r 's/^[0-9]{2}:[0-9]{2}:[0-9]{2}\s//')
    fi
}

# Ask the first time
ask_wayd

# Loop contines till canceled
while true; do
    # Sleep for set frequency AFTER previous WAYD timesheet entry closed
    sleep "$frequency_secs"
    ask_wayd
done