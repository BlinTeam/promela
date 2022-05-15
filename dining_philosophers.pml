#define emptyC(C) (C.waiting == 0)
bool lock = false;
int waitCount = 0;

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
		lock = false;
		C.gate; /* Wait for gate */
		C.gate = false; /* Reset gate */
		C.waiting--;
		!lock;
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


#define PHILOSOPHERS_COUNT 5
#define next(i) ((i + 1) % PHILOSOPHERS_COUNT)
#define prev(i) ((i + PHILOSOPHERS_COUNT - 1) % PHILOSOPHERS_COUNT)
int philosopherForks[5];
int eatingPhilosopher = 0;
int sumForks = 10;
condition Ok2Eat[5];

inline takeForks(i) {
	enterMon();
	if
	:: (philosopherForks[i] != 2) -> waitC(Ok2Eat[i]);
	:: else -> skip;
	fi;
	philosopherForks[next(i)] = philosopherForks[next(i)] - 1;
	philosopherForks[prev(i)] = philosopherForks[prev(i)] - 1;
	atomic {
		sumForks = sumForks - 2;
		eatingPhilosopher++;
	}
	leaveMon();
}

inline releaseForks(i) {
	enterMon();
	philosopherForks[next(i)] = philosopherForks[next(i)] + 1;
	philosopherForks[prev(i)] = philosopherForks[prev(i)] + 1;
	atomic {
		sumForks = sumForks + 2;
		eatingPhilosopher--;
	}
	if
	:: (philosopherForks[next(i)] == 2) -> signalC(Ok2Eat[next(i)]);
	:: else -> skip;
	fi;
	if
	:: (philosopherForks[prev(i)] == 2) -> signalC(Ok2Eat[prev(i)]);
	:: else -> skip;
	fi;
	leaveMon();
}

int interations[5];

proctype philosopher(int id) {
	do
	:: (interations[id] < 10) -> 
		printf("philosopher %d want eating", id);
		takeForks(id);
		printf("philosopher %d is eating", id);
		releaseForks(id);
		printf("philosopher %d stop eating", id);
		interations[id]++;
	:: else -> break;
	od;
}

init {
	atomic{
		int i = 0;
		do
		:: (i < PHILOSOPHERS_COUNT) -> 
		   philosopherForks[i] = 2;
		   run philosopher(i); 
		   i++;
		:: else -> break;
		od;
	}
}