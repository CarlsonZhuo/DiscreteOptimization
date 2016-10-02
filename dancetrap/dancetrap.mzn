% Beauty Trap
% Perform the most seductive dance

enum LEGS = {spin, leap, waltz, curtsey, prep, stand};
enum ARMS = {beckon, out, up, wrapped, neutral};
enum FACE = {smile, wink, batt, think, glow, blank};

int: maxlen;
set of int: STEP = 1..maxlen;
array[LEGS] of int: maxlegs;
array[ARMS] of int: maxarms;
array[FACE] of int: maxface;
constraint assert(maxlegs[stand] >= maxlen, "maxlegs[stand] smaller than maxlen");
constraint assert(maxarms[neutral] >= maxlen, "maxarms[neutral] smaller than maxlen");
constraint assert(maxface[blank] >= maxlen, "maxface[blank] smaller than maxlen");
array[LEGS,ARMS] of int: dance_value;
array[ARMS,FACE] of int: entice_value;
constraint assert(dance_value[stand,neutral] = 0, "incorrect dance_value array");
constraint assert(entice_value[neutral,blank] = 0, "incorrect entice_value array");
int: boredom; % how bored each step make the viewer

var STEP: len;
array[STEP] of var LEGS: legs;
array[STEP] of var ARMS: arms;
array[STEP] of var FACE: face;

% Constraint, len is the biggest ... in LEGS, ARMS, FACE
constraint forall(i in STEP)(i > len -> legs[i] = stand /\ arms[i] = neutral /\ face[i] = blank );

% Constraint1: A move cannot be used for too much time
% constraint forall(leg_move in LEGS)(
%                  sum([ 1 | i in STEP where legs[i] = leg_move]) <= maxlegs[leg_move]);
% constraint forall(arm_move in ARMS)(
%                  sum([ 1 | i in STEP where arms[i] = arm_move]) <= maxarms[arm_move]);
% constraint forall(face_exp in FACE)(
%                 sum([ 1 | i in STEP where face[i] = face_exp]) <= maxface[face_exp]);
include "globals.mzn";
constraint global_cardinality_low_up(legs, LEGS, [0| i in LEGS], maxlegs);
constraint global_cardinality_low_up(arms, ARMS, [0| i in LEGS], maxarms);
constraint global_cardinality_low_up(face, FACE, [0| i in LEGS], maxface);

% spin, leap, waltz, curtsey, prep, stand
include "regular.mzn";
array[1..7, FACE] of int: legs_re =
[| 2, 0, 4, 5, 6, 7       % Init, 1
 | 0, 0, 0, 5, 6, 7       % Spin, 2
 | 2, 0, 4, 0, 0, 7       % Leap, 3
 | 2, 0, 4, 5, 6, 7       % Waltz, 4
 | 2, 0, 4, 5, 0, 7       % Curtsey, 5
 | 2, 3, 4, 5, 6, 7       % Prep, 6
 | 2, 0, 4, 5, 6, 7 |];  % Stand, 7


% beckon, h_out, h_up, h_wrap, neutral
array[1..6, ARMS] of int: arms_re =
[| 0, 3, 4, 0, 6
 | 0, 3, 4, 5, 6       % Beckon, 2
 | 2, 0, 4, 0, 6       % h_out, 3
 | 2, 3, 0, 0, 6       % h_up, 4
 | 0, 3, 4, 0, 6       % h_wrap, 5
 | 0, 3, 4, 5, 6 |];  % Neutral, 6

% She cannot make more than two of the same gestures in a row except blank. 
% She cannot think directly after smile (ing) or batt (ing) her eyelids.
array[1..7, FACE] of int: face_re =
[| 2, 3, 4, 5, 6, 7      % Initial State
 | 2, 3, 4, 0, 6, 7      % Smile, 2
 | 2, 3, 4, 5, 6, 7      % Wink, 3
 | 2, 3, 4, 0, 6, 7      % Batt, 4
 | 2, 3, 4, 5, 6, 7      % Think, 5
 | 2, 3, 4, 5, 6, 7      % Glow, 6
 | 2, 3, 4, 5, 6, 7 |]; % Blank, 7

constraint forall(s in 1..maxlen-2) (face[s] = face[s+1] /\ face[s+1] = face[s+2] -> face[s] = blank);

constraint regular(legs, 7, 6, legs_re, 1, 1..7);
constraint regular(arms, 6, 5, arms_re, 1, 1..6);
constraint regular(face, 7, 6, face_re, 1, 1..7);

constraint forall(s in STEP) (dance_value[legs[s], arms[s]] >= 0);
constraint forall(s in STEP) (entice_value[arms[s], face[s]] >= 0);

% She can waltz at most three times in a row.
% In between any waltz and a following curtsey there must be a stand.
constraint forall(s in 1..maxlen-2) (legs[s]=waltz /\ legs[s+1]=waltz -> legs[s+2]!=waltz);
% constraint forall(s in 1..maxlen-2) (legs[s]=waltz /\ legs[s+2]=curtsey -> legs[s+1] = stand );
constraint forall(s1, s2 in 1..maxlen where s1 < s2) (legs[s1]=waltz /\ legs[s2]=curtsey -> exists(k in s1..s2)(legs[k] = stand ));

var int: obj = sum(s in 1..len) (dance_value[legs[s], arms[s]] + entice_value[arms[s], face[s]]) - boredom*len;
solve maximize obj;

output ["len = \(len);\n" , "legs = \(legs);\n", "arms = \(arms);\n", "face = \(face);\n","obj = \(obj);"];