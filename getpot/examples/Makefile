IPATH = -I./. -I../.

ADDFLAGS = -ggdb -Wall


PROGRAMS = get next options follow direct_follow \
           nominus flags input-file variables filter \
	   expand ufo field_separator ez-ufo absorb tails \
	   nominus_followers

all: $(PROGRAMS) 

.cpp: 
	g++ $(ADDFLAGS) $(IPATH) $< -o $@

clean:
	rm -f $(PROGRAMS)
