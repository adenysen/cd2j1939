#!/usr/bin/gawk -f

BEGIN {
	FS = "\t";
	last_pgn = -1;
	n_fields = 0;
	n_pgn = 0;
	debug_outfile = "j1939.txt";
	c_header_outfile = "j1939_msg.h"
	c_decode_outfile = "j1939_decode.c"
	c_print_outfile = "j1939_print.c"

	printf "#ifndef HAVE_J1939_REG_H\n" > c_header_outfile;
	printf "#define HAVE_J1939_REG_H\n" > c_header_outfile;
	printf "\n" > c_header_outfile;
	printf "#include <stdint.h>\n" > c_header_outfile;

	printf "#include \"%s\"\n", c_header_outfile > c_decode_outfile;
	printf "\n" > c_decode_outfile;
	printf "int j1939_decode(unsigned int type, uint64_t data, struct j1939_msg *msg)\n" > c_decode_outfile;
	printf "{\n" > c_decode_outfile;
	printf "\tmsg->type = type;\n" > c_decode_outfile;
	printf "\tswitch (msg->type) {\n" > c_decode_outfile;

	printf "#include <stdio.h>\n" > c_print_outfile;
	printf "#include \"%s\"\n", c_header_outfile > c_print_outfile;
	printf "\n" > c_print_outfile;
	printf "void j1939_print(FILE *fp, struct j1939_msg *msg)\n" > c_print_outfile;
	printf "{\n" > c_print_outfile;
	printf "\tswitch (msg->type) {\n" > c_print_outfile;
}

END {
	pgn_footer();

	printf "\n" > c_header_outfile;
	printf "struct j1939_msg {\n" > c_header_outfile;
	printf "\tunsigned int type;\n" > c_header_outfile;
	printf "\tunion {\n" > c_header_outfile;
	for (i = 0; i < n_pgn; i++) {
		printf "\t\tstruct %s %s;\n", \
			tolower(all_pgn[i]), tolower(all_pgn[i]) > c_header_outfile;
	}
	printf "\t};\n" > c_header_outfile;
	printf "};\n" > c_header_outfile;
	printf "\n" > c_header_outfile;
	printf "#endif\n" > c_header_outfile;

	printf "\tdefault:\n" > c_decode_outfile;
	printf "\t\treturn -1;\n" > c_decode_outfile;
	printf "\t}\n" > c_decode_outfile;
	printf "\treturn 0;\n" > c_decode_outfile;
	printf "}\n" > c_decode_outfile;

	printf "\t}\n" > c_print_outfile;
	printf "}\n" > c_print_outfile;
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

function pgn_header()
{
	#
	# FOREACH PGN
	#
	printf "%5d %s  %s\n", pgn, pg_name, pg_label > debug_outfile;

	printf "\n" > c_header_outfile;
	printf "// %s\n", pg_label > c_header_outfile;
	printf "\n" > c_header_outfile;
	printf "#define %-16s %d\n", pg_name, pgn > c_header_outfile;

	printf "\tcase %s:\n", pg_name > c_decode_outfile;

	printf "\tcase %s:\n", pg_name > c_print_outfile;
	printf "\t\tfprintf(fp, \"* %s -- %s\\n\");\n", \
		pg_name, pg_label > c_print_outfile;

	all_pgn[n_pgn] = pg_name;
	n_pgn++;
}

function pgn_footer(  i, word)
{
	if (last_pgn == -1) {
		return;
	}
	#
	# FOREACH SPN
	#
	printf "\n" > c_header_outfile;
	printf "struct %s {\n", tolower(pg_name) > c_header_outfile;
	for (i = 0; i < n_fields; i++) {
		word = int((f_len[i] + 7) / 8);
		if (word == 3) {
		    word++;
		} else if (word > 4) {
		    word = 8;
		}
		word *= 8;
		printf "\tuint%d_t spn%d;\n", \
			word, f_spn[i] > c_header_outfile;

		printf "\t\tmsg->%s.spn%d = (data >> SPN%d_SHIFT) & SPN%d_MASK;\n", \
			tolower(pg_name), f_spn[i], f_spn[i], f_spn[i] > c_decode_outfile;

		printf "\t\tfprintf(fp, \"  %s: 0x%%x\\n\", msg->%s.spn%d);\n", \
			f_label[i], tolower(pg_name), f_spn[i] > c_print_outfile;
	}
	printf "};\n" > c_header_outfile;
	printf "\t\tbreak;\n" > c_decode_outfile;
	printf "\t\tbreak;\n" > c_print_outfile;
	n_fields = 0;
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

	mask = sprintf("SPN%d_MASK", spn);
	shift = sprintf("SPN%d_SHIFT", spn);
	hex = int(lshift(1, len)) - 1;

	printf "#define %-16s 0x%x\n", mask, hex > c_header_outfile;
	printf "#define %-16s %d\n", shift, pos > c_header_outfile;

	f_spn[n_fields] = spn;
	f_len[n_fields] = len;
	f_label[n_fields] = sp_label;
	n_fields++;
}

$1 != "Revised" && $15 == 8 && $18 != "" && $19 != "" {
	if ($5 != last_pgn) {
		pgn_footer();
	}
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

	# Some of the names have a / so remove it.
	gsub("/", "_", pg_name);

	# Some of the labels have "" so remove them.
	gsub("\"", "'", sp_label);

	# Sanity check for duplicate SPN numbers.
	if (spn in all) {
		print NR, spn, position;
	}
	all[spn] = 1;

	if (pgn != last_pgn) {
		pgn_header();
	}
	spn_record();
	last_pgn = pgn;
}
