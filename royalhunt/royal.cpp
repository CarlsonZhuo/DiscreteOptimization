#include <fstream>
#include <string>
#include <iostream>
#include <vector>
#include <stdlib.h>

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;
using namespace std;


/* This function is used for splitting a long string
 */
void split(const string& src, const string& separator, vector<string>& dest)
{
    string str = src;
    string substring;
    string::size_type start = 0, index;

    do
    {
        index = str.find_first_of(separator,start);
        if (index != string::npos)
        {    
            substring = str.substr(start,index-start);
            dest.push_back(substring);
            start = str.find_first_not_of(separator,index);
            if (start == string::npos) return;
        }
    }while(index != string::npos);
      
    //the last token
    substring = str.substr(start);
    dest.push_back(substring);
}

/* This function read the data accordingly
 * The data are read and put into several vector for further use
 * They are passed by reference, so you shall first define the corresponding vectors in your main functions, and then call this function to read the data in.
 * The names of the vector should explain what data are put in

 * The name of the data file should be passed to filename
 * The enjoy values are put in an one-dimentional array
 */
void readData(char filename[], 
              int &n, int &m, 
              vector<int> &rank, 
              vector<int> &ability, 
              vector<int> &beauty, 
              vector<int> &speed, 
              vector<int> &enjoy){
    ifstream inputFile(filename);

    if (!inputFile.is_open()){
        cout << "input file does not exists!\n";
        exit(0);
    }

    string line;

    // read n
    getline(inputFile, line);
    n = atoi(line.c_str());

    // rank
    getline(inputFile, line);
    vector<string> ranks;
    split(line, " ", ranks);
    for (int rider = 0; rider < n; rider++){
        rank.push_back(atoi(ranks[rider].c_str()));
    }

    // ability
    getline(inputFile, line);
    vector<string> abilities;
    split(line, " ", abilities);
    for (int rider = 0; rider < n; rider++){
        ability.push_back(atoi(abilities[rider].c_str()));
    }
  
    // read m
    getline(inputFile, line);
    m = atoi(line.c_str());

    // beauty
    getline(inputFile, line);
    vector<string> beauties;
    split(line, " ", beauties);
    for (int horse = 0; horse < m; horse++){
        beauty.push_back(atoi(beauties[horse].c_str()));
    }

    // speead
    getline(inputFile, line);
    vector<string> speeds;
    split(line, " ", speeds);
    for (int horse = 0; horse < m; horse++){
        speed.push_back(atoi(speeds[horse].c_str()));
    }

    // enjoyment
    vector<string> enjoy_values;
    for (int rider = 0; rider < n; rider++){
        enjoy_values.clear();
        getline(inputFile, line);
        split(line, " ", enjoy_values);
        for (int horse = 0; horse < m; horse++){
            enjoy.push_back(atoi(enjoy_values[horse].c_str()));
        }
    }
    inputFile.close();
}

// This function appends dummy horses or dummy person
// to the original data.
void cleanData(int &n, int &m, int & nD,
              vector<int> &rank, 
              vector<int> &ability, 
              vector<int> &beauty, 
              vector<int> &speed, 
              vector<int> &enjoy){
    nD = max(n, m);

    if (n > m){
        // we have more people than horses
        // hence append dummy horses
        for (int i = 0; i < n-m; i ++){
            beauty.push_back(0);
            speed.push_back(0);
        }
        vector<int> newEnjoy;
        for (int row = 0; row < n; row ++){
            for (int col = 0; col < n; col ++){
                if(col < m)
                    newEnjoy.push_back(enjoy[row*m + col]);
                else
                    newEnjoy.push_back(0);
            }
        }
        enjoy = newEnjoy;
    }
    else if (n < m){
        // we have more horses than people
        // hence append dummy people
        for (int i = 0; i < m-n; i ++){
            rank.push_back(0);
            ability.push_back(0);
        }
        for(int newRow = 0; newRow < m-n; newRow ++){
            for(int col = 0; col < m; col ++){
                enjoy.push_back(0);
            }
        }
    }
}


class royalhuntOptions : public Options {
public:
    char* filename;

    royalhuntOptions(const char* s)
        : Options(s) {}

    void parse(int& argc, char* argv[]) {
        Options::parse(argc,argv);
        if (argc != 2) return;
        filename = argv[1];
    }
};


class royalhunt : public Script {
protected:
    int n; // Number of court members
    int m; // Number of horse
    int nD; // nD = max(n, m);
    vector<int> rank;
    vector<int> ability; 
    vector<int> beauty;
    vector<int> speed;
    vector<int> enjoy; 
    // enjoy[i*m + j] = the enjoyment of the ith people on the jth horse

