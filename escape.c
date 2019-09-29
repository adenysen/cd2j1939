//
// Libreoffice generates a TSV that is not quite usable.  This program
// removes the quotes from the strings and converts embedded new lines
// into \n sequences.
//
#include <stdio.h>

#define QUOTE 0x27

static void put(int val, int inside)
{
	if (inside) {
		switch (val) {
		case '\n':
			putchar('\\');
			putchar('n');
			break;
		case '\t':
			putchar('\\');
			putchar('t');
			break;
		default:
			putchar(val);
			break;
		}
	} else {
		putchar(val);
	}
}

int main()
{
	int inside = 0, qcnt = 0, val;

	while ((val = getchar()) && EOF != val) {
		switch (qcnt) {
		case 0:
			if (val == QUOTE) {
				qcnt = 1;
			} else {
				put(val, inside);
			}
			break;
		case 1:
			if (val == QUOTE) {
				qcnt = 2;
			} else {
				inside = 1 - inside;
				qcnt = 0;
			}
			put(val, inside);
			break;
		case 2:
			if (val == QUOTE) {
				qcnt = 1;
			} else {
				put(val, inside);
			}
			break;
		}
	}
	return 0;
}
