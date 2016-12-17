int: n; % Number of queens
array [1..n] of var 1..n: pos; % The col position of the queen at the ith row

predicate valid_pos(int: i, int: j, var int: pos_i, var int: pos_j) =
    pos_i     != pos_j        /\ % Two queens cannot be at the same col
    pos_i + i != pos_j + j /\ % Two queens cannot be at the diagonal
    pos_i - i != pos_j - j; % Two queens cannot be at the diagonal

constraint
forall (i in 1..n, j in i+1..n) (
    valid_pos(i, j, pos[i], pos[j])
);

ann: search_ann = int_search(pos, first_fail, indomain_median, complete);

solve :: search_ann satisfy;
