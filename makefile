CFLAGS = -Wall -Werror

all: j1939-flat.tsv

j1939-flat.tsv: escape j1939.tsv
	./escape < j1939.tsv > j1939-flat.tsv

escape: escape.o

clean:
	rm -f escape escape.o j1939-flat.tsv
