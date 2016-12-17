#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>
#include <stdio.h>
#include <stdlib.h>

using namespace Gecode;
using namespace std;


class Move : public Propagator {
protected:
    Int::IntView x0, x1;
    int n;
public:
    // posting
    Move(Space& home, Int::IntView y0, Int::IntView y1, int n) 
        : Propagator(home), x0(y0), x1(y1), n(n) {
        x0.subscribe(home,*this,Int::PC_INT_DOM);
        x1.subscribe(home,*this,Int::PC_INT_DOM);
    }
    static ExecStatus post(Space& home, 
                           Int::IntView x0, Int::IntView x1, int n) {
        (void) new (home) Move(home,x0,x1,n);
        return ES_OK;
    }
    // disposal
    virtual size_t dispose(Space& home) {
        x0.cancel(home,*this,Int::PC_INT_DOM);
        x1.cancel(home,*this,Int::PC_INT_DOM);
        (void) Propagator::dispose(home);
        return sizeof(*this);
    }
    // copying
    Move(Space& home, bool share, Move& p) 
        : Propagator(home,share,p) {
        n = p.n;
        x0.update(home,share,p.x0);
        x1.update(home,share,p.x1);
    }
    virtual Propagator* copy(Space& home, bool share) {
        return new (home) Move(home,share,*this);
    }
    // cost computation
    virtual PropCost cost(const Space&, const ModEventDelta&) const {
        return PropCost::binary(PropCost::LO);
    }
    // re-scheduling
    virtual void reschedule(Space& home) {
        x0.reschedule(home,*this,Int::PC_INT_DOM);
        x1.reschedule(home,*this,Int::PC_INT_DOM);
    }
    // propagation
    virtual ExecStatus propagate(Space& home, const ModEventDelta&)  {
        const int valid_move[8][2] = {
            {-2,-1}, {-2,1}, {2,-1}, {2,1},
            {1,-2}, {1,2}, {-1,-2}, {-1,2}
        };
        // Prune x1
        for(int i = x1.min(); i <= x1.max(); i ++){
            if (!x1.in(i)) continue; // so that i is in the dom of x1
            int x1_row = (i-1) / n;
            int x1_col = (i-1) % n;

            int to_delete = 1;
            for(int m = 0; m < 8; m ++){
                int valid_x0_row = x1_row + valid_move[m][0];
                int valid_x0_col = x1_col + valid_move[m][1];
                bool row_valid = (valid_x0_row >= 0 && valid_x0_row < n);
                bool col_valid = (valid_x0_col >= 0 && valid_x0_col < n);
                // If (1) row (2) col are valid, check (3) whether the move is in the dom
                if (row_valid && col_valid && x0.in(valid_x0_row * n + valid_x0_col + 1)){
                    to_delete = 0;
                    break;
                }
            }
            if (to_delete){
                ModEvent me = x1.nq(home, i);
                if (me_failed(me)) return ES_FAILED;
            }
        }
        // Prune x0. Symmetric with prune x1.
        for(int i = x1.min(); i <= x1.max(); i ++){
            if (!x0.in(i)) continue; // so that i is in the dom of x1
            int x0_row = (i-1) / n;
            int x0_col = (i-1) % n;

            int to_delete = 1;
            for(int m = 0; m < 8; m ++){
                int valid_x1_row = x0_row + valid_move[m][0];
                int valid_x1_col = x0_col + valid_move[m][1];
                bool row_valid = (valid_x1_row >= 0 && valid_x1_row < n);
                bool col_valid = (valid_x1_col >= 0 && valid_x1_col < n);
                // If (1) row (2) col are valid, check (3) whether the move is in the dom
                if (row_valid && col_valid && x1.in(valid_x1_row * n + valid_x1_col + 1)){
                    to_delete = 0;
                    break;
                }
            }
            if (to_delete){
                ModEvent me = x0.nq(home, i);
                if (me_failed(me)) return ES_FAILED;
            }
        }

        if (x0.assigned() && x1.assigned())
            return home.ES_SUBSUMED(*this);
        else 
            return ES_NOFIX;
    }
};

// Entrance Function for the customized propagator
void move(Space& home, IntVar x, IntVar y, int n) {
    // constraint post function
    Int::IntView y0(x), y1(y);
    if (Move::post(home,y0,y1,n) != ES_OK)
        home.fail();
}

class KnightsOption : public Options {
public:
    int n;

    KnightsOption(const char* s, int n0)
        : Options(s), n(n0) {}

    void parse(int& argc, char* argv[]) {
        Options::parse(argc,argv);
        if (argc < 2) return;
        n = atoi(argv[1]);
    }
};


class Knights : public Script {
protected:
    int n;
    IntVarArray x;

public:
    Knights(const KnightsOption& opt): Script(opt), n(opt.n){
        x = IntVarArray(*this, n*n, 1, n*n);

        for(int i = 0; i < n*n-1; i ++)
            move(*this, x[i], x[i+1], n); // by default, n = 6
        move(*this, x[0], x[n*n-1], n);

        distinct(*this, x);

        rel(*this, x[0] == 1);
        rel(*this, x[26] == 22);
        rel(*this, x[17] == 23);
        rel(*this, x[8] == 25);

        branch(*this, x, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
    }
    
    virtual void print(ostream& os) const {
        // Convert the var into readable keyboard
        vector<int> y(n*n);
        for (int i = 0; i < n*n; i ++)
            y[x[i].val()-1] = i; 
        // Print the keyboard
        for(int i = 0; i < n; i ++){
            for (int j = 0; j < n; j ++){
                cout << y[i*n + j] << ", ";
            }
            cout << endl;
        }
        os << endl;
    }
    // Copy constructor
    Knights(bool share, Knights& old_k): Script(share, old_k) {
        n = old_k.n;
        x.update(*this, share, old_k.x);
    }

    virtual Space* copy(bool share) {
        return new Knights(share, *this);
    }
};


int main(int argc, char* argv[]) {
    KnightsOption opt("Knights Move", 6);  // by default, n = 6
    opt.parse(argc, argv);
    opt.solutions(0);

    Script::run<Knights, DFS, KnightsOption>(opt);

    return 0;
}

// How I "Compile":
// Copy and paste the code to overwrite one of the example cpp file
// under gecode-5.0.0/examples. Then make && make install.
