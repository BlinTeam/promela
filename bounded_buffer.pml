#define emptyC(C) (C.waiting == 0)
bool lock = false;
int waitCount = 0;

typedef condition {
	bool gate;
	byte waiting;
}

inline enterMon() {
	atomic {
		!lock && (waitCount == 0);
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
		waitCount++;
		!lock;
		waitCount--;
		lock = true;
	}
}

inline signalC(C) {
	atomic {
		if
		:: (C.waiting > 0) -> 	/* Signal only if waiting */
			C.gate = true; /*Signal the gate*/
		:: else -> 
			skip;
		fi;
	}
}

#define BUFFER_SIZE 10
int buffer[BUFFER_SIZE];
int lastPointer = 0;
int count = 0;
int item = 0;
int append_count = 0;
int remove_count = 0;
condition nonEmpty;
condition nonFull;

inline append(d) {
	enterMon();
	if
	:: (count == BUFFER_SIZE) -> waitC(nonFull);
	:: else -> skip;
	fi;
	append_count++;
	buffer[lastPointer] = d;
	printf("append in buffer value: %d", d);
	lastPointer = (lastPointer + 1) % BUFFER_SIZE;
	count++;
	append_count--;
	signalC(nonEmpty);
	leaveMon();
}

inline remove() {
	enterMon();
	if
	:: (count == 0) -> waitC(nonEmpty);
	:: else -> skip;
	fi;
	remove_count++;
	int index = (BUFFER_SIZE + lastPointer - count) % BUFFER_SIZE;
	count--;
	printf("take from buffer value: %d", buffer[index]);
	remove_count--;
	signalC(nonFull)
	leaveMon();
} 

active [3] proctype user() {
	do
	::
	atomic {
		item++;
		append(item);
	}
	remove();
	od;
}