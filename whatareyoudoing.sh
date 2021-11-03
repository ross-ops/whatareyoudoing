#!/bin/sh

usage() {
    echo "usage: $0 [exit]"
    echo "Run with no arguments for standard runmode"
    echo "Run with \`exit\` to exit WAYD and clean up"
    exit 1
}

# Get a datestamp
dstamp=$(date +%y%m%d)

# Set lockfile 
lockfile="$HOME/.whatareyoudoing/lock-${dstamp}"

# Set config file
config_file="$HOME/.whatareyoudoing/config"

# Test config file exists or make one
if [ ! -f "$config_file" ]; then
    touch "$config_file"
fi

ini_parser() {
    sed -nr "/^\[$1\]/ { :l /^$2[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" "$3"
}

# Existing timesheet file
active_ts=$(ini_parser timesheet active_timesheet "$config_file")

# Runs if the `exit` arg is passed
# Kills running WAYD processes and cleans lockfile
run_exit() {
    if [ -f "$lockfile" ]; then
        process_id=$(/bin/ps -fu "$USER"| grep "whatareyoudoing" | grep -v "grep" | awk '{print $2}')
        # rm the lockfile so the next time wayd is run, it knows that there's not a version  already running
        rm -rf "$lockfile"
        echo "Quitting WAYD"
        # Get most recent timesheet output
        if [ -n "$active_ts" ]; then
            echo "Most recent timesheet at ${active_ts}"
        fi
        # kill processes running this script
        for i in ${process_id}; do
            kill -9 "$i"
        done
        exit 0
    else
        echo "WAYD not running"
        exit 0
    fi
}

# Handle rogue args
if [ "$#" -gt 1 ]; then
  usage
fi

# Handle help/malformed args
if [ "$#" -eq 1 ] && [ "$1" != "exit" ]; then
    usage
fi

# Handle exit arg being passed
if [ "$#" -eq 1 ] && [ "$1" = "exit" ]; then
    run_exit
fi

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


# Config ts location
config_ts_location=$(ini_parser timesheet location "$config_file")

# If theres a ts location in config, use it, else default
if [ -n "${config_ts_location}"]; then
    $ts_location="HOME/timesheets"
else
    $ts_location="${config_ts_location}"
fi

# Ask where you want timesheets saved
timesheet_location=$(zenity_text "Where would you like to write your timesheet files? Default: $HOME/timesheets" $ts_location)

# See if last popup was 'canceled'
test_cancel "$timesheet_location"

# If timesheet directory location isn't set, default it
if [ -z "$timesheet_location" ]; then
    timesheet_location="$HOME/timesheets"
fi

# Set timesheet file
timesheet="$timesheet_location/timesheet-$dstamp"

# Update config file
echo "[timesheet]" > "$config_file"
echo "location=$timesheet_location" >> "$config_file"
echo "active_timesheet=$timesheet" >> "$config_file"

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

# Config ts frerquency
config_ts_freq=$(ini_parser timesheet frequency "$config_file")

# If theres a ts location in config, use it, else default
if [ -n "${config_ts_freq}"]; then
    $ts_freq="15"
else
    $ts_freq="${config_ts_freq}"
fi
# Ask how often you want to be prompted
frequency=$(zenity_text "How often should I ask you (in minutes)? Default: 15" "${ts_freq}")

# See if last popup was 'canceled'
test_cancel "$frequency"

#  If frequency not explicitly set, default it
if [ -z "$frequency" ]; then
    frequency=15
fi

# update config files
echo "frequency=$frequency" >> "$config_file"

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