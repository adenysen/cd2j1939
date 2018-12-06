#!/usr/bin/gawk -f

BEGIN {
	FS = "\t";
	last_pgn = -1;
	n_fields = 0;
	c_header_outfile = "j1939_msg.h"
	c_decode_outfile = "j1939_decode.c"
	c_print_outfile = "j1939_print.c"

	# TCL
	printf "set ::all_pgn {\n"

	printf "#include \"%s\"\n", c_header_outfile	> c_decode_outfile;
	printf "\n"					> c_decode_outfile;
	printf "int j1939_decode(unsigned int type, uint64_t data, struct j1939_msg *msg)\n" > c_decode_outfile;
	printf "{\n"					> c_decode_outfile;
	printf "\tmsg->type = type;\n"			> c_decode_outfile;
	printf "\tswitch (msg->type) {\n"		> c_decode_outfile;

	printf "#include <stdio.h>\n"					> c_print_outfile;
	printf "#include \"%s\"\n", c_header_outfile			> c_print_outfile;
	printf "#include \"j1939_slot.h\"\n"				> c_print_outfile;
	printf "\n"							> c_print_outfile;
	printf "\tstatic char nastr[] = \"         NA\";"		> c_print_outfile;
	printf "\n"							> c_print_outfile;
	printf "void j1939_print(FILE *fp, struct j1939_msg *msg)\n"	> c_print_outfile;
	printf "{\n"							> c_print_outfile;
	printf "\tchar *ptr, buf[128];\n"				> c_print_outfile;
	printf "\tswitch (msg->type) {\n"				> c_print_outfile;
}

END {
	pgn_footer();

	printf "\tdefault:\n"				> c_decode_outfile;
	printf "\t\treturn -1;\n"			> c_decode_outfile;
	printf "\t}\n"					> c_decode_outfile;
	printf "\treturn 0;\n"				> c_decode_outfile;
	printf "}\n"					> c_decode_outfile;

	printf "\t}\n"					> c_print_outfile;
	printf "}\n"					> c_print_outfile;

	# TCL
	printf "}\n"
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

function print_protect(x, indent,  i)
{
	for (i = 0; i < indent; i++) {
		printf "\t";
	}
	if (match(x, " ") || x == "") {
		printf "{%s}", x;
	} else {
		printf "%s", x;
	}
	printf "\n";
}

function pg_print_protect(x)
{
	print_protect(x, 1);
}

function sp_print_protect(x)
{
	print_protect(x, 2);
}

function pgn_header()
{
	# TCL
	printf "{\n";
	pg_print_protect(pgn);
	pg_print_protect(pg_label);
	pg_print_protect(pg_name);
	pg_print_protect(pg_desc);
	pg_print_protect(edp);
	pg_print_protect(dp);
	pg_print_protect(pf);
	pg_print_protect(ps);
	pg_print_protect(multipacket);
	pg_print_protect(txrate);
	pg_print_protect(datalen);
	pg_print_protect(priority);
	printf "\t{\n";

	#
	# FOREACH PGN
	#
	printf "\tcase %s:\n", pg_name			> c_decode_outfile;

	printf "\tcase %s:\n", pg_name			> c_print_outfile;
	printf "\t\tfprintf(fp, \"* %s -- %s\\n\");\n", \
		pg_name, pg_label			> c_print_outfile;
}

function pgn_footer(  i, label)
{
	if (last_pgn == -1) {
		return;
	}
	# TCL
	printf "\t}\n";
	printf "}\n";
	#
	# FOREACH SPN
	#
	for (i = 0; i < n_fields; i++) {

		printf "\t\tmsg->%s.spn%d = (data >> SPN%d_SHIFT) & SPN%d_MASK;\n", \
			tolower(pg_name), f_spn[i], f_spn[i], f_spn[i] > c_decode_outfile;

		printf "\t\tif (msg->%s.spn%d == SPN%d_MASK) {\n", \
			tolower(pg_name), f_spn[i], f_spn[i] > c_print_outfile;

		printf "\t\t\tptr = nastr;\n"	> c_print_outfile;
		printf "\t\t} else {\n"		> c_print_outfile;

		printf "\t\t\t%s(msg->%s.spn%d, buf, sizeof(buf));\n", \
			slot_name, tolower(pg_name), f_spn[i] > c_print_outfile;

		printf "\t\t\tptr = buf;\n"	> c_print_outfile;
		printf "\t\t}\n"		> c_print_outfile;

		# Truncate label to a reasonable length.
		label = substr(f_label[i], 1, 50);
		if (label != f_label[i]) {
		    label = label "..."
		}

		printf "\t\tfprintf(fp, \"  %-54s %%s %s  0x%%x\\n\", ptr, msg->%s.spn%d);\n", \
			label, units, tolower(pg_name), f_spn[i] > c_print_outfile;
	}
	printf "\t\tbreak;\n"				> c_decode_outfile;
	printf "\t\tbreak;\n"				> c_print_outfile;
	n_fields = 0;
}

function spn_record(  len, pos, mask, shift, hex)
{
	len = bitlen(sp_length);
	pos = bitpos(sp_position);
	# Ignore these two that are larger than eight bytes:
	# 1198   2-8 56 Anti-theft Random Number
	# 1202   2-8 56 Anti-theft Password Representation
	if (len > 32) {
		return;
	}

	mask = sprintf("SPN%d_MASK", spn);
	shift = sprintf("SPN%d_SHIFT", spn);
	hex = int(lshift(1, len)) - 1;

	f_spn[n_fields] = spn;
	f_label[n_fields] = sp_label;
	n_fields++;

	# TCL
	printf "\t{\n";
	sp_print_protect(sp_position);
	sp_print_protect(spn);
	sp_print_protect(sp_label);
	sp_print_protect(sp_desc);
	sp_print_protect(sp_length);
	sp_print_protect(resolution);
	sp_print_protect(offset);
	sp_print_protect(datrange);
	sp_print_protect(operange);
	sp_print_protect(units);
	sp_print_protect(slot_id);
	sp_print_protect(slot_name);
	sp_print_protect(len);
	sp_print_protect(pos);
	sp_print_protect(mask);
	sp_print_protect(shift);
	sp_print_protect(hex);
	printf "\t}\n";
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
	ref = $17; # uninteresting
	sp_position = $18; # byte.bit or byte-byte
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

	# Some units are empty or have %, so fix it.
	if (!units) {
		units = ";";
	}
	gsub("%", "%%", units);

	# Sanity check for duplicate SPN numbers.
	if (spn in all) {
		print NR, spn, sp_position;
	}
	all[spn] = 1;

	if (pgn != last_pgn) {
		pgn_header();
	}
	spn_record();
	last_pgn = pgn;
}
