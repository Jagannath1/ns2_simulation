#Create a simulator object
set ns [new Simulator]
# Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf
#Define a 'finish' procedure
proc finish {} {
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

set tcp1 [new Agent/TCP/Reno]
$ns attach-agent $s1 $tcp1
$tcp1 set window_ 1000
$tcp1 set packetSize_ $mpktsize
$tcp1 set fid_ 1


set tcp2 [new Agent/TCP/Reno]
$ns attach-agent $s2 $tcp2
$tcp1 set window_ 1000
$tcp1 set packetSize_ $mpktsize
$tcp2 set fid_ 2

set tcp3 [new Agent/TCP/Reno]
$ns attach-agent $s3 $tcp3
$tcp1 set window_ 1000
$tcp1 set packetSize_ $mpktsize
$tcp3 set fid_ 3

set tcp4 [new Agent/TCP/Reno]
$ns attach-agent $s4 $tcp4
$tcp1 set window_ 1000
$tcp1 set packetSize_ $mpktsize
$tcp3 set fid_ 4


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
$loss_random_variable set max_ 1000
set loss_module [new ErrorModel] 
$loss_module drop-target [new Agent/Null] 
$loss_module set rate_ 1 
# error rate will then be (0.001 = 1 / (1000 - 0));
$loss_module ranvar $loss_random_variable  

$ns lossmodel $loss_module $G $r

#global equations


#Schedule events for the CBR agents
$ns at 0.1 "$ftp1 start"
$ns at 0.1 "$ftp2 start"
$ns at 0.1 "$ftp3 start"
$ns at 0.1 "$ftp4 start"

#$ns at 0.1 "$ftp1 start"
#$ns at 0.1 "$ftp2 start"
#$ns at 0.1 "$ftp3 start"
#$ns at 0.1 "$ftp4 start"
$ns at 5.0 "$ftp1 stop"
$ns at 5.0 "$ftp2 stop"
$ns at 5.0 "$ftp3 stop"
$ns at 5.0 "$ftp4 stop"
$ns at 5.25 "finish"
$ns run

