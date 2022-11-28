#Create a simulator object
set ns [new Simulator]
# Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf
#Define a 'finish' procedure
proc finish {} {
	global qmon0 qmon1 qmon2 qmon3 qmon4 qmon5
	set parr0 [$qmon0 set parrivals_]
	puts "s1 to G : $parr0"
	set parr1 [$qmon1 set parrivals_]
	puts "s2 to G : $parr1"
	set parr2 [$qmon2 set parrivals_]
	puts "s3 to G : $parr2"
	set parr3 [$qmon3 set parrivals_]
	puts "s4 to G : $parr3"
	set parr4 [$qmon4 set parrivals_]
	puts "G to r : $parr4" 
	set bdrop [$qmon0 set bdrops_]
	puts "s1 to G : $bdrop"
	set bdrop [$qmon1 set bdrops_]
	puts "s2 to G : $bdrop"
	set bdrop [$qmon2 set bdrops_]
	puts "s3 to G : $bdrop"
	set bdrop [$qmon3 set bdrops_]
	puts "s4 to G : $bdrop"
	set bdrop [$qmon4 set bdrops_]
	puts "G to r : $bdrop" 
	global ns nf
	$ns flush-trace
	
	# Close the NAM trace file
	close $nf
	
	# Execute NAM on the trace file
	exec nam out.nam &
	exit 0
}
#global variables
set mpktsize 1460

#Create four nodes
set s1 [$ns node]
set s2 [$ns node]
set G [$ns node]
set r [$ns node]
set s3 [$ns node]
set s4 [$ns node]
#Create links between the nodes
$ns duplex-link $s1 $G 100Mb 10ms DropTail
$ns duplex-link $s2 $G 100Mb 40ms DropTail
$ns duplex-link $r $G 10Mb 10ms DropTail
$ns duplex-link $s3 $G 100Mb 70ms DropTail
$ns duplex-link $s4 $G 100Mb 100ms DropTail

$ns queue-limit $s1 $G 1000
$ns queue-limit $s2 $G 1000
$ns queue-limit $s3 $G 1000
$ns queue-limit $s4 $G 1000
$ns queue-limit $G $r 1000

Agent/TCP instproc done {} {
	 global nssim freelist reslist ftp rng mfsize mean_intarrtime nof_tcps simstart	simend delres nlist mm starttime temp
	 #the global variables nssim (ns simulator instance), ftp (application),
	 #rng (random number generator), simstart (start time of the simulation) and
	 #simend (ending time of the simulation) have to be created by the user in
	 #the main program
	 #flow-ID of the TCP flow
	 set flind [$self set fid_]
	 #the class is determined by the flow-ID and total number of tcp-sources
	 set class [expr int(floor($flind/$nof_tcps))]
	 set ind [expr $flind-$class*$nof_tcps]
	 lappend nlist($class) [list [$nssim now] [llength $reslist($class)]]
	 for {set nn 0} {$nn < [llength $reslist($class)]} {incr nn} {
		 set tmp [lindex $reslist($class) $nn]
		 set tmpind [lindex $tmp 0]
		 if {$tmpind == $ind} { 
			 set mm $nn
			 set starttime [lindex $tmp 1]
		 }
	 }
	 set reslist($class) [lreplace $reslist($class) $mm $mm]
	 lappend freelist($class) $ind
	 set tt [$nssim now]
	 if {$starttime > $simstart && $tt < $simend} {
	 	lappend delres($class) [expr $tt-$starttime]
	 }
	 if {$tt > $simend} {
	 	$nssim at $tt "$nssim halt"
	 }
}



set temp 0

set tcp1 [new Agent/TCP]
$ns attach-agent $s1 $tcp1
$tcp1 set window_ 1000
$tcp1 set packetSize_ $mpktsize

set temp 1

set tcp2 [new Agent/TCP]
$ns attach-agent $s2 $tcp2
$tcp2 set window_ 1000
$tcp2 set packetSize_ $mpktsize

set temp 2

set tcp3 [new Agent/TCP]
$ns attach-agent $s3 $tcp3
$tcp3 set window_ 1000
$tcp3 set packetSize_ $mpktsize

set temp 3

set tcp4 [new Agent/TCP]
$ns attach-agent $s4 $tcp4
$tcp4 set window_ 1000
$tcp4 set packetSize_ $mpktsize

set temp 4

set sink1 [new Agent/TCPSink]
set sink2 [new Agent/TCPSink]
set sink3 [new Agent/TCPSink]
set sink4 [new Agent/TCPSink]
$ns attach-agent $r $sink1
$ns attach-agent $r $sink2
$ns attach-agent $r $sink3
$ns attach-agent $r $sink4

