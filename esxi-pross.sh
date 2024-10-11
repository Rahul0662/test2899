#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <server> <snmpv2string> <processname>"
    exit 1
fi

# Command-line arguments
SNMP_SERVER=$1         # Server name or IP address
SNMP_COMMUNITY=$2      # SNMP community string
PROCESS_NAME=$3        # The process name to check for

# Thresholds for warning and critical alerts
WARNING_THRESHOLD=50
CRITICAL_THRESHOLD=100

# Check if SNMP tools are installed
if ! command -v snmpwalk &> /dev/null
then
    echo "Error: snmpwalk not found. Please install SNMP tools."
    exit 2
fi

# Perform SNMP walk to get all running processes
process_list=$(snmpwalk -v2c -c $SNMP_COMMUNITY -On $SNMP_SERVER 1.3.6.1.2.1.25.4.2.1.2 | grep -i "$PROCESS_NAME")

# Check if process is running
if [[ -z "$process_list" ]]; then
    echo "CRITICAL: Process '$PROCESS_NAME' not found via SNMP on server '$SNMP_SERVER'!"
    exit 2
else
    # If the process is found, print its details
    echo "OK: Process '$PROCESS_NAME' is running on server '$SNMP_SERVER'. Details:"
    echo "$process_list"
    
    # Optionally: Add a count for multiple instances and warning/critical thresholds
    process_count=$(echo "$process_list" | wc -l)
    
    if [ "$process_count" -ge "$CRITICAL_THRESHOLD" ]; then
        echo "CRITICAL: More than $CRITICAL_THRESHOLD instances of '$PROCESS_NAME' found!"
        exit 2
    elif [ "$process_count" -ge "$WARNING_THRESHOLD" ]; then
        echo "WARNING: More than $WARNING_THRESHOLD instances of '$PROCESS_NAME' found!"
        exit 1
    else
        echo "OK: Process count is within limits."
        exit 0
    fi
fi
