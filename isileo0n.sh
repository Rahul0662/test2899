#!/bin/bash

# Define the SNMP parameters
HOSTNAME="your_isilon_hostname_or_ip"
COMMUNITY="your_snmp_community"  # Usually "public" or configured SNMP community
OID_NODE_FAN_TABLE="1.3.6.1.4.1.12124.2.53.1"  # Replace with the actual NodeFanTable OID

# Define OIDs for fan description and fan speed (replace with actual OIDs if necessary)
OID_FAN_DESCRIPTION="1.3.6.1.4.1.12124.2.53.1.2.1.2"  # OID for fan description
OID_FAN_SPEED="1.3.6.1.4.1.12124.2.53.1.2.1.3"        # OID for fan speed

# Function to check SNMP response for fan data
check_fan_data() {
    echo "Checking fan data from $HOSTNAME using SNMP..."

    # Get fan descriptions
    echo "Fetching fan descriptions..."
    fan_descriptions=$(snmpwalk -v2c -c $COMMUNITY $HOSTNAME $OID_FAN_DESCRIPTION 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "Error fetching fan descriptions: $fan_descriptions"
        exit 1
    fi

    # Get fan speeds
    echo "Fetching fan speeds..."
    fan_speeds=$(snmpwalk -v2c -c $COMMUNITY $HOSTNAME $OID_FAN_SPEED 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "Error fetching fan speeds: $fan_speeds"
        exit 1
    fi

    # Print the results (for testing purposes)
    echo -e "\nFan Descriptions:"
    echo "$fan_descriptions"
    
    echo -e "\nFan Speeds (in RPM):"
    echo "$fan_speeds"

    # Process data (this is a placeholder, process as needed)
    # Example: parse the SNMP output and display fan status
    process_snmp_data "$fan_descriptions" "$fan_speeds"
}

# Function to process and correlate fan descriptions and speeds
process_snmp_data() {
    local descriptions="$1"
    local speeds="$2"

    # Convert descriptions and speeds into arrays
    IFS=$'\n' read -r -d '' -a description_array <<< "$descriptions"
    IFS=$'\n' read -r -d '' -a speed_array <<< "$speeds"

    echo -e "\nFan Status Report:"
    
    # Loop through descriptions and print the associated speed
    for i in "${!description_array[@]}"; do
        fan_desc=$(echo "${description_array[$i]}" | cut -d '=' -f 2 | xargs)  # Extract fan description
        fan_speed=$(echo "${speed_array[$i]}" | cut -d '=' -f 2 | xargs)      # Extract fan speed in RPM

        echo "Fan: $fan_desc - Speed: $fan_speed RPM"
    done
}

# Run the fan data check
check_fan_data
