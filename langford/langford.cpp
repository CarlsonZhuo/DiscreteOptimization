#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;
using namespace std;

// A function that translate the model x representation
// into a normally understandable representation
int* decodeAsX(vector<int> x, int n, int k){
    // Each variables x[ik+j], where i ∈ {0, . . . , n−1} and 
    // j ∈ {0, . . . , k −1}, denotes the position where the jth 
    // occurrence of the number i + 1 appears in the sequence.
    int * result = new int[n*k];
    for (int i = 0; i < n; i ++){
        for (int j = 0; j < k; j ++){
            result[x[i*k+j]-1] = i+1;
        }
    }
    return result;
}

int* decodeAsY(vector<int> y, int n, int k){
    int * result = new int[n*k];
    for (int i = 0; i < n*k; i ++){
        result[i] = y[i]/k + 1;
    }
    return result;
}

class LangfordOptions : public Options {
public:
    int n, k;

    LangfordOptions(const char* s, int n0, int k0)
        : Options(s), n(n0), k(k0) {}

    void parse(int& argc, char* argv[]) {
        Options::parse(argc,argv);
        if (argc < 3) return;
        n = atoi(argv[1]);
        k = atoi(argv[2]);
    }
};


class Langford : public Script {
protected:
    int k, n;      
    IntVarArray x;
    int opt_num;
public:
    enum {
    MODEL_ONE,
    MODEL_TWO,
    MODEL_CHANNEL,
    MODEL_SYM,
    SEARCH_ONE,
    SEARCH_TWO,
    SEARCH_THREE,
    };