    // the mapping from people to horse 
    // p2h[i] = j -> the horse of the ith people is the jth horse
    // h2p[j] = i -> the rider of the jth horse is the ith people
    IntVarArray p2h; 
    IntVarArray h2p;

    // cur_enjoy[i] denodes the current enjoy level of the ith person
    // given that his/her horse is p2h[i]
    // cur_beauty[i] denotes the beauty of p2h[i]
    // cur_speed[i] denotes the speed of p2h[i]
    // cur_ability[j] denotes the ability of h2p[j]
    // cur_penalty is a boolean array that helps to define the panlty
    IntVarArray cur_enjoy;
    IntVarArray cur_beauty;
    IntVarArray cur_speed;
    IntVarArray cur_ability;
    BoolVarArray cur_penalty;
    IntVar Obj_val;

    // these helper function are used to define the penalty
    BoolVarArray helper1;
    BoolVarArray helper2;
    BoolVarArray helper3;
    BoolVarArray helper4;

public:
    royalhunt(const royalhuntOptions& opt): Script(opt){
        readData(opt.filename, n, m, rank, ability, beauty, speed, enjoy);
        cleanData(n, m, nD, rank, ability, beauty, speed, enjoy);

        // Find max ability, beauty, enjoy, and speed
        int maxAblity, maxBeauty, maxEnjoy, maxSpeed;
        vector<int>::iterator it;
        it = max_element(ability.begin(), ability.end());
        maxAblity = *it;
        it = max_element(beauty.begin(), beauty.end());
        maxBeauty = *it;
        it = max_element(enjoy.begin(), enjoy.end());
        maxEnjoy = *it;
        it = max_element(speed.begin(), speed.end());
        maxSpeed = *it;

        p2h = IntVarArray(*this, nD, 0, nD-1);
        h2p = IntVarArray(*this, nD, 0, nD-1);

        cur_enjoy = IntVarArray(*this, nD, 0, maxEnjoy); 
        cur_beauty = IntVarArray(*this, nD, 0, maxBeauty);
        cur_speed = IntVarArray(*this, nD, 0, maxSpeed);
        cur_ability = IntVarArray(*this, nD, 0, maxAblity);
        cur_penalty = BoolVarArray(*this, nD*nD, 0, 1);
        helper1 = BoolVarArray(*this, nD*nD, 0, 1); 
        helper2 = BoolVarArray(*this, nD*nD, 0, 1); 
        helper3 = BoolVarArray(*this, nD*nD, 0, 1); 
        helper4 = BoolVarArray(*this, nD*nD, 0, 1); 
        Obj_val = IntVar(*this, -10000, 10000);

        // Define those cur_ stuff
        for (int i = 0; i < nD; i ++){
            element(*this,
                    static_cast<IntArgs>(enjoy),
                    expr(*this, i*nD+p2h[i]),
                    cur_enjoy[i]);
        }

        for (int i = 0; i < nD; i ++){
            element(*this,
                    static_cast<IntArgs>(beauty),
                    expr(*this, p2h[i]),
                    cur_beauty[i]);
        }
        for (int i = 0; i < nD; i ++){
            element(*this,
                    static_cast<IntArgs>(speed),
                    expr(*this, p2h[i]),
                    cur_speed[i]);
        }
        for (int h = 0; h < nD; h ++){
            element(*this,
                    static_cast<IntArgs>(ability),
                    expr(*this, h2p[h]),
                    cur_ability[h]);
        }

        //
        // Define the objective value
        //
        // Punish if not a /\ not b /\ not c.
        // not b: the faster horse has a rider
        // not c: one of the horse has at least one rider.
        // not b -> not c
        // not a: the rider of the faster one has less skill.

        // Hence, punish if
        // (a) the faster horse has rider, and
        // (b1) the slower one has rider, but skill is better OR
        // (b2) the slower one has no rider.
        for (int h1 = 0; h1 < nD; h1 ++){
            for (int h2 = 0; h2 < nD; h2 ++){
                int cur_idx = h1*nD + h2;
                rel(*this, (speed[h1] > speed[h2]) == helper1[cur_idx]);
                rel(*this, (h2p[h1] < n) == helper2[cur_idx]);
                rel(*this, (cur_ability[h1] < cur_ability[h2]) == helper3[cur_idx]);
                rel(*this, (h2p[h2] < n) == helper4[cur_idx]);
                if (h2 > m || h1 > m)
                    rel(*this, cur_penalty[cur_idx] == 0);
                else{
                    rel(*this, 
                        (
                        helper1[cur_idx] &&
                        helper2[cur_idx] &&
                            (
                            (helper4[cur_idx] && helper3[cur_idx]) ||
                            !helper4[cur_idx]
                            )
                        )
                        >> (cur_penalty[cur_idx] == 1)
                        );
                     rel(*this, 
                        !(
                        helper1[cur_idx] &&
                        helper2[cur_idx] &&
                            (
                            (helper4[cur_idx] && helper3[cur_idx]) ||
                            !helper4[cur_idx]
                            )
                        )
                        >> (cur_penalty[cur_idx] == 0)
                        );
                }
            }
        }
        rel(*this, Obj_val == (sum(cur_enjoy) - 100 * sum(cur_penalty)));

        // Channeling
        for (int j = 0; j < nD; j ++)
            for (int i = 0; i < nD; i ++)
                rel(*this, ((h2p[i]==j) == (p2h[j]==i)));
        
        // The emperior must enjoy the day more than anyone else
        for (int i = 1; i < nD; i ++){
            rel(*this, cur_enjoy[0] > cur_enjoy[i]);
        }

        // No nagetive enjoyment
        for (int i = 0; i < nD; i ++){
            rel(*this, cur_enjoy[i] >= 0);
        }

        // all horse different
        distinct(*this, p2h);

        // if a cour member holds a higher rank than another, then either
        // (a) the beauty of their horse can be no less than that assigned to the other,
        // (b) the lower rank member does not ride, or
        // (c) both court members do not ride.
        // The lower rank member does not ride => cur_beauty[j] = 0
        // Both do not ride => 0>=0
        // Don't compare with dummy people
        for (int i = 0; i < n; i ++){
            for (int j = 0; j < n; j ++){
                if (rank[i] > rank[j]){
                    rel(*this, cur_beauty[i] >= cur_beauty[j]);
                }
            }
        }

        branch(*this, p2h, INT_VAR_SIZE_MIN(), INT_VAL_MAX());
    }
    
