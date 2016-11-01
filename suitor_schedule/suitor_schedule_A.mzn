% scheduling suitors
enum SUITOR;
SUITOR: LiuBei; % which suitor is LiuBei
int: n; % number of meetings
set of int: MEETING = 1..n;
array[MEETING] of SUITOR: suitor;

enum ROOM = { Red, Gold, Blue };
array[SUITOR,ROOM] of int: mintime;
array[SUITOR,ROOM] of int: maxtime;
constraint forall(s in SUITOR, r in ROOM)
                 (assert(mintime[s,r] >= 1 /\ maxtime[s,r] >= mintime[s,r], 
                  "error in mintime/maxtime at [\(s),\(r)]\n"));

array[ROOM,ROOM] of int: move;
constraint forall(r in ROOM)(assert(move[r,r] = 0,"move[\(r),\(r)] != 0\n"));

int: ndays; % number of days
set of int: DAY = 1..ndays;
int: earliest; % time for earliest meeting start
int: latest;  % time for end of latest meeting

int: lessontime; % time for kung fu lesson;
int: minsep;     % minimum time between consecutive kung fu lessons

array[ROOM] of int: usedstart;  % time others use each room each day
array[ROOM] of int: useddur;    % durations of others use

enum STAGE = {A,B,C};
STAGE: stage;

set of int: TIME = 0..24*ndays;

array[MEETING] of var TIME: start;
array[MEETING] of var TIME: dur;    % duration in false schedule
array[MEETING] of var ROOM: room;
set of int: KUNGFU = 1..n;
array[KUNGFU] of var int: kungfu;  % start time for each lesson
   % unused lessons have start times after 24*ndays


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% include "globals.mzn";

% For every meeting, it cannot start earlier than earliest
% For every meeting, it cannot end later than latest
constraint forall(m in MEETING) (
    (start[m] mod 24) >= earliest /\
    (start[m] mod 24) <= latest /\
    ((start[m] + dur[m]) mod 24) >= earliest /\
    ((start[m] + dur[m]) mod 24) <= latest
);

% For every meeting, it cannot last longer than maxtime
% For every meeting, it cannot shorter longer than mintime
constraint forall(m in MEETING) (
    dur[m] >= mintime[suitor[m], room[m]] /\
    dur[m] <= maxtime[suitor[m], room[m]]
);

% Suitors meeting cannot overlap with each other
constraint forall(m1, m2 in MEETING where m1 < m2) (
    start[m1] + dur[m1] <= start[m2] \/
    start[m2] + dur[m2] <= start[m1]
);

% Suitors meeting cannot falls in reserved time
constraint forall(m in MEETING) (
    usedstart[room[m]] + useddur[room[m]] <= (start[m] mod 24)\/
    (start[m] + dur[m]) mod 24 <= usedstart[room[m]]
);

% Constraint only for stage A
constraint forall(k in KUNGFU) (
    kungfu[k] = 24*ndays + 1
);

% Maximize Time for Liu Bei
var int: obj = sum(m in MEETING where suitor[m] = LiuBei)(dur[m]);

solve maximize obj;

output
       ["start = ["] ++ [show_int(2, start[m]) ++ if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["dur = ["] ++ [show_int(2, dur[m]) ++  if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["room = ["] ++ [show(room[m]) ++  if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["kungfu = ["] ++ [show(kungfu[k]) ++  if k != n then ", " else "" endif | k in KUNGFU] ++ ["];\n"]
       ++ ["obj = " ++ show(obj) ++ ";"]
       ;





