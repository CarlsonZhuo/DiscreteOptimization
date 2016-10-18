% Liu Bei forsees that Yuan Shiu will be defeated by Cao Cao
% He needs to find a route to safety in Jin province before the defeat
% But Cao Cao's soldiers are everywhere

int: nrow;
set of int: ROW = 1..nrow;
int: ncol;
set of int: COL = 1..ncol;

% Plains, Mountain, Forest, City, River
enum TERRAIN = { P, M, F, C, R };
array[TERRAIN] of int: delay;
int: timelimit;

array[ROW,COL] of TERRAIN: terrain;
array[ROW,COL] of int: soldier;
array[ROW,COL] of bool: Jin;

int: start_row;
int: start_col;

int: maxstep;
set of int: STEP = 1..maxstep;
set of int: STEP0 = 0..maxstep;

var STEP: steps;
array[ROW,COL] of var STEP0: visit; % which step do we visit position or 0 if not visited


% Another Viewpoint - at_row, at_col
array[1..maxstep] of var 0..nrow: at_row;
array[1..maxstep] of var 0..ncol: at_col;
% constraint forall(r in ROW, c in COL) 
%                 (visit[r, c] >= 1 -> (at_row[visit[r, c]] = r /\ at_col[visit[r, c]] = c));
constraint forall(s in 1..steps) 
                (visit[at_row[s], at_col[s]] = s);
% constraint forall(s in 1..maxstep) 
%                 ((at_row[s] >= 1 /\ at_col[s] >= 1) -> visit[at_row[s], at_col[s]] = s);

% constraint forall(s in 1..maxstep)
%                 (at_row[s] = 0 <-> at_col[s] = 0);
                
% start at start position
constraint visit[start_row,start_col] = 1;
constraint at_row[1] = start_row;
constraint at_col[1] =start_col;


% only use steps moves
constraint sum(r in ROW, c in COL)(visit[r,c] >= 1) <= steps;
% reach Jin province
% constraint exists(r in ROW, c in COL)(Jin[r,c] /\ visit[r,c] >= 1);
constraint Jin[at_row[steps], at_col[steps]];

% visit at most one city
% constraint not exists(r1,r2 in ROW, c1,c2 in COL)
%                      ((r1 != r2 \/ c1 != c2) 
%                       /\ terrain[r1,c1] = C /\ terrain[r2,c2] = C 
%                       /\ visit[r1,c1] >= 1 /\ visit[r2,c2] >= 1); 
constraint sum(s in 1..maxstep)
                (at_row[s] != 0 /\ at_col[s] != 0 /\ terrain[at_row[s], at_col[s]] = C) <= 1;


% cant enter Mountain
% constraint not exists(r in ROW, c in COL)(terrain[r,c] = M /\ visit[r,c] >= 1);
constraint forall(s in 1..maxstep)
                (at_row[s] != 0 /\ at_col[s] != 0 -> terrain[at_row[s], at_col[s]] != M);


% visit only one place in every step
% constraint forall(r1,r2 in ROW, c1,c2 in COL)
%                  (r1 != r2 \/ c1 != c2  
%                   -> (visit[r1,c1] = 0 
%                       \/ visit[r2,c2] != visit[r1,c1])); 
include "alldifferent_except_0.mzn";
constraint alldifferent_except_0([at_row[s]*nrow + at_col[s] | s in 1..maxstep]);


% steps form a path
% constraint forall(s in 1..steps-1)
%                  (exists(r1, r2 in ROW, c1, c2 in COL)
%                         (abs(r1-r2) + abs(c1-c2) = 1 
%                          /\ visit[r1,c1] = s /\ visit[r2,c2] = s+1));
constraint forall(s in 1..maxstep-1 where s <= steps -1 )
                ((abs(at_row[s] - at_row[s+1]) + abs(at_col[s] - at_col[s+1]) = 1));


% no shortcuts
% constraint forall(r1,r2 in ROW, c1,c2 in COL)
%                  (abs(r1-r2) + abs(c1-c2) = 1 ->
%                   visit[r1,c1] = 0 \/ visit[r2,c2] = 0 \/
%                   abs(visit[r1,c1] - visit[r2,c2]) = 1);
constraint forall(s1, s2 in STEP where s1 + 1 < s2)
                (s1 <= steps /\ s2 <= steps -> abs(at_row[s1] - at_row[s2]) + abs(at_col[s1] - at_col[s2]) >= 2);

% not too much delay
constraint time <= timelimit;
var int: time = sum(r in ROW, c in COL)(delay[terrain[r,c]]*(visit[r,c] >= 1));
% var int: time = sum(s in 1..maxstep where at_row[s] != 0 /\ at_col[s] != 0)(delay[terrain[at_row[s], at_col[s]]]);


% minimize the number of soldiers traversed
solve minimize obj;
var int: obj = sum(r in ROW, c in COL)((visit[r,c] > 0)*soldier[r,c]);
                         

array[TERRAIN] of string: ter = [".", "#", "^", "C", "~"];

output 
       ["%"] ++ [show_int(2, at_row[s]) | s in 1..1] ++
       [ " " ++ ter[fix(terrain[r,c])] ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\n%"] ++
       [ if soldier[r,c] > 0 then show_int(2,soldier[r,c]) else " ." endif
         ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\n"] ++
       ["%"] ++
       [ if fix(visit[r,c]) > 0 then show_int(2,visit[r,c]) else " ." endif
         ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\nvisit = array2d(ROW,COL,\(visit));\nsteps = \(steps);\ntime = \(time);\nobj = \(obj);"]
%        ++ ["\n"] ++ 
%        [show_int(2, at_row[s]) | s in 1..maxstep]
%        ++ ["\n"] ++ 
%        [show_int(2, at_col[s]) | s in 1..maxstep]
       
      ;
