# What Are You Doing
WAYD is a zenity based shell script that asks 'What Are You Doing?' at a user defined interval. 
It timestamps this information and writes it to a user defined directory, in a timesheet file named with todays date.
It autostarts on sourcing your shell config, unless it's already running (using a lockfile deleted on exit). 
This effectively means this will trigger when you first open your terminal, or a new tab (pretty good bet in our line of work).

Run `./install.sh` and re-source your shell config, and you're cooking.

To exit WAYD (e.g at the end of the day), run `whatareyoudoing exit` from your terminal.

TODO:

    - icon doesn't work
   
    - some integration with WRMS may be possible (tks)
   
    - if left running, would like to quit if day rolls
