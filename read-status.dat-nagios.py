with open('/usr/local/nagios/var/status.dat', 'r') as f:
    content = f.read()

# Find all instances of servicestatus and loop over them
start = 0
while True:
    service_start = content.find('servicestatus {', start)
    if service_start == -1:
        break
    service_end = content.find('}', service_start)
    service_section = content[service_start:service_end]

    # Extract the host_name, service_description, plugin_output, and current_state values
    host_name_start = service_section.find('host_name=') + len('host_name=')
    host_name_end = service_section.find('\n', host_name_start)
    host_name = service_section[host_name_start:host_name_end].strip()

    service_desc_start = service_section.find('service_description=') + len('service_description=')
    service_desc_end = service_section.find('\n', service_desc_start)
    service_desc = service_section[service_desc_start:service_desc_end].strip()

    plugin_output_start = service_section.find('plugin_output=') + len('plugin_output=')
    plugin_output_end = service_section.find('\n', plugin_output_start)
    plugin_output = service_section[plugin_output_start:plugin_output_end].strip()

    current_state_start = service_section.find('current_state=') + len('current_state=')
    current_state_end = service_section.find('\n', current_state_start)
    current_state = service_section[current_state_start:current_state_end].strip()

    # Print the host_name, service_description, plugin_output, and current_state values in a single line
    print(host_name + ',' + service_desc + ',' + plugin_output + ',' + current_state)

    # Update the start index for the next iteration
    start = service_end
