package main

// created by manish choudhary to automate task

import (
	"bufio"
	"encoding/base64"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
)

var globalMyStruct MyStruct
var globalClient1 ssh.Client
var globalClient2 ssh.Client
var currentServer = ""

const (
	sshPort = 22
	timeout = 10 * time.Second
	server1 = "192.168.1.31"
	server2 = "192.168.1.31"
	clapi   = "path"
	user1   = "nagiosadmin"
	user2   = "root"
	pass1   = "bmFnaW9zYWRtaW4="
	pass2   = "bWFuaXNoQDEyMzQ1"
)

type MyStruct struct {
	currentUnixTime        int64
	startUnixTime          int64
	endUnixTime            int64
	maintenanceType        string
	comments               string
	fileName               string
	fileList               []string
	centreon1HostList      []string
	centreon2HostList      []string
	centreon1HostgroupList []string
	centreon2HostgroupList []string
	foundServers           map[string]string
	foundHostgroup         map[string]string
	notFoundServers        []string
	notFoundHostgroup      []string
}

func checkInput() {
	hostname, _ := os.Hostname()
	username := os.Getenv("USER")
	deviceDetails := "( " + hostname + "/" + username + " )"
	startDate := flag.String("s", "", "start date")
	endDate := flag.String("e", "", "end date")
	fileName := flag.String("f", "empty", "filename")
	maintenanceType := flag.String("t", "", "maintenanceType")
	comments := flag.String("c", "", "comments")
	flag.Parse()

	start, err := time.Parse("2006-01-02 15:04:05", *startDate)
	if err != nil {
		fmt.Println("Error parsing start date:", err)
		myExit()
	}
	end, err := time.Parse("2006-01-02 15:04:05", *endDate)
	if err != nil {
		fmt.Println("Error parsing end date:", err)
		myExit()
	}

	if start.Unix() >= end.Unix() {
		fmt.Println("Start time must be less than end time")
		myExit()
	}

	now := time.Now()
	globalMyStruct.currentUnixTime = now.Unix()
	globalMyStruct.startUnixTime = start.Unix()
	globalMyStruct.endUnixTime = end.Unix()
	globalMyStruct.comments = *comments + deviceDetails
	filename := *fileName

	if _, err := os.Stat(filename); os.IsNotExist(err) {
		fmt.Printf("File %s does not exist\n", filename)
		myExit()
	}

	file, err := os.Open(filename)
	if err != nil {
		fmt.Printf("Error opening file %s: %s\n", filename, err)
		myExit()
	}
	defer file.Close()
	defer file.Close()

	fileInfo, err := file.Stat()
	if err != nil {
		fmt.Printf("Error getting file information: %s\n", err)
		myExit()
	}
	if fileInfo.Size() == 0 {
		fmt.Printf("File %s is empty\n", filename)
		myExit()
	}

	if *maintenanceType == "HOST" {
		globalMyStruct.maintenanceType = "HOST"
	} else if *maintenanceType == "HOSTGROUP" {
		globalMyStruct.maintenanceType = "HOSTGROUP"
	} else {
		fmt.Println(" invalid :  -t does not match 'HOST' or 'HOSTGROUP'")
		myExit()
	}

	globalMyStruct.fileName = *fileName

	verifySSHConnectivity()

	fmt.Println("Start Date:", start)
	fmt.Println("End Date:", end)
	fmt.Println("File Name:", *fileName)
	fmt.Println("Maintenance Type:", *maintenanceType)
	fmt.Println("")
}

func verifySSHConnectivity() {

	if !isPortOpen(server1, sshPort) {
		fmt.Printf("SSH port is closed on server 1 (%s)\n", server1)
		myExit()
	}

	if !isPortOpen(server2, sshPort) {
		fmt.Printf("SSH port is closed on server 2 (%s)\n", server2)
		myExit()
	}
}

