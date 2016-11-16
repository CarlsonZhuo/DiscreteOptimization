int: length; % height of lake
set of int: LENGTH = 0..length-1;
int: width; % width of lake
set of int: WIDTH = 0..width-1;

int: ntypes;  % number of types of ship
set of int: TYPE = 1..ntypes;
array[TYPE] of int: number;         % number of each type of ship
array[TYPE] of set of SHAPE: config; % configs for each type of ship

int: nshapes; % number of shapes
set of int: SHAPE = 1..nshapes;
set of int: SHAPE0 = 0..nshapes;
array[SHAPE] of set of ROFF: shape;

int: nroff; % number of rectangle offsets
set of int: ROFF = 1..nroff;
array[ROFF,1..4] of int: rectoff; % x offset, y offset, width, height

int: total_ships = sum(number);
set of int: SHIP = 1..total_ships;
array[SHIP] of var LENGTH:  x;
array[SHIP] of var WIDTH:   y;
array[SHIP] of var SHAPE0:  k;

array[LENGTH] of WIDTH: mist; % mist starts at this width, goes downward
array[WIDTH] of int: arrow;  % number of arrows that arrive at this height
array[TYPE] of int: price;
int: budget;
enum STAGE = {A,B,C,D,E,F};
STAGE: stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% include "globals.mzn";
include "geost.mzn";

array[ROFF, 1..2] of int: rsize = array2d(ROFF, 1..2, [rectoff[i,j]|i in ROFF, j in 3..4]);

array[ROFF, 1..2] of int: roff = array2d(ROFF, 1..2, [rectoff[i,j]|i in ROFF, j in 1..2]);

array[SHIP, 1..2] of var int: coord;
constraint forall(i in SHIP)(
    coord[i,1] = x[i] /\ coord[i,2] = y[i]
);

% Mapping ships to type
array[SHIP] of var 1..ntypes: sid_to_type;
constraint sid_to_type[1] = 1;
constraint forall(sid in 2..total_ships)(
    if sum(t in 1..sid_to_type[sid-1])(number[t]) >= sid then
    sid_to_type[sid] = sid_to_type[sid-1] 
    else sid_to_type[sid] = sid_to_type[sid-1] + 1 endif
);

var int: tarrows;

%%%%%%%%%%%%%%%%%%%%%Stage A%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
constraint stage = A -> tarrows = 0;
constraint stage = A -> forall(sid in SHIP)(k[sid] = 1);

% Cannot lie outside the river
constraint stage = A ->
forall(sid in SHIP)(x[sid] + rectoff[sid_to_type[sid], 3] < length);
constraint stage = A ->
forall(sid in SHIP)(y[sid] + rectoff[sid_to_type[sid], 4] < width);

% No overlap
constraint stage = A ->
forall(sid1, sid2 in SHIP where sid1 < sid2)(
    x[sid1] >= x[sid2] + rectoff[sid_to_type[sid2], 3] \/ 
    x[sid2] >= x[sid1] + rectoff[sid_to_type[sid1], 3] \/
    y[sid1] >= y[sid2] + rectoff[sid_to_type[sid2], 4] \/ 
    y[sid2] >= y[sid1] + rectoff[sid_to_type[sid1], 4]
);

% Symetric breaking - ship of the same type should be ordered
constraint stage = A ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
);

%%%%%%%%%%%%%%%%%Stage B%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
constraint stage = B -> tarrows = 0;
constraint stage = B -> forall(sid in SHIP)(k[sid] = 1);

% Cannot lie outside the river
constraint stage = B ->
forall(sid in SHIP)(
    forall(s in shape[sid_to_type[sid]])(
        y[sid] + rectoff[s, 2] + rectoff[s, 4] <= width /\
        x[sid] + rectoff[s, 1] + rectoff[s, 3] <= length
    )
);

% No overlap
constraint stage = B ->
forall(sid1, sid2 in SHIP where sid1 < sid2)(
    forall(s1 in shape[sid_to_type[sid1]], s2 in shape[sid_to_type[sid2]])(
    x[sid1] + rectoff[s1,1] >= x[sid2] + rectoff[s2,1] + rectoff[s2,3] \/ 
    x[sid2] + rectoff[s2,1] >= x[sid1] + rectoff[s1,1] + rectoff[s1,3] \/
    y[sid1] + rectoff[s1,2] >= y[sid2] + rectoff[s2,2] + rectoff[s2,4] \/ 
    y[sid2] + rectoff[s2,2] >= y[sid1] + rectoff[s1,2] + rectoff[s1,4]
    )
);