    virtual void print(std::ostream& os) const {
        for (int i = 0; i < n; i ++){
            if (p2h[i].val() + 1 <= m)
                os << p2h[i].val() + 1 << " ";
            else
                os << 0 << " ";
        }
        os << endl;
        os << Obj_val << endl;
    }

    royalhunt(bool share, royalhunt& oldR): Script(share, oldR) {
        n = oldR.n;
        m = oldR.m;
        nD = oldR.nD;
        // TODO: Check these deep copy 
        for(unsigned i = 0; i < oldR.rank.size(); i++)
            rank.push_back(oldR.rank[i]);
        for(unsigned i = 0; i < oldR.ability.size(); i++)
            ability.push_back(oldR.ability[i]);
        for(unsigned i = 0; i < oldR.beauty.size(); i++)
            beauty.push_back(oldR.beauty[i]);
        for(unsigned i = 0; i < oldR.speed.size(); i++)
            speed.push_back(oldR.speed[i]);
        for(unsigned i = 0; i < oldR.enjoy.size(); i++)
            enjoy.push_back(oldR.enjoy[i]);

        p2h.update(*this, share, oldR.p2h);
        h2p.update(*this, share, oldR.h2p);
        cur_enjoy.update(*this, share, oldR.cur_enjoy);
        cur_beauty.update(*this, share, oldR.cur_beauty);
        cur_ability.update(*this, share, oldR.cur_ability);
        cur_speed.update(*this, share, oldR.cur_speed);
        cur_penalty.update(*this, share, oldR.cur_penalty);
        helper1.update(*this, share, oldR.helper1);
        helper2.update(*this, share, oldR.helper2);
        helper3.update(*this, share, oldR.helper3);
        helper4.update(*this, share, oldR.helper4);
        Obj_val.update(*this, share, oldR.Obj_val);
    }
    
    virtual Space* copy(bool share) {
        return new royalhunt(share, *this);
    }

    int get_obj_value() const{
        return Obj_val.val();
    }

    virtual void constrain(const Space& _best) {
        const royalhunt& prev_best = static_cast<const royalhunt&>(_best);
        rel(*this, Obj_val > prev_best.get_obj_value());
    }

};


int main(int argc, char* argv[]) {
    royalhuntOptions rOpt("Royal Hunt");
    rOpt.ipl(IPL_DOM);
    rOpt.parse(argc, argv);
    rOpt.solutions(0);

    Script::run<royalhunt, BAB, royalhuntOptions>(rOpt);

    return 0;
}