func isPortOpen(ip string, port int) bool {
	addr := net.JoinHostPort(ip, strconv.Itoa(port))
	conn, err := net.DialTimeout("tcp", addr, timeout)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func myExit() {
	os.Exit(3)
}

func main() {

	globalMyStruct = MyStruct{
		currentUnixTime:        0,
		startUnixTime:          0,
		endUnixTime:            0,
		maintenanceType:        "",
		fileName:               "",
		comments:               "",
		fileList:               []string{},
		centreon1HostList:      []string{},
		centreon2HostList:      []string{},
		centreon1HostgroupList: []string{},
		centreon2HostgroupList: []string{},
		foundServers:           make(map[string]string),
		foundHostgroup:         make(map[string]string),
		notFoundServers:        []string{},
		notFoundHostgroup:      []string{},
	}
	checkInput()
	readFile()
	globalClient1 = getClient(server1)
	globalClient2 = getClient(server2)

	defer globalClient1.Close()
	defer globalClient2.Close()

	if globalMyStruct.maintenanceType == "HOST" {
		fetchDeviceDetails("Host")
	} else {
		fetchDeviceDetails("HG")
	}
}

func fetchDeviceDetails(t string) {
	p := decode(pass1)
	cmd := fmt.Sprintf("%s  -u %s -p %s -o %s -a show", clapi, user1, p, t)
	getListDetails(cmd)
	processDetails()
	checkMaintenance()

}

func decode(encoded string) string {
	b, _ := base64.StdEncoding.DecodeString(encoded)
	return string(b)
}

func getListDetails(cmd string) {
	cmdList := []string{cmd}

	currentServer = "server1"
	executeCode(globalClient1, cmdList, "get")
	currentServer = "server2"
	executeCode(globalClient2, cmdList, "get")
	currentServer = ""
}

func processDetails() {

	if globalMyStruct.maintenanceType == "HOST" {

		for _, server := range globalMyStruct.fileList {
			if contains(globalMyStruct.centreon1HostList, server) {
				globalMyStruct.foundServers[server] = "server1"
			} else if contains(globalMyStruct.centreon2HostList, server) {
				globalMyStruct.foundServers[server] = "server2"
			} else {
				globalMyStruct.notFoundServers = append(globalMyStruct.notFoundServers, server)
			}
		}
	} else {

		for _, group := range globalMyStruct.fileList {
			if contains(globalMyStruct.centreon1HostgroupList, group) {
				globalMyStruct.foundHostgroup[group] = "server1"
			} else if contains(globalMyStruct.centreon2HostgroupList, group) {
				globalMyStruct.foundHostgroup[group] = "server2"
			} else {
				globalMyStruct.notFoundHostgroup = append(globalMyStruct.notFoundHostgroup, group)
			}
		}
	}
}
func contains(slice []string, value string) bool {
	for _, item := range slice {
		if item == value {
			return true
		}
	}
	return false
}

func getClient(hostname string) ssh.Client {
	config := &ssh.ClientConfig{
		User: user2,
		Auth: []ssh.AuthMethod{
			ssh.Password(decode(pass2)),
		},
		HostKeyCallback: func(hostname string, remote net.Addr, key ssh.PublicKey) error {
			return nil
		},
	}
	client, err := ssh.Dial("tcp", hostname+":"+strconv.Itoa(sshPort), config)
	if err != nil {
		log.Fatalf("Failed to dial : %s , %s", err, hostname)
		myExit()
	}
	return *client
}

func executeCode(client ssh.Client, cmdList []string, inType string) {
	session, err := client.NewSession()
	if err != nil {
		fmt.Println("Failed to create session: ", err)
		os.Exit(1)
	}
	if inType == "get" {
		output, _ := session.CombinedOutput(cmdList[0])
		breakCentreonData(output)
	} else {
		return
	}

	session.Close()
}

func breakCentreonData(output []uint8) {
	var centreonServerList []string
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	scanner.Scan()
	for scanner.Scan() {
		line := scanner.Text()
		columns := strings.Split(line, ";")
		centreonServerList = append(centreonServerList, columns[1])
	}

	if currentServer == "server1" && globalMyStruct.maintenanceType == "HOST" {
		globalMyStruct.centreon1HostList = append(globalMyStruct.centreon1HostList, centreonServerList...)
	} else if currentServer == "server2" && globalMyStruct.maintenanceType == "HOST" {
		globalMyStruct.centreon2HostList = append(globalMyStruct.centreon2HostList, centreonServerList...)
	} else if currentServer == "server1" && globalMyStruct.maintenanceType == "HOSTGROUP" {
		globalMyStruct.centreon1HostgroupList = append(globalMyStruct.centreon1HostgroupList, centreonServerList...)
	} else if currentServer == "server2" && globalMyStruct.maintenanceType == "HOSTGROUP" {
		globalMyStruct.centreon2HostgroupList = append(globalMyStruct.centreon2HostgroupList, centreonServerList...)
	}

}

func readFile() {
	globalMyStruct.fileList = globalMyStruct.fileList[:0]
	file, _ := os.Open(globalMyStruct.fileName)

	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		server := scanner.Text()
		server = strings.TrimSpace(server)
		globalMyStruct.fileList = append(globalMyStruct.fileList, server)
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading file:", err)
		myExit()
	}
}

