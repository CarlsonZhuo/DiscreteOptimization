var 0..9: B;
var 0..9: E;
var 0..9: A;
var 0..9: N;
var 0..9: S;
var 0..9: C;
var 0..9: R;
var 0..9: Y;
var 0..9: I;
var 0..9: G;


constraint    
           20000 * B + 2000 * E + 200 * A + 20 * N + 2 * S
         = 100000 * C + 10000 * R + 1000 * Y + 100 * I + 10 * N + G;

include "alldifferent.mzn";
constraint alldifferent([B, E, A, N, S, C, R, Y, I, G]);

constraint B != 0;
constraint C != 0;

solve satisfy;