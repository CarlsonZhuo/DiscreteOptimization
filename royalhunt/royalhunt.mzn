int: n; % number of court members
set of int: COURT = 1..n;
int: emperor = 1;
array[COURT] of int: rank;
array[COURT] of int: ability;

int: m; % number of horses
set of int: HORSE = 1..m;
array[HORSE] of int: beauty;
array[HORSE] of int: speed;

array[COURT,HORSE] of int: enjoy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

array[COURT] of var HORSE union {0}: horse_of;

% Constraint 0
% Define 0 tail
% If one man does not own a horse, then people with lower rank would not own a horse
constraint forall(i, j in COURT where rank[i] < rank[j]) (
 horse_of[j] = 0 -> horse_of[i] = 0
);
% At most n-m zero
%% constraint n>m -> sum([1 | i in COURT where horse_of[i] = 0]) = n-m;
% If m > n, no zero
%% constraint m>=n -> sum([1 | i in COURT where horse_of[i] = 0]) = 0;
constraint sum(i in COURT) (horse_of[i] > 0) = min(n, m);

% Constraint 1
% All horse different except 0
include "alldifferent_except_0.mzn";
constraint alldifferent_except_0(horse_of);

% Constraint 2
% The emperor must enjoy the day more than anyone else.
constraint forall(i in 2..n where horse_of[i] != 0) (enjoy[i, horse_of[i]] < enjoy[1, horse_of[1]]);

% Constraint 3
% If a court member holds a higher rank than another, then either 
% (a) the beauty of their horse can be no less than that assigned to the other, 
% (b) the lower rank member does not ride, or 
% (c) both court members do not ride.
constraint forall(i, j in COURT where rank[i] < rank[j] /\ horse_of[i] != 0 /\ horse_of[j] != 0) (
    horse_of[i] = 0 \/
    (horse_of[i] = 0 /\ horse_of[j] = 0) \/
    beauty[horse_of[i]] <= beauty[horse_of[j]]
);

% Constraint 4
% No negative enjoyment
constraint forall(i in COURT where horse_of[i] != 0)(
    enjoy[i, horse_of[i]] >= 0
);

% Constraint 5
% Define rider_of
array[HORSE] of var COURT union {0}: rider_of;
constraint forall(i in COURT, j in HORSE) (
   (horse_of[i] = j <-> rider_of[j] = i)
);


% Constraint 6
% (a) the rider of the faster horse has no less riding ability than that of the slower horse, 
% (b) the faster horse has no rider
% (c) both horses have no rider.

% Punish if not a /\ not b /\ not c.
% not b: the faster horse has a rider
% not c: one of the horse has at least one rider.
% not b -> not c
% not a: the rider of the faster one has less skill.

% Hence, punish if
% (a) the faster horse has rider, and
% (b1) the slower one has rider, but skill is better OR
% (b2) the slower one has no rider.
var int: penalty = sum([1 | i, j in HORSE where 
        speed[i] < speed[j] /\ rider_of[j] != 0 /\
        ((rider_of[i] != 0 /\ ability[rider_of[i]] > ability[rider_of[j]]) \/
        rider_of[i] = 0)
]);

% maximize the total enjoyment of the hunt over all riders
var int: overall_enjoyment = sum(i in 1..n where horse_of[i] != 0) (enjoy[i, horse_of[i]]);
var int: obj = overall_enjoyment - 100*penalty;
solve maximize obj;

output ["rider = \(rider_of);\nhorse = \(horse_of);\n",  "obj = \(obj);"];
%output ["horse = \(horse_of);\n",  "obj = \(obj);"];