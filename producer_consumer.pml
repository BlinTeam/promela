#define emptyC(C) (C.waiting == 0)
bool lock = false;

typedef condition {
    bool gate;
    byte waiting;
}

inline enterMon() {
    atomic {
        !lock;
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
        lock = false; /* Exit monitor */
        C.gate; /* Wait for gate */
        C.gate = false; /* Reset gate */
        C.waiting--;
    }
}

inline signalC(C) {
    atomic {
        if
        :: (C.waiting > 0) ->     /* Signal only if waiting */
            C.gate = true; /*Signal the gate*/
            !lock; /* IRR, wait for lock */
            lock = true; /* Take lock again */
        :: else -> 
            skip;
        fi;
    }
}

#define BUFFER_SIZE 10
#define COUNT_PRODUCER 3
#define COUNT_CONSUMER 3
#define isFull (size >= BUFFER_SIZE)
#define isEmpty (size <= 0)
int buffer[10];
byte producers = 0;
byte consumers = 0;
condition Not_Empty;
condition Not_Full;
int size = 0;
int item = 0;

inline append(d, id) {
	enterMon();
	if
		:: (isFull) -> waitC(Not_Full);
		:: else -> skip;
	fi;
	producers++;
	printf("%d append, size = %d",id, size);
	buffer[size] = d;
	size++;
	printf("produce item %d", d);
	producers--;
	signalC(Not_Empty);
	leaveMon();
}

inline take(id) {
	int d = 0;
	enterMon();
	if
		:: (isEmpty) -> waitC(Not_Empty); // hotel lock 
		:: else -> skip;
	fi;
	consumers++;
	printf("%d take, size = %d", id, size);
	d = buffer[size - 1];
	printf("comsume item %d", d);
	size--;
	consumers--;
	signalC(Not_Full);
	leaveMon();
}


active [COUNT_PRODUCER] proctype producer() {
	int i;
	printf("producer: %d\n", _pid);
	do
	::
		int currentItem = 0;
		atomic {
			item++;
			currentItem = item;
		}
		append(currentItem, _pid)
	od;
}

active [COUNT_CONSUMER] proctype consumer() {
	printf("consymer: %d\n", _pid);
	do
	::
		take(_pid)
	od;
}