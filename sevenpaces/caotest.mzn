var 0..9: C;
var 0..9: A;
var 0..9: O;
var 0..9: Z;
var 0..9: H;
var 0..9: I;
var 0..9: P;
var 0..9: T;
var 0..9: E;
var 0..9: S;


constraint    
           100*C + 10*A + O + 100*Z + 10*H + I + 100*C + 10*A + O + 10*P + I
           = 1000*T + 100*E + 10*S + T;
           
constraint P = 3 * Z;
constraint O = 0;
constraint C != 0;
constraint Z != 0;
constraint T != 0;

include "alldifferent.mzn";
constraint alldifferent([C,A,O,Z,H,I,P,T,E,S]);

solve satisfy;