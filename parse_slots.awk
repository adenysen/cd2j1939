#!/usr/bin/gawk -f

BEGIN {
	FS = "\t";
	printf "#ifndef HAVE_J1939_SLOTS_H\n";
	printf "#define HAVE_J1939_SLOTS_H\n";
	printf "\n"
}

END {
	printf "#endif\n"
}

function get_format(input)
{
	if (input == "d") {
		return "%11d";
	} else if (input == "u") {
		return "%11u";
	}
	return sprintf("%%11.%df", input);
}

function get_offset(input)
{
	split(input, tmp, " ");
	input = tmp[1];
	gsub(",", "", input);
	return input;
}

function get_scale(input)
{
	split(input, tmp, " ");
	input = tmp[1];
	gsub("/", ".0/", input);
	gsub(",", "", input);
	return input;
}

!($1 ~ "#") {
	type = $1;
	format = $2;
	slot = $4;
	scale = $6;
	offset = $8;
	noop = 0;

	if (type == "int") {
		if (format == "u") {
			type = "unsigned int";
		}
	} else if (type == "d") {
		type = "double";
	} else {
		noop = 1;
	}
	format = get_format(format);
	offset = get_offset(offset);
	scale = get_scale(scale);

	printf "static inline void %s(unsigned int val, char *buf, int len)\n", slot;
	printf "{\n"
	if (noop) {
		printf "\tsnprintf(buf, len, \"          ?\");\n";
	} else {
		printf "\t%s result = %s + val * %s;\n", type, offset, scale;
		printf "\tsnprintf(buf, len, \"%s\", result);\n", format;
	}
	printf "}\n"
	printf "\n"
}
