#!/bin/sh

cd /wayd/ && sudo ./install.sh

if [ $? -ne 0 ]; then
    echo "ERROR: Cannot install WAYD"
fi

whatareyoudoing

if [ $? -ne 0 ]; then
    echo "ERROR: Cannot run WAYD"
fi