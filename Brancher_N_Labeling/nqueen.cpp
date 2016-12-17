
#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

#include <iostream>

using namespace Gecode;
using namespace std;


class int_val_med : public Brancher { 
protected: 
    ViewArray<Int::IntView> x; 
    mutable int start;
    // choice definition 
    class PosVal : public Choice { 
    public: 
        int pos; 
        int val; 
        PosVal(const int_val_med& b, int p, int v)
            : Choice(b,2), pos(p), val(v) {} 
        virtual size_t size(void) const {   
            return sizeof(*this); 
        }
        virtual void archive(Archive& e) const { 
            Choice::archive(e); 
            e << pos << val; 
        } 
    }; 
public: 
    int_val_med(Home home, ViewArray<Int::IntView>& x0)
        : Brancher(home), x(x0), start(0) {} 
    //posting
    static void post(Home home, ViewArray<Int::IntView>& x) { 
        (void) new (home) int_val_med(home,x); 
    } 
    //disposal
    virtual size_t dispose(Space& home) { 
        (void) Brancher::dispose(home); 
        return sizeof(*this); 
    } 
    //choice 
    virtual const Choice*  choice(Space& home) {
        // Find the variable with min domain
        int p = start;
        unsigned int s = x[p].size();
        for (int i=start+1; i<x.size(); i++){
            if (!x[i].assigned() && (x[i].size() < s)) {
                p = i; s = x[p].size();
            }            
        }
        // Find the m/2
        int counter = x[p].size() / 2; // Loop until counter deduced to 1
        int cur_val = x[p].min()-1;
        while(counter > 0){
            cur_val ++;
            if (x[p].in(cur_val))
                counter --;
        }
        return new PosVal(*this,p,cur_val);
        // return new PosVal(*this,p,x[p].min());
    }
    virtual const Choice*  choice(const Space& home, Archive& e) {
        int pos, val;
        e>>pos>>val;
        return new PosVal(*this, pos, val);
    }
    //copy
    int_val_med(Space& home, bool share, int_val_med& b) 
        : Brancher(home,share,b), start(b.start) { 
        x.update(home,share,b.x); 
    } 
    virtual Brancher* copy(Space& home, bool share) { 
        return new (home) int_val_med(home,share,*this); 
    }
    // status 
    virtual bool status(const Space& home) const { 
        for (int i=start; i<x.size(); i++)
            if(!x[i].assigned()){
                start = i;
                return true;
            }
        return false; 
    } 
    // commit 
    virtual ExecStatus commit(Space& home, 
                              const Choice& c, 
                              unsigned int a) {
        const PosVal& pv = static_cast<const PosVal&>(c); 
        int pos=pv.pos, val=pv.val; 
        if (a == 0) 
            return me_failed(x[pos].eq(home,val)) ? ES_FAILED : ES_OK; 
        else 
            return me_failed(x[pos].nq(home,val)) ? ES_FAILED : ES_OK; 
    } 
    // print 
    virtual void print(const Space& home, const Choice& c, unsigned int a, std::ostream& o) const { 
        const PosVal& pv = static_cast<const PosVal&>(c); 
        int pos=pv.pos, val=pv.val; 
        if (a == 0) 
            o << "x[" << pos << "] = " << val; 
        else 
            o << "x[" << pos << "] != " << val; 
    } 
}; 

 void int_val_med(Home home, const IntVarArgs& x) { 
    if (home.failed()) 
        return; 
    ViewArray<Int::IntView> y(home,x); 
    int_val_med::post(home,y); 
 } 



class NQueensOption : public Options {
public:
    int n;

    NQueensOption(const char* s, int n0)
        : Options(s), n(n0) {}

    void parse(int& argc, char* argv[]) {
        Options::parse(argc,argv);
        if (argc < 2) return;
        n = atoi(argv[1]);
    }
};


class NQueens : public Space {
protected:
    IntVarArray sol;
    int n;

public:
    enum {
    SEARCH_ONE,
    SEARCH_TWO,
    };

    NQueens(const NQueensOption& opt): n(opt.n){
        sol = IntVarArray(*this, n, 1, n);
        n = n;
        for (int i = 0; i<n; i++)
            for (int j = i+1; j<n; j++) {
                rel(*this, sol[i] != sol[j]);
                rel(*this, sol[i]+i != sol[j]+j);
                rel(*this, sol[i]-i != sol[j]-j);
            } 
        switch (opt.search()){
            case SEARCH_ONE: {
                cout << "solve using search one\n";
                branch(*this, sol, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
            }  break;
            case SEARCH_TWO: {
                cout << "solve using search two\n";
                // branch(*this, sol, INT_VAR_SIZE_MIN(), INT_VAL_MED());
                int_val_med(*this, sol);
            } break;
        }
    }
  
    NQueens(bool share, NQueens &s) : Space(share, s){
        n = s.n;
        sol.update(*this, share, s.sol);
    }
    virtual Space* copy(bool share){
        return new NQueens(share, *this);
    }
    void print(ostream& os) const {
        os << sol << std::endl;
    }
};

int main(int argc, char* argv[]){
    NQueensOption opt("NQueens Problem", 6);
    opt.solutions(1);
    opt.search(NQueens::SEARCH_ONE);
    opt.search(NQueens::SEARCH_ONE, "1");
    opt.search(NQueens::SEARCH_TWO, "2");

    opt.parse(argc, argv);

    Script::run<NQueens, DFS, NQueensOption>(opt);

    return 0;
}


// How I "Compile":
// Copy and paste the code to overwrite one of the example cpp file
// under gecode-5.0.0/examples. Then make && make install.
