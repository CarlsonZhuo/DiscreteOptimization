% assignment 2
% select a set of raiding warrior
enum WARRIOR;
WARRIOR: dummy; 
enum CLAN; % the clan they belong too

int: l; % minimum raid party size
int: u; % maximum raid party size
int: m; % limit of hatreds

array[WARRIOR] of int: strength;
array[WARRIOR] of CLAN: clan;

array[CLAN,CLAN] of 0..1: hates;

array[1..u] of var WARRIOR: raid_team;
var int: total_strength = sum(i in 1..u) (strength[raid_team[i]]);

% No more than m hates among
constraint (sum(i, j in 1..u where j < i) (hates[clan[raid_team[i]], clan[raid_team[j]]]) <= m);
% RAID TEAM all different except dummy
constraint forall(i in 1..u-1) (
                        (raid_team[i] >= (raid_team[i] != dummy) + raid_team[i+1]));

% no more than u - l dummy
constraint sum(i in 1..u) (raid_team[i] == dummy) <= u - l;

% Maximize the strength
solve maximize total_strength;

output ["raid = {"] ++ [if fix(raid_team[i]) != dummy then show(raid_team[i])
                        ++ if i < u /\ fix(raid_team[i+1]) != dummy then ", " else "" endif
                     else "" endif | i in 1..u ] ++ ["};\n"];
output ["obj=" ++ show(total_strength)++";"];