$ns connect $tcp1 $sink1
$ns connect $tcp2 $sink2
$ns connect $tcp3 $sink3
$ns connect $tcp4 $sink4

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
set ftp3 [new Application/FTP]
$ftp3 attach-agent $tcp3
set ftp4 [new Application/FTP]
$ftp4 attach-agent $tcp4


set loss_random_variable [new RandomVariable/Uniform]
$loss_random_variable set min_ 0 
$loss_random_variable set max_ 100
set loss_module [new ErrorModel] 
$loss_module drop-target [new Agent/Null] 
$loss_module set rate_ 1
# error rate will then be (0.001 = 1 / (1000 - 0));
$loss_module ranvar $loss_random_variable  

$ns lossmodel $loss_module $G $r

#global equations
set mpktsize 1460
set nssim [Simulator instance]
set simend 1.5
set mm 0
set starttime 0
set simstart 0.5
#This code contains methods for flow generation and result recording.
# the total (theoretical) load in the bottleneck link
set rho 0.8
puts "rho = $rho"
# Filetransfer parameters
set mfsize 500
# bottleneck bandwidth, required for setting the load
set bnbw 10000000
set nof_tcps 100 
set nof_classes 4 
set rho_cl [expr $rho/$nof_classes] 
puts "rho_cl=$rho_cl, nof_classes=$nof_classes"
set mean_intarrtime [expr ($mpktsize+40)*8.0*$mfsize/($bnbw*$rho_cl)]
#flow interarrival time
puts "1/la = $mean_intarrtime"
for {set ii 0} {$ii < $nof_classes} {incr ii} {
	 set delres($ii) {} 
	 #contains the delay results for each class
	 set nlist($ii) {} 
	 #contains the number of active flows as a function of time
	 set freelist($ii) {} 
	 #contains the free flows
	 set reslist($ii) {} 
	 #contains information of the reserved flows
}


proc start_flow {class} {
 	global nssim freelist reslist ftp tcp_ tcp_d rng nof_tcps mfsize mean_intarrtime simend
	 #you have to create the variables tcp_s (tcp source) and tcp_d (tcp destination)
	 set tt [$nssim now]
	 set freeflows [llength $freelist($class)]
	 set resflows [llength $reslist($class)]
	 lappend nlist($class) [list $tt $resflows]
	 if {$freeflows == 0} {
		 puts "Class $class: At $tt, nof of free TCP sources == 0!!!"
		 puts "freelist($class)=$freelist($class)"
		 puts "reslist($class)=$reslist($class)"
		 exit
		 
	 }
 #take the first index from the list of free flows
	 set ind [lindex $freelist($class) 0]
	 set cur_fsize [expr ceil([$rng exponential $mfsize])]
	 $tcp_s($class,$ind) reset
	 $tcp_d($class,$ind) reset
	 $ftp($class,$ind) produce $cur_fsize
	 set freelist($class) [lreplace $freelist($class) 0 0]
	 lappend reslist($class) [list $ind $tt $cur_fsize]
	 set newarrtime [expr $tt+[$rng exponential $mean_intarrtime]]
	 $nssim at $newarrtime "start_flow $class"
	 if {$tt > $simend} {
	 	$nssim at $tt "$nssim halt"
	 }
}
set parr_start 0
set pdrops_start 0 
proc record_start {} {
	 global fmon_bn nssim parr_start pdrops_start nof_classes
	 #you have to create the fmon_bn (flow monitor) in the bottleneck link
	 set parr_start [$fmon_bn set parrivals_]
	 set pdrops_start [$fmon_bn set pdrops_]
	 puts "Bottleneck at [$nssim now]: arr=$parr_start, drops=$pdrops_start"
}
set parr_end 0
set pdrops_end 0
proc record_end { } {
	 global fmon_bn nssim parr_start pdrops_start nof_classes
	 set parr_start [$fmon_bn set parrivals_]
	 set pdrops_start [$fmon_bn set pdrops_]
	 puts "Bottleneck at [$nssim now]: arr=$parr_start, drops=$pdrops_start"
}

set qmon0 [$ns monitor-queue $s1 $G ""] 
set qmon1 [$ns monitor-queue $s2 $G ""] 
set qmon2 [$ns monitor-queue $s3 $G ""] 
set qmon3 [$ns monitor-queue $s4 $G ""] 
set qmon4 [$ns monitor-queue $G $r ""] 
set fmon_bn [$ns monitor-queue $G $r ""] 

set parr [$qmon0 set parrivals_]
puts "$parr"

set bdrop [$qmon0 set bdrops_]
puts "$bdrop" 
#Schedule events for the CBR agents
$ns at 0.0 "record_start"

$ns at 1.5 "record_end"
$ns at 0.1 "start_flow 0"


$ns at 1.75 "finish"
$ns run

