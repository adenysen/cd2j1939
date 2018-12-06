#!/usr/bin/tclsh

source all_pgn.tcl

proc pglist_unpack_item {} {
	uplevel {set pgn	[lindex $item 0]}
	uplevel {set pg_label	[lindex $item 1]}
	uplevel {set pg_name	[lindex $item 2]}
	uplevel {set pg_desc	[lindex $item 3]}
	uplevel {set edp	[lindex $item 4]}
	uplevel {set dp		[lindex $item 5]}
	uplevel {set pf		[lindex $item 6]}
	uplevel {set ps		[lindex $item 7]}
	uplevel {set multipkt	[lindex $item 8]}
	uplevel {set txrate	[lindex $item 9]}
	uplevel {set datalen	[lindex $item 10]}
	uplevel {set priority	[lindex $item 11]}
	uplevel {set spn	[lindex $item 12]}
}

proc splist_unpack_item {} {
	uplevel {set sp_pos	[lindex $item 0]}
	uplevel {set spn	[lindex $item 1]}
	uplevel {set sp_label	[lindex $item 2]}
	uplevel {set sp_desc	[lindex $item 3]}
	uplevel {set sp_length	[lindex $item 4]}
	uplevel {set resolution	[lindex $item 5]}
	uplevel {set offset	[lindex $item 6]}
	uplevel {set datrange	[lindex $item 7]}
	uplevel {set operange	[lindex $item 8]}
	uplevel {set units	[lindex $item 9]}
	uplevel {set slot_id	[lindex $item 10]}
	uplevel {set slot_name	[lindex $item 11]}
	uplevel {set len	[lindex $item 12]}
	uplevel {set pos	[lindex $item 13]}
	uplevel {set mask	[lindex $item 14]}
	uplevel {set shift	[lindex $item 15]}
	uplevel {set hex	[lindex $item 16]}
}

proc generate_pg_report {item} {
	pglist_unpack_item
	puts $::dbg [format "%5d %s  %s" $pgn $pg_name $pg_label]
	foreach y $spn {
		generate_sp_report $y
	}
}

proc generate_sp_report {item} {
	splist_unpack_item
	puts $::dbg [format "\t%5d bitpos=%2d bitlen=%2d {%7s %6s} %s" \
			$spn $pos $len $sp_length $sp_pos $sp_label]
}

set ::debug_outfile "j1939.txt"
set ::dbg [open $debug_outfile "w"]

foreach x $::all_pgn {
	generate_pg_report $x
}

close $::dbg
