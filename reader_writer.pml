#define emptyC(C) (C.waiting == 0)
bool lock = false;
int signalCount = 0;

typedef condition {
	bool gate;
	byte waiting;
}

inline enterMon() {
	atomic {
		!lock && signalCount == 0;
		lock = true;
	}
}

inline leaveMon() {
	lock = false;
}

inline waitC(C) {
	atomic {
		printf("MSC: wait\n");
		C.waiting++;
		lock = false;
		C.gate; /* Wait for gate */
		C.gate = false; /* Reset gate */
		C.waiting--;
	}
}

inline signalC(C) {
	atomic {
		if
		:: (C.waiting > 0) -> 	/* Signal only if waiting */
			signalCount++;
			C.gate = true; /*Signal the gate*/
			!lock; /* IRR, wait for lock */
			lock = true; /* Take lock again */
			signalCount--;
		:: else -> 
			skip;
		fi;
	}
}



/*monitor RW*/
#define COUNT_READERS 3
#define COUNT_WRITERS 3
byte readers = 0;
byte writers = 0;
int writer_iterations = 0;
int reader_iterations = 0;
condition OKtoRead;
condition OKtoWrite;

active [COUNT_READERS] proctype reader() {
/*operation StartRead */
do
:: (reader_iterations < 50) -> 
enterMon();
printf("MSC: EndRead\n");
if
    ::(writers > 0) -> 
        waitC(OKtoRead);
    :: else -> 
        skip;
fi;
readers++;
signalC(OKtoRead);
leaveMon();

printf("MSC: read the database \ncount of readers is %d\n", readers);

/*operation EndRead */
enterMon();
printf("MSC: EndRead\n");
readers--;
if
    :: (readers == 0) -> 
        signalC(OKtoWrite);
    :: else -> 
        skip;
fi;
leaveMon();
reader_iterations++;
:: else -> break;
od;
}

active [COUNT_WRITERS] proctype writer() {
/*operation StartWrite */
do
:: (writer_iterations < 50) ->
enterMon();
printf("MSC: StartWrite\n");
if 
    ::(writers > 0 || readers > 0) ->
        waitC(OKtoWrite);
    ::else -> 
        skip;
fi;
writers++;
leaveMon();

printf("MSC: write to the database\n");

/*operation EndWrite */
enterMon();
printf("MSC: EndWrite\n");
writers--;
if
    ::(emptyC(OKtoRead)) ->
        signalC(OKtoWrite);
    ::else -> 
        signalC(OKtoRead);    
fi;
leaveMon();
writer_iterations++;
:: else -> break;
od;
}