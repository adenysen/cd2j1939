#!/usr/bin/gawk -f

BEGIN {
	FS = "\t";
	last_pgn = -1;
	debug_outfile = "j1939.txt";
	c_header_outfile = "j1939_reg.h"
	printf "#ifndef HAVE_J1939_REG_H\n" > c_header_outfile;
	printf "#define HAVE_J1939_REG_H\n" > c_header_outfile;
}

END {
	printf "\n" > c_header_outfile;
	printf "#endif\n" > c_header_outfile;
}

function bitlen(input,  num, unit)
{
	split(input, tmp, " ");

	num  = tmp[1];
	unit = tmp[2];

	if (unit == "bit" || unit == "bits") {
		return num;
	} else if (unit == "byte" || unit == "bytes") {
		return 8 * num;
	}
	printf "UNEXPECTED SIZE: %s\n", input;
}

function bitpos(input,  byte, bit)
{
	split(input, tmp, ",");
	input = tmp[1];

	if (match(input, "\\.")) {
		split(input, tmp, "\\.");
		byte = tmp[1];
		bit = tmp[2];
		byte--;
		bit--;
	} else if (match(input, "-")) {
		split(input, tmp, "-");
		byte = tmp[1];
		byte--;
		bit = 0;
	} else {
		byte = input;
		byte--;
		bit = 0;
	}
	return bit + 8 * byte;
}

function pgn_header(  id)
{
	printf "%5d %s  %s\n", pgn, pg_name, pg_label > debug_outfile;
	printf "\n" > c_header_outfile;
	printf "// %s (%d)  %s\n", pg_name, pgn, pg_label > c_header_outfile;
	printf "\n" > c_header_outfile;
}

function spn_record(  len, pos, mask, shift, hex)
{
	len = bitlen(sp_length);
	pos = bitpos(position);
	# Ignore these two that are larger than eight bytes:
	# 1198   2-8 56 Anti-theft Random Number
	# 1202   2-8 56 Anti-theft Password Representation
	if (len > 32) {
		return;
	}
	printf "\t%5d bitpos=%2d bitlen=%2d {%7s %6s} %s\n", \
		spn, pos, len, sp_length, position, sp_label  > debug_outfile;

#	printf "\n" > c_header_outfile;
#	printf "// %5d bitpos=%2d bitlen=%2d {%7s %6s} %s\n", \
#	 	spn, pos, len, sp_length, position, sp_label  > c_header_outfile;

	mask = sprintf("SPN%d_MASK", spn);
	shift = sprintf("SPN%d_SHIFT", spn);
	hex = int(lshift(1, len)) - 1;

	printf "#define %-16s 0x%x\n", mask, hex > c_header_outfile;
	printf "#define %-16s %d\n", shift, pos > c_header_outfile;
}

$1 != "Revised" && $15 == 8 && $18 != "" && $19 != "" {
	pgn = $5;
	pg_label = $6;
	pg_name = $7;
	pg_desc = $8;
	edp = $9;
	dp = $10;
	pf = $11;
	ps = $12;
	multipacket = $13;
	txrate = $14; # NB text
	datalen = $15;
	priority = $16;
	ref = $17;
	position = $18;
	spn = $19;
	sp_label = $20;
	sp_desc = $21;
	sp_length = $22; # "2 bits" or "1 byte"
	resolution = $23; # NB text
	offset = $24; # NB some are number with unit
	datrange = $25; # "0 to 8,000.1 rpm"
	operange = $26; 
	units = $27;
	slot_id = $28; # index
	slot_name = $29; # internal database name

	# Sanity check for duplicate SPN numbers.
	if (spn in all) {
		print NR, spn, position;
	}
	all[spn] = 1;

	if (pgn != last_pgn) {
		pgn_header();
		last_pgn = pgn;
	}
	spn_record();
}
