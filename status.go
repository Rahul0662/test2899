package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	// Open the file for reading
	file, err := os.Open("F:\\status.dat")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	// Create a scanner to read the file line by line
	scanner := bufio.NewScanner(file)

	// Initialize variables to hold the host_name, service_description, plugin_output, and current_state values
	var hostName string
	var serviceDesc string
	var pluginOutput string
	var currentState string

	// Loop through each line of the file
	for scanner.Scan() {
		line := scanner.Text()
		line = strings.TrimSpace(line)
		// Check if the line starts with "servicestatus {"
		if strings.HasPrefix(line, "servicestatus {") {
			// Reset the variables for a new service section
			hostName = ""
			serviceDesc = ""
			pluginOutput = ""
			currentState = ""

			// Loop through each line of the service section
			for scanner.Scan() {
				line := scanner.Text()
				line = strings.TrimSpace(line)
				//fmt.Println(line)
				// Check if the line is the end of the service section
				if line == "}" {
					// Print the values as a single line separated by commas
					fmt.Printf("%s,%s,%s,%s\n", hostName, serviceDesc, pluginOutput, currentState)
					break
				}

				// Extract the required values from the line
				if strings.HasPrefix(line, "host_name=") {
					hostName = strings.TrimPrefix(line, "host_name=")
				} else if strings.HasPrefix(line, "service_description=") {
					serviceDesc = strings.TrimPrefix(line, "service_description=")
				} else if strings.HasPrefix(line, "plugin_output=") {
					pluginOutput = strings.TrimPrefix(line, "plugin_output=")
				} else if strings.HasPrefix(line, "current_state=") {
					currentState = strings.TrimPrefix(line, "current_state=")
				}
			}
		}
	}

	// Check for any errors encountered while scanning the file
	if err := scanner.Err(); err != nil {
		panic(err)
	}
}
