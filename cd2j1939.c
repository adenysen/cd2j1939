#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include "j1939_msg.h"

static void usage(char *progname)
{
	fprintf(stderr,
		"\nusage: %s [options]\n\n"
		" -f [file] read CAN messages from 'file' (use '-' for stdin)\n"
		" -h        prints this message and exits\n"
		"\n",
		progname);
}

int main(int argc, char *argv[])
{
	char *infile = NULL, line[128], *progname;
	uint32_t cid, ms, pf, pgn, ps;
	struct j1939_msg msg;
	int64_t data, sec;
	int c, cnt;
	FILE *fp;

	/* Process the command line arguments. */
	progname = strrchr(argv[0], '/');
	progname = progname ? 1 + progname : argv[0];
	while (EOF != (c = getopt(argc, argv, "f:h"))) {
		switch (c) {
		case 'f':
			infile = optarg;
			break;
		case 'h':
			usage(progname);
			return 0;
		case '?':
		default:
			usage(progname);
			return -1;
		}
	}
	if (!infile) {
		usage(progname);
		return -1;
	}
	if (!strcmp(infile, "-")) {
		fp = stdin;
	} else {
		fp = fopen(infile, "r");
		if (!fp) {
			fprintf(stderr, "cannot open %s: %m\n", infile);
			return -1;
		}
	}
	while (1) {
		if (!fgets(line, sizeof(line), fp)) {
			break;
		}
		//
		// (1543630057.858962) can0 0CF00203#CC0000FFF00000FF
		//
		cnt = sscanf(line, " (%" PRId64 ".%d) %*s %x#%" PRIx64,
			     &sec, &ms, &cid, &data);
		if (cnt != 4) {
			continue;
		}
		pf = (cid >> PF_SHIFT) & PF_MASK;
		ps = (cid >> PS_SHIFT) & PS_MASK;
		if (pf < 240) {
			ps = 0;
		}
		pgn = (pf << 8) | ps;
		data = __builtin_bswap64(data);
		if (!j1939_decode(pgn, data, &msg)) {
			j1939_print(stdout, &msg);
		} else {
			printf("* unknown cid 0x%08x pgn %u\n", cid, pgn);
		}
	}
	fclose(fp);

	return 0;
}
