int: T; % maximum time allowed;
set of int: TIME = 1..T;

int: E; % weight of elephant in STONES;
set of int: STONE = 0..E;

int: G; % number of guards
set of int: GUARD = 1..G;
array[GUARD] of STONE: easy;   
array[GUARD] of STONE: hard;
array[GUARD] of TIME: tired;

GUARD: p; % maximum people on pier;
GUARD: b; % maximum people on boat;

set of int: ACT = -1..E; % -1 = goto bank, 0 = wait, > 0 carry stones  
int: wait = 0;
int: to_bank = -1;
array[GUARD,TIME] of var ACT: act;        % action at time t
var TIME: end;                            % end time;


constraint forall(t in TIME, g in GUARD) (
    act[g,t] = 0 \/
    act[g,t] = easy[g] \/
    act[g,t] = hard[g] \/
    act[g,t] = -1
);

% Helper var, carried
array[GUARD,TIME] of var 0..E: carried;
constraint forall(t in TIME, g in GUARD)(
    if act[g,t] < 0 then carried[g,t] = 0 else carried[g,t] = act[g,t] endif
);

% If all stones are carried, stop
constraint end=sum(t in TIME)(if sum(g in GUARD)(act[g,t]!=0)>0 then 1 else 0 endif);
% constraint end=min([if sum(t in 1..i, g in GUARD)(carried[g,t]) >= E then i else 0 endif  | i in TIME]);

% All act after end are zero
constraint forall(g in GUARD, t in TIME where t > end)(
    act[g, t] = 0
);

% All stones have to be carried
constraint sum(g in GUARD, t in TIME)(carried[g,t]) >= E;

% One man g cannot carry more than hard[g]
constraint forall(g in GUARD, t in TIME)(act[g,t] <= hard[g]);

% If carry more than easy, rest for tired[g]
constraint forall(g in GUARD, t in 1..end-1) (
    act[g,t] > easy[g] -> forall(i in t+1..min(t+tired[g], T)) (act[g,i] <= 0)
);

% All people in one direction
constraint forall(t in TIME, g1, g2 in GUARD where g1 < g2) (
    act[g1, t] * act[g2, t] >= 0
);

% No more than pier people passing through the pier
constraint forall(t in 1..T)(
    sum([if act[g,t] != 0 then 1 else 0 endif|g in GUARD]) <= p
);

predicate on_boat(TIME:t, GUARD:g) =
    sum([if act[g,tmpT]>0 then 1 else act[g,tmpT] endif | tmpT in 1..t]) = 1;

% No more than b people staying at the boat
constraint forall(t in TIME)(
    sum([on_boat(t, g) | g in GUARD]) < b
);

constraint forall(g in GUARD)(
    act[g,1] != -1
);

constraint exists(g in GUARD)(
    act[g,1] > 0
);

constraint forall(t in 1..end-1, g in GUARD)(
    act[g,t] > 0 -> 
        (
%         forall(tmpT in t+1..end)(act[g,tmpT]=0)
        act[g,t+1] = -1
        \/ exists(nextT in t+2..T)(act[g,nextT]=-1 /\ forall(tmpT in t+1..nextT-1)(act[g,tmpT]=0)) 
        )
);

constraint forall(t in 2..T, g in GUARD)(
    act[g,t] = -1 -> 
        (act[g,t-1] > 0
        \/ exists(prevT in 1..t-2)(act[g,prevT]>0 /\ forall(tmpT in prevT+1..t-1)(act[g,tmpT]=0))
        )   
);

solve minimize end;

output
       ["act = array2d(GUARD,TIME,[\n"] ++
       [ show_int(2,act[g,t]) ++ "," ++ "\t"
       ++ if t = T /\ g = G then "]);\n" elseif t = T then "\n" else "" endif
       | g in GUARD, t in TIME ] ++
       ["end =" ++ show_int(2, end) ++ ";"]