    Langford(const LangfordOptions& opt): Script(opt), k(opt.k), n(opt.n) {
        opt_num = opt.model();
        switch (opt.model()) {
            ///////////////////////////////////////////////////////////////
            ///////////////////////  Model  1 /////////////////////////////
            ///////////////////////////////////////////////////////////////
            // Each variables x[ik+j], where i ∈ {0, . . . , n−1} and 
            // j ∈ {0, . . . , k −1}, denotes the position where the jth 
            // occurrence of the number i + 1 appears in the sequence.
            case MODEL_ONE: { 
                cout << "solve using model 1\n";
                x = IntVarArray(*this, k*n, 1, k*n);
                distinct(*this, x, IPL_DOM);
                for (int i = 0; i < n; i ++){
                    for (int j = 0; j < k-1; j ++){
                        rel(*this, x[i*k+j+1] == x[i*k+j]+i+2);
                    }
                }
                branch(*this, x, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
            } break;
            ///////////////////////////////////////////////////////////////
            ///////////////////////  Model  2 /////////////////////////////
            ///////////////////////////////////////////////////////////////
            case MODEL_TWO: {
                cout << "solve using model 2\n";
                x = IntVarArray(*this, k*n, 0, k*n-1);
                distinct(*this, x, IPL_DOM);
                for (int i = 0; i < n; i ++){
                    for (int j = 1; j <= n*k - (k-1)*(i+2); j ++){
                        for(int c = 1; c < k; c ++){
                            rel(*this, !(x[j-1] == i*k) || (x[c*(i+2)+j-1] == i*k + c));
                        }
                    }
                }
                for (int i = 0; i < n; i ++){
                    for (int j = n*k - (k-1)*(i+2) + 1; j <= n*k; j ++){
                        rel(*this, x[j-1] != i*k);
                    }
                }
                branch(*this, x, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
            } break;
            ///////////////////////////////////////////////////////////////
            /////////////////  Channeling Model 1 and 2 ///////////////////
            ///////////////////////////////////////////////////////////////
            case MODEL_CHANNEL: {
                cout << "solve using model channel\n";
                x = IntVarArray(*this,k*n,1,k*n);
                IntVarArray y = IntVarArray(*this,k*n,0,k*n-1);
                // channeling
                channel(*this, x, 1, y, 0);
                // Constrain 1 for y
                distinct(*this, y);
                for (int i = 0; i < n; i ++){
                    for (int j = 1; j <= n*k - (k-1)*(i+2); j ++){
                        for(int c = 1; c < k; c ++){
                            rel(*this, !(y[j-1] == i*k) || (y[c*(i+2)+j-1] == i*k + c));
                        }
                    }
                }
                // Constrain 2 for y
                for (int i = 0; i < n; i ++){
                    for (int j = n*k - (k-1)*(i+2) + 1; j <= n*k; j ++){
                        rel(*this, y[j-1] != i*k);
                    }
                }
                // Constrain for x
                distinct(*this, x, IPL_DOM);
                for (int i = 0; i < n; i ++){
                    for (int j = 0; j < k-1; j ++){
                        rel(*this, x[i*k+j+1] == x[i*k+j]+i+2);
                    }
                }
                // Define different search methods
                switch (opt.search()){
                    case SEARCH_ONE: {
                        cout << "solve using search one\n";
                        branch(*this, x, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    }  break;
                    case SEARCH_TWO: {
                        cout << "solve using search two\n";
                        branch(*this, y, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    } break;
                    case SEARCH_THREE: {
                        cout << "solve using search three\n";
                        branch(*this, x+y, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    } break;
                }
            } break;
            ///////////////////////////////////////////////////////////////
            ///// Channeling Model 1 and 2 with symmetric breaking/////////
            ///////////////////////////////////////////////////////////////
            case MODEL_SYM: {
                cout << "solve using model channel with symmetric breaking\n";
                x = IntVarArray(*this,k*n,1,k*n);
                IntVarArray y = IntVarArray(*this,k*n,0,k*n-1);
                // channeling
                channel(*this, x, 1, y, 0);
                // Constrain 1 for y
                distinct(*this, y);
                for (int i = 0; i < n; i ++){
                    for (int j = 1; j <= n*k - (k-1)*(i+2); j ++){
                        for(int c = 1; c < k; c ++){
                            rel(*this, !(y[j-1] == i*k) || (y[c*(i+2)+j-1] == i*k + c));
                        }
                    }
                }
                // Constrain 2 for y
                for (int i = 0; i < n; i ++){
                    for (int j = n*k - (k-1)*(i+2) + 1; j <= n*k; j ++){
                        rel(*this, y[j-1] != i*k);
                    }
                }
                // Constrain for x
                distinct(*this, x, IPL_DOM);
                for (int i = 0; i < n; i ++){
                    for (int j = 0; j < k-1; j ++){
                        rel(*this, x[i*k+j+1] == x[i*k+j]+i+2);
                    }
                }
                // Symmetry breaking
                rel(*this, x[0] < (n*k/2));
                // Define different search methods
                switch (opt.search()){
                    case SEARCH_ONE: {
                        cout << "solve using search one\n";
                        branch(*this, x, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    }  break;
                    case SEARCH_TWO: {
                        cout << "solve using search two\n";
                        branch(*this, y, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    } break;
                    case SEARCH_THREE: {
                        cout << "solve using search three\n";
                        branch(*this, x+y, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
                    } break;
                }
            } break;
        }
    }
    
    virtual void print(ostream& os) const {
        // Copy the content of x into tmpX
        vector<int> tmpX;
        for(int i = 0; i < n*k; i ++){
            tmpX.push_back(x[i].val());
        }
        // Decode tmpX
        // If model 2, use decode Y
        // Else, use decode X
        int * result;
        if (opt_num == MODEL_TWO)
            result = decodeAsY(tmpX, n, k);
        else
            result = decodeAsX(tmpX, n ,k);
        for (int i = 0; i < n*k; i ++)
            os << result[i] << " ";
        os << endl;
    }

    Langford(bool share, Langford& l): Script(share, l) {
        opt_num = l.opt_num;
        k = l.k;
        n = l.n;
        x.update(*this, share, l.x);
    }
    
    virtual Space* copy(bool share) {
        return new Langford(share, *this);
    }
};

int main(int argc, char* argv[]) {
    LangfordOptions opt("Langford",9,3);
    opt.model(Langford::MODEL_CHANNEL);
    opt.model(Langford::MODEL_ONE, "1");
    opt.model(Langford::MODEL_TWO, "2");
    opt.model(Langford::MODEL_CHANNEL, "3");
    opt.model(Langford::MODEL_SYM, "4");

    opt.search(Langford::SEARCH_THREE);
    opt.search(Langford::SEARCH_ONE, "1");
    opt.search(Langford::SEARCH_TWO, "2");
    opt.search(Langford::SEARCH_THREE, "3");

    opt.parse(argc, argv);
    opt.solutions(0);

    Script::run<Langford, DFS, LangfordOptions>(opt);

    return 0;
}