% Symetric breaking - ship of the same type should be ordered
constraint stage = B ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
);

%%%%%%%%%%%%%%%%%%%%Stage C%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
constraint stage = C -> tarrows = 0;
constraint stage = C -> forall(sid in SHIP)(k[sid] = 1);

% Cannot lie outside the river
constraint stage = C ->
forall(sid in SHIP)(
    forall(s in shape[sid_to_type[sid]])(
        y[sid] + rectoff[s, 2] + rectoff[s, 4] <= width /\
        x[sid] + rectoff[s, 1] + rectoff[s, 3] <= length
    )
);

% No overlap
constraint stage = C ->
forall(sid1, sid2 in SHIP where sid1 < sid2)(
    forall(s1 in shape[sid_to_type[sid1]], s2 in shape[sid_to_type[sid2]])(
    x[sid1] + rectoff[s1,1] >= x[sid2] + rectoff[s2,1] + rectoff[s2,3] \/ 
    x[sid2] + rectoff[s2,1] >= x[sid1] + rectoff[s1,1] + rectoff[s1,3] \/
    y[sid1] + rectoff[s1,2] >= y[sid2] + rectoff[s2,2] + rectoff[s2,4] \/ 
    y[sid2] + rectoff[s2,2] >= y[sid1] + rectoff[s1,2] + rectoff[s1,4]
    )
);

% Symetric breaking - ship of the same type should be ordered
constraint stage = C ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
);

% Hiden under mist
constraint stage = C ->
forall(tmpX in LENGTH)(
    forall(sid in SHIP)(
        forall(s in shape[sid_to_type[sid]])(
            x[sid] + rectoff[s,1] > tmpX \/
            x[sid] + rectoff[s,1] + rectoff[s,3] < tmpX \/
            y[sid] + rectoff[s,2] >= mist[tmpX]
        )
    )
);


%%%%%%%%%%%%%%%%%%%%Stage D%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
constraint stage = D -> 
forall(sid in SHIP)(
    k[sid] = sid_to_type[sid]
);

% Cannot lie outside the river
constraint stage = D ->
forall(sid in SHIP)(
    forall(s in shape[sid_to_type[sid]])(
        y[sid] + rectoff[s, 2] + rectoff[s, 4] <= width /\
        x[sid] + rectoff[s, 1] + rectoff[s, 3] <= length
    )
);

% No overlap
constraint stage = D ->
forall(sid1, sid2 in SHIP where sid1 < sid2)(
    forall(s1 in shape[sid_to_type[sid1]], s2 in shape[sid_to_type[sid2]])(
    x[sid1] + rectoff[s1,1] >= x[sid2] + rectoff[s2,1] + rectoff[s2,3] \/ 
    x[sid2] + rectoff[s2,1] >= x[sid1] + rectoff[s1,1] + rectoff[s1,3] \/
    y[sid1] + rectoff[s1,2] >= y[sid2] + rectoff[s2,2] + rectoff[s2,4] \/ 
    y[sid2] + rectoff[s2,2] >= y[sid1] + rectoff[s1,2] + rectoff[s1,4]
    )
);

% Symetric breaking - ship of the same type should be ordered
constraint stage = D ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
);

% Hiden under mist
constraint stage = D ->
forall(tmpX in LENGTH)(
    forall(sid in SHIP)(
        forall(s in shape[sid_to_type[sid]])(
            x[sid] + rectoff[s,1] > tmpX \/
            x[sid] + rectoff[s,1] + rectoff[s,3] < tmpX \/
            y[sid] + rectoff[s,2] >= mist[tmpX]
        )
    )
);

% count arrows
constraint stage = D -> 
tarrows = sum(sid in SHIP)(
    sum(s in shape[sid_to_type[sid]])(
        sum(tmpY in 0..rectoff[s,4]-1)(
            arrow[y[sid]+rectoff[s,2]+tmpY]*rectoff[s,3] 
        )
    )
);

%%%%%%%%%%%%%%%%%%%%Stage E%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Use kind instead of k in stage E
array[SHIP] of var SHAPE:  kind;

constraint stage = E ->
geost_bb(2,
    rsize,
    roff,
    shape,
    coord,
    kind,
    [0,0],
    [length, width]
);

% Symetric breaking - ship of the same type should be ordered
constraint stage = E ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
);

