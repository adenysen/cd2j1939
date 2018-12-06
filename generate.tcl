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

#
# C Language
#
proc ccode_header {fd} {
	puts $fd "#ifndef HAVE_J1939_REG_H"
	puts $fd "#define HAVE_J1939_REG_H"
	puts $fd ""
	puts $fd "#include <stdint.h>"
	puts $fd "#include <stdio.h>"
	puts $fd ""
	puts $fd [format "#define %-16s %s" "PF_MASK"  "0xff"]
	puts $fd [format "#define %-16s %s" "PF_SHIFT" "16"]
	puts $fd [format "#define %-16s %s" "PS_MASK"  "0xff"]
	puts $fd [format "#define %-16s %s" "PS_SHIFT" "8"]
}

proc ccode_footer {fd} {
	puts $fd ""
	puts $fd "struct j1939_msg {"
	puts $fd "\tunsigned int type;"
	puts $fd "\tunion {"
	foreach item $::all_pgn {
		pglist_unpack_item
		set tmp [string tolower $pg_name]
		puts $fd [format "\t\tstruct %s %s;" $tmp $tmp]
	}
	puts $fd "\t};"
	puts $fd "};"
	puts $fd ""
	puts $fd "int j1939_decode(unsigned int type, uint64_t data, struct j1939_msg *msg);"
	puts $fd "void j1939_print(FILE *fp, struct j1939_msg *msg);"
	puts $fd ""
	puts $fd "#endif"
}

proc ccode_visit_pgn {fd item} {
	pglist_unpack_item
	puts $fd ""
	puts $fd "// $pg_label"
	puts $fd ""
	puts $fd [format "#define %-16s %d" $pg_name $pgn]
	puts $fd ""
	foreach y $spn {
		ccode_visit_spn_mask $fd $y
	}
	puts $fd ""
	puts $fd "struct [string tolower $pg_name] {"
	foreach y $spn {
		ccode_visit_spn_field $fd $y
	}
	puts $fd "};"
}

proc ccode_visit_spn_field {fd item} {
	splist_unpack_item
	set word [expr int(($len + 7) / 8)]
	if {$word == 3} {
		incr word
	} elseif {$word > 4} {
		set word 8
	}
	set word [expr $word * 8]
	puts $fd [format "\tuint%d_t spn%d;" $word $spn]
}

proc ccode_visit_spn_mask {fd item} {
	splist_unpack_item
	puts $fd [format "#define %-16s 0x%x" $mask $hex]
	puts $fd [format "#define %-16s %d" $shift $pos]
}

#
# Plain text report
#
proc report_visit_pgn {fd item} {
	pglist_unpack_item
	puts $fd [format "%5d %s  %s" $pgn $pg_name $pg_label]
	foreach y $spn {
		report_visit_spn $fd $y
	}
}

proc report_visit_spn {fd item} {
	splist_unpack_item
	puts $fd [format "\t%5d bitpos=%2d bitlen=%2d {%7s %6s} %s" \
			$spn $pos $len $sp_length $sp_pos $sp_label]
}

set debug_outfile "j1939.txt"
set fd [open $debug_outfile "w"]
foreach x $::all_pgn {
	report_visit_pgn $fd $x
}
close $fd

set c_header_outfile "j1939_msg.h"
set fd [open $c_header_outfile "w"]
ccode_header $fd
foreach x $::all_pgn {
	ccode_visit_pgn $fd $x
}
ccode_footer $fd
close $fd
