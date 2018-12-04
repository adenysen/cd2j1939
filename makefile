CFLAGS = -Wall -Werror

all: j1939_msg.h cd2j1939

j1939_msg.h j1939_decode.c j1939_print.c: j1939-flat.tsv parse.awk
	./parse.awk < j1939-flat.tsv

j1939-flat.tsv: escape j1939.tsv
	./escape < j1939.tsv > j1939-flat.tsv

cd2j1939: cd2j1939.o j1939_decode.o j1939_print.o

escape: escape.o

clean:
	rm -f j1939_msg.h escape escape.o j1939-flat.tsv
	rm -f cd2j1939 cd2j1939.o j1939_decode.o j1939_print.o
	rm -f j1939_decode.c j1939_print.c j1939.txt
