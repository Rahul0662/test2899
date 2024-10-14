use Net::SNMP;

# Set timeout and retries
my $timeout = 60; # Set to 60 seconds
my $retries = 10;  # Set to a higher number of retries

# Enable SNMP debugging
Net::SNMP->debug(1);  # This will print debug info to STDERR

# Create the SNMP session with increased timeout and retries
my ($session, $error) = Net::SNMP->session(
    -hostname  => 'your_isilon_hostname_or_ip',  # Replace with your hostname or IP
    -community => 'your_snmp_community',          # Replace with your SNMP community
    -version   => 2,                               # SNMP version
    -timeout   => $timeout,                        # Set the timeout here
    -retries   => $retries                         # Set the retries here
);

# Check if the session was created successfully
if (!defined $session) {
    die "Error creating SNMP session: $error";
}

# Perform SNMP get_table operation
my $result = $session->get_table(-baseoid => $baseoid);

# Check for errors after the get_table call
if (!defined $result) {
    die "SNMP get_table error: " . $session->error();
}

# Continue with your logic...