func checkMaintenance() {

	var server1cmdList []string
	var server2cmdList []string

	if globalMyStruct.maintenanceType == "HOST" {
		for k, v := range globalMyStruct.foundServers {
			if v == "server1" {
				server1cmdList = append(server1cmdList, getHostcmd(k)...)
			} else {
				server2cmdList = append(server2cmdList, getHostcmd(k)...)
			}
		}
	} else {
		for k, v := range globalMyStruct.foundHostgroup {
			if v == "server1" {
				server1cmdList = append(server1cmdList, getHGcmd(k)...)
			} else {
				server2cmdList = append(server2cmdList, getHGcmd(k)...)
			}
		}
	}

	if len(server1cmdList) > 0 {
		currentServer = "server1"
		runDowntime(server1cmdList)
	}
	if len(server2cmdList) > 0 {
		currentServer = "server2"
		runDowntime(server2cmdList)
	}
}

func getHostcmd(k string) []string {
	commandFile := "/var/log/nagios/rw/nagios.cmd"
	var cmdlist []string
	ScheduleHostDowntime := fmt.Sprintf(" echo \" [%d] SCHEDULE_HOST_DOWNTIME;%s;%d;%d;1;0;7200;%s;%s \" >> %s", globalMyStruct.currentUnixTime, k, globalMyStruct.startUnixTime, globalMyStruct.endUnixTime, user1, globalMyStruct.comments, commandFile)
	ScheduleHostSvcDowntime := fmt.Sprintf(" echo \" [%d] SCHEDULE_HOST_SVC_DOWNTIME;%s;%d;%d;1;0;7200;%s;%s \" >> %s", globalMyStruct.currentUnixTime, k, globalMyStruct.startUnixTime, globalMyStruct.endUnixTime, user1, globalMyStruct.comments, commandFile)
	cmdlist = append(cmdlist, ScheduleHostDowntime)
	cmdlist = append(cmdlist, ScheduleHostSvcDowntime)
	return cmdlist

}

func getHGcmd(k string) []string {
	var cmdlist []string
	commandFile := "/var/log/nagios/rw/nagios.cmd"
	ScheduleHostgroupHostDowntime := fmt.Sprintf(" echo \" [%d] SCHEDULE_HOSTGROUP_HOST_DOWNTIME;%s;%d;%d;1;0;7200;%s;%s \" >> %s", globalMyStruct.currentUnixTime, k, globalMyStruct.startUnixTime, globalMyStruct.endUnixTime, user1, globalMyStruct.comments, commandFile)
	ScheduleHostgroupSvcDowntime := fmt.Sprintf(" echo \" [%d] SCHEDULE_HOSTGROUP_SVC_DOWNTIME;%s;%d;%d;1;0;7200;%s;%s \" >> %s", globalMyStruct.currentUnixTime, k, globalMyStruct.startUnixTime, globalMyStruct.endUnixTime, user1, globalMyStruct.comments, commandFile)
	cmdlist = append(cmdlist, ScheduleHostgroupHostDowntime)
	cmdlist = append(cmdlist, ScheduleHostgroupSvcDowntime)
	return cmdlist
}

func runDowntime(cmds []string) {

	if currentServer == "server1" {

		for _, cmd := range cmds {
			session, _ := globalClient1.NewSession()
			output, err := session.CombinedOutput(cmd)
			if err != nil {
				log.Fatal(err)
			}
			fmt.Println(string(output))
			session.Close()
		}

	} else {

		for _, cmd := range cmds {
			session, _ := globalClient2.NewSession()
			output, err := session.CombinedOutput(cmd)
			if err != nil {
				log.Fatal(err)
			}
			fmt.Println(string(output))
			session.Close()
		}

	}
}

//  fmt.Println(reflect.TypeOf(session))
