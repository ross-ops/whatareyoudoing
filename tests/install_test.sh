#!/bin/sh

../install.sh

if [ $@ -ne 0 ]; then
    echo "ERROR: Cannot install WAYD"
fi