% Hiden under mist
constraint stage = E ->
forall(tmpX in LENGTH)(
    forall(sid in SHIP)(
        forall(s in shape[kind[sid]])(
            x[sid] + rectoff[s,1] > tmpX \/
            x[sid] + rectoff[s,1] + rectoff[s,3] <= tmpX \/
            y[sid] + rectoff[s,2] >= mist[tmpX]
        )
    )
);

% count arrows
constraint stage = E -> 
tarrows = sum(sid in SHIP)(
    sum(s in shape[kind[sid]])(
        sum(tmpY in 0..rectoff[s,4]-1)(
            arrow[y[sid]+rectoff[s,2]+tmpY]*rectoff[s,3] 
        )
    )
);

% k should be one of the config
constraint stage = E ->
forall(sid in SHIP)(
    kind[sid] in config[sid_to_type[sid]]
);

%%%%%%%%%%%%%%%%%%%%Stage F%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

array[1..nroff+1, 1..2] of int: rsize0 = array2d(1..nroff+1, 1..2, [if i <= nroff then rectoff[i,j] else 0 endif|i in 1..nroff+1, j in 3..4]);

array[1..nroff+1, 1..2] of int: roff0 = array2d(1..nroff+1, 1..2, [if i <= nroff then rectoff[i,j] else 0 endif|i in 1..nroff+1, j in 1..2]);

array[1..nshapes+1] of set of 1..nroff+1: shape0 = [if i <= nshapes then shape[i] else {nroff+1} endif|i in 1..nshapes+1];

array[SHIP] of var 1..nshapes+1:  kind0;
constraint stage = F ->
forall(sid in SHIP)(
    if k[sid] = 0 then kind0[sid] = nshapes+1
    else kind0[sid] = k[sid]
    endif
);

constraint stage = F ->
geost_bb(2,
    rsize0,
    roff0,
    shape0,
    coord,
    kind0,
    [0,0],
    [length, width]
);


% Symetric breaking - ship of the same type should be ordered
constraint stage = F ->
forall(sid1, sid2 in SHIP where sid1 < sid2 /\ sid_to_type[sid1] = sid_to_type[sid2])(
     if k[sid1] = 0 \/ k[sid2] = 0 then true else
    (x[sid1] = x[sid2] /\ y[sid1] > y[sid2]) \/
    (x[sid1] > x[sid2])
    endif
);

% Hiden under mist
constraint stage = F ->
forall(tmpX in LENGTH)(
    forall(sid in SHIP)(
        if k[sid] = 0 then true else
        forall(s in shape[k[sid]])(
            x[sid] + rectoff[s,1] > tmpX \/
            x[sid] + rectoff[s,1] + rectoff[s,3] <= tmpX \/
            y[sid] + rectoff[s,2] >= mist[tmpX]
        )
        endif
    )
);

% Within budget
constraint stage = F ->
sum(sid in SHIP where k[sid]!=0)(price[sid_to_type[sid]]) <= budget;

% k should be one of the config
constraint stage = F ->
forall(sid in SHIP)(
    k[sid] in config[sid_to_type[sid]] \/ k[sid] = 0
);

% count arrows
constraint stage = F -> 
tarrows = sum(sid in SHIP where k[sid] != 0)(
    sum(s in shape[k[sid]])(
        sum(tmpY in 0..rectoff[s,4]-1)(
            arrow[y[sid]+rectoff[s,2]+tmpY]*rectoff[s,3] 
        )
    )
);

% 
constraint stage = F ->
forall(sid in SHIP where k[sid] = 0)(
    x[sid] = 0 /\ y[sid] = 0
);

solve maximize tarrows;

output
       ["x = ["] ++ [show_int(2, x[i]) ++ if i != total_ships then ", " else "" endif | i in SHIP] ++ ["];\n"]
       ++ ["y = ["] ++ [show_int(2, y[i]) ++ if i != total_ships then ", " else "" endif | i in SHIP] ++ ["];\n"]
       ++ ["k = ["] ++ 
           if stage = E then 
               [show_int(2, kind[i]) ++ if i != total_ships then ", " else "" endif | i in SHIP] ++ ["];\n"] 
           else 
               [show_int(2, k[i]) ++ if i != total_ships then ", " else "" endif | i in SHIP] ++ ["];\n"]
           endif    
       ++ ["tarrows = " ++ show(tarrows) ++ ";"]
%        ++ [show(shape0[i]) ++ ", " | i in 1..nshapes+1]
       ;