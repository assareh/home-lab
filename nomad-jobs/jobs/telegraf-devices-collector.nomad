job "telegraf-devices-collector" {
  datacenters = ["dc1"]

  group "telegraf" {
    task "telegraf" {
      driver = "docker"

      config {
        network_mode = "host"
        image        = "telegraf:1.18.1-alpine"

        args = [
          "-config",
          "/local/telegraf.conf",
        ]
      }

      template {
        data = <<EOTC
# Telegraf Configuration
[global_tags]
  role = "castle"
  datacenter = "dc1"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://influxdb.service.consul:8086"] # required
  database = "telegraf" # required
  retention_policy = ""
  write_consistency = "any"
  timeout = "5s"
  username = "telegraf"
  password = "telegraf"

##
## SNMP Input Plugin
##

##
##  -- 'index_as_tag' on tables requires PR #2366 for support, part of current master branch tagged for 1.3 release
##  -- See https://github.com/influxdata/telegraf/issues/1948
##

##
## EdgeRouter devices
##
 [[inputs.snmp]]
   # List of agents to poll
   agents = [ "edgerouter.service.consul" ]
   # Polling interval
   interval = "60s"
   # Timeout for each SNMP query.
   timeout = "5s"
   # Number of retries to attempt within timeout.
   retries = 3
   # SNMP version, values can be 1, 2, or 3
   version = 2
   # SNMP community string.
   community = "dc1"
   # The GETBULK max-repetitions parameter
   max_repetitions = 50
   # Measurement name
   name = "snmp.EdgeOS"
   ##
   ## Exclusions
   ##
   # Don't want these columns from UCD-SNMP-MIB::laTable
   fielddrop = [ "laErrorFlag", "laErrMessage" ]
   # Don't want these rows from UCD-DISKIO-MIB::diskIOTable
   [inputs.snmp.tagdrop]
     diskIODevice = [ "loop*", "ram*" ]
   ## 
   ## System details
   ##
   #  System name (hostname)
   [[inputs.snmp.field]]
     name = "sysName"
     oid = "SNMPv2-MIB::sysName.0"
     is_tag = true
   #  System vendor OID
   [[inputs.snmp.field]]
     name = "sysObjectID"
     oid = "SNMPv2-MIB::sysObjectID.0"
   #  System description
   [[inputs.snmp.field]]
     name = "sysDescr"
     oid = "SNMPv2-MIB::sysDescr.0"
   #  System contact
   [[inputs.snmp.field]]
     name = "sysContact"
     oid = "SNMPv2-MIB::sysContact.0"
   #  System location
   [[inputs.snmp.field]]
     name = "sysLocation"
     oid = "SNMPv2-MIB::sysLocation.0"
   ##
   ## Host/System Resources
   ##
   #  System uptime
   [[inputs.snmp.field]]
     name = "sysUpTime"
     oid = "HOST-RESOURCES-MIB::hrSystemUptime.0"
   #  Number of user sessions
   [[inputs.snmp.field]]
     name = "hrSystemNumUsers"
     oid = "HOST-RESOURCES-MIB::hrSystemNumUsers.0"
   #  Number of process contexts
   [[inputs.snmp.field]]
     name = "hrSystemProcesses"
     oid = "HOST-RESOURCES-MIB::hrSystemProcesses.0"
   #  Device Listing
   [[inputs.snmp.table]]
     oid = "HOST-RESOURCES-MIB::hrDeviceTable"
     [[inputs.snmp.table.field]]
       oid = "HOST-RESOURCES-MIB::hrDeviceIndex"
       is_tag = true
   ##
   ## Context Switches & Interrupts
   ##
   #  Number of interrupts processed
   [[inputs.snmp.field]]
     name = "ssRawInterrupts"
     oid = "UCD-SNMP-MIB::ssRawInterrupts.0"
   #  Number of context switches
   [[inputs.snmp.field]]
     name = "ssRawContexts"
     oid = "UCD-SNMP-MIB::ssRawContexts.0"
   ##
   ## Host performance metrics
   ##
   #  System Load Average 
   [[inputs.snmp.table]]
     oid = "UCD-SNMP-MIB::laTable"
     [[inputs.snmp.table.field]]
       oid = "UCD-SNMP-MIB::laNames"
       is_tag = true
   ##
   ## CPU inventory
   ##
   #  Processor listing
   [[inputs.snmp.table]]
     index_as_tag = true
     oid = "HOST-RESOURCES-MIB::hrProcessorTable"
   ##
   ## CPU utilization
   ##
   #  Number of 'ticks' spent on user-level
   [[inputs.snmp.field]]
     name = "ssCpuRawUser"
     oid = "UCD-SNMP-MIB::ssCpuRawUser.0"
   #  Number of 'ticks' spent on reduced-priority
   [[inputs.snmp.field]]
     name = "ssCpuRawNice"
     oid = "UCD-SNMP-MIB::ssCpuRawNice.0"
   #  Number of 'ticks' spent on system-level
   [[inputs.snmp.field]]
     name = "ssCpuRawSystem"
     oid = "UCD-SNMP-MIB::ssCpuRawSystem.0"
   #  Number of 'ticks' spent idle
   [[inputs.snmp.field]]
     name = "ssCpuRawIdle"
     oid = "UCD-SNMP-MIB::ssCpuRawIdle.0"
   #  Number of 'ticks' spent waiting on I/O
   [[inputs.snmp.field]]
     name = "ssCpuRawWait"
     oid = "UCD-SNMP-MIB::ssCpuRawWait.0"
   #  Number of 'ticks' spent in kernel
   [[inputs.snmp.field]]
     name = "ssCpuRawKernel"
     oid = "UCD-SNMP-MIB::ssCpuRawKernel.0"
   #  Number of 'ticks' spent on hardware interrupts
   [[inputs.snmp.field]]
     name = "ssCpuRawInterrupt"
     oid = "UCD-SNMP-MIB::ssCpuRawInterrupt.0"
   #  Number of 'ticks' spent on software interrupts
   [[inputs.snmp.field]]
     name = "ssCpuRawSoftIRQ"
     oid = "UCD-SNMP-MIB::ssCpuRawSoftIRQ.0"
   ##
   ## System Memory (physical/virtual)
   ##
   #  Size of phsyical memory (RAM)
   [[inputs.snmp.field]]
     name = "hrMemorySize"
     oid = "HOST-RESOURCES-MIB::hrMemorySize.0"
   #  Size of real/phys mem installed
   [[inputs.snmp.field]]
     name = "memTotalReal"
     oid = "UCD-SNMP-MIB::memTotalReal.0"
   #  Size of real/phys mem unused/avail
   [[inputs.snmp.field]]
     name = "memAvailReal"
     oid = "UCD-SNMP-MIB::memAvailReal.0"
   #  Total amount of mem unused/avail
   [[inputs.snmp.field]]
     name = "memTotalFree"
     oid = "UCD-SNMP-MIB::memTotalFree.0"
   #  Size of mem used as shared memory
   [[inputs.snmp.field]]
     name = "memShared"
     oid = "UCD-SNMP-MIB::memShared.0"
   #  Size of mem used for buffers
   [[inputs.snmp.field]]
     name = "memBuffer"
     oid = "UCD-SNMP-MIB::memBuffer.0"
   #  Size of mem used for cache
   [[inputs.snmp.field]]
     name = "memCached"
     oid = "UCD-SNMP-MIB::memCached.0"
   ##
   ## Block (Disk) performance
   ##
   #  System-wide blocks written
   [[inputs.snmp.field]]
     name = "ssIORawSent"
     oid = "UCD-SNMP-MIB::ssIORawSent.0"
   #  Number of blocks read
   [[inputs.snmp.field]]
     name = "ssIORawReceived"
     oid = "UCD-SNMP-MIB::ssIORawReceived.0"
   #  Per-device (disk) performance
   [[inputs.snmp.table]]
     oid = "UCD-DISKIO-MIB::diskIOTable"
     [[inputs.snmp.table.field]]
       oid = "UCD-DISKIO-MIB::diskIODevice"
       is_tag = true
   ##
   ## Disk/Partition/Filesystem inventory & usage
   ##
   #  Storage listing
   [[inputs.snmp.table]]
     oid = "HOST-RESOURCES-MIB::hrStorageTable"
     [[inputs.snmp.table.field]]
       oid = "HOST-RESOURCES-MIB::hrStorageDescr"
       is_tag = true
   ##
   ## Interface metrics
   ##
   #  Per-interface traffic, errors, drops
   [[inputs.snmp.table]]
     oid = "IF-MIB::ifTable"
     [[inputs.snmp.table.field]]
       oid = "IF-MIB::ifName"
       is_tag = true
   #  Per-interface high-capacity (HC) counters
   [[inputs.snmp.table]]
     oid = "IF-MIB::ifXTable"
     [[inputs.snmp.table.field]]
       oid = "IF-MIB::ifName"
       is_tag = true
   ##
   ## IP metrics
   ##
   #  System-wide IP metrics
   [[inputs.snmp.table]]
     index_as_tag = true
     oid = "IP-MIB::ipSystemStatsTable"
   ## 
   ## ICMP Metrics
   ##
   #  ICMP statistics
   [[inputs.snmp.table]]
     index_as_tag = true
     oid = "IP-MIB::icmpStatsTable"
   #  ICMP per-type statistics
   [[inputs.snmp.table]]
     index_as_tag = true
     oid = "IP-MIB::icmpMsgStatsTable"
   ##
   ## UDP statistics
   ##
   #  Datagrams delivered to app
   [[inputs.snmp.field]]
     name = "udpInDatagrams"
     oid = "UDP-MIB::udpInDatagrams.0"
   #  Datagrams received with no app
   [[inputs.snmp.field]]
     name = "udpNoPorts"
     oid = "UDP-MIB::udpNoPorts.0"
   #  Datagrams received with error
   [[inputs.snmp.field]]
     name = "udpInErrors"
     oid = "UDP-MIB::udpInErrors.0"
   #  Datagrams sent
   [[inputs.snmp.field]]
     name = "udpOutDatagrams"
     oid = "UDP-MIB::udpOutDatagrams.0"
   ##
   ## TCP statistics
   ##
   #  Number of CLOSED -> SYN-SENT transitions
   [[inputs.snmp.field]]
     name = "tcpActiveOpens"
     oid = "TCP-MIB::tcpActiveOpens.0"
   #  Number of SYN-RCVD -> LISTEN transitions
   [[inputs.snmp.field]]
     name = "tcpPassiveOpens"
     oid = "TCP-MIB::tcpPassiveOpens.0"
   #  Number of SYN-SENT/RCVD -> CLOSED transitions
   [[inputs.snmp.field]]
     name = "tcpAttemptFails"
     oid = "TCP-MIB::tcpAttemptFails.0"
   #  Number of ESTABLISHED/CLOSE-WAIT -> CLOSED transitions
   [[inputs.snmp.field]]
     name = "tcpEstabResets"
     oid = "TCP-MIB::tcpEstabResets.0"
   #  Number of ESTABLISHED or CLOSE-WAIT
   [[inputs.snmp.field]]
     name = "tcpCurrEstab"
     oid = "TCP-MIB::tcpCurrEstab.0"
   #  Number of segments received
   [[inputs.snmp.field]]
     name = "tcpInSegs"
     oid = "TCP-MIB::tcpInSegs.0"
   #  Number of segments sent
   [[inputs.snmp.field]]
     name = "tcpOutSegs"
     oid = "TCP-MIB::tcpOutSegs.0"
   #  Number of segments retransmitted
   [[inputs.snmp.field]]
     name = "tcpRetransSegs"
     oid = "TCP-MIB::tcpRetransSegs.0"
   #  Number of segments received with error
   [[inputs.snmp.field]]
     name = "tcpInErrs"
     oid = "TCP-MIB::tcpInErrs.0"
   #  Number of segments sent w/RST
   [[inputs.snmp.field]]
     name = "tcpOutRsts"
     oid = "TCP-MIB::tcpOutRsts.0"
   ##
   ## IP routing statistics
   ##
   #  Number of valid routing entries
   [[inputs.snmp.field]]
     name = "inetCidrRouteNumber"
     oid = "IP-FORWARD-MIB::inetCidrRouteNumber.0"
   #  Number of valid entries discarded
   [[inputs.snmp.field]]
     name = "inetCidrRouteDiscards"
     oid = "IP-FORWARD-MIB::inetCidrRouteDiscards.0"
   #  Number of valid forwarding entries
   [[inputs.snmp.field]]
     name = "ipForwardNumber"
     oid = "IP-FORWARD-MIB::ipForwardNumber.0"
   ##
   ## IP routing statistics
   ##
   # Number of valid routes discarded
   [[inputs.snmp.field]]
     name = "ipRoutingDiscards"
     oid = "RFC1213-MIB::ipRoutingDiscards.0"
   ##
   ## SNMP metrics
   ##
   #  Number of SNMP messages received
   [[inputs.snmp.field]]
     name = "snmpInPkts"
     oid = "SNMPv2-MIB::snmpInPkts.0"
   #  Number of SNMP Get-Request received
   [[inputs.snmp.field]]
     name = "snmpInGetRequests"
     oid = "SNMPv2-MIB::snmpInGetRequests.0"
   #  Number of SNMP Get-Next received
   [[inputs.snmp.field]]
     name = "snmpInGetNexts"
     oid = "SNMPv2-MIB::snmpInGetNexts.0"
   #  Number of SNMP objects requested
   [[inputs.snmp.field]]
     name = "snmpInTotalReqVars"
     oid = "SNMPv2-MIB::snmpInTotalReqVars.0"
   #  Number of SNMP Get-Response received
   [[inputs.snmp.field]]
     name = "snmpInGetResponses"
     oid = "SNMPv2-MIB::snmpInGetResponses.0"
   #  Number of SNMP messages sent
   [[inputs.snmp.field]]
     name = "snmpOutPkts"
     oid = "SNMPv2-MIB::snmpOutPkts.0"
   #  Number of SNMP Get-Request sent
   [[inputs.snmp.field]]
     name = "snmpOutGetRequests"
     oid = "SNMPv2-MIB::snmpOutGetRequests.0"
   #  Number of SNMP Get-Next sent
   [[inputs.snmp.field]]
     name = "snmpOutGetNexts"
     oid = "SNMPv2-MIB::snmpOutGetNexts.0"
   #  Number of SNMP Get-Response sent
   [[inputs.snmp.field]]
     name = "snmpOutGetResponses"
     oid = "SNMPv2-MIB::snmpOutGetResponses.0"
EOTC

        destination = "local/telegraf.conf"
      }

      resources {
        cpu    = 20
        memory = 28
      }
    }
  }
}
