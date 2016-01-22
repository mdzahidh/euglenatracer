#include <stdio.h>
#include <iostream>
//#include <unistd.h>
//#include <sys/stat.h>

#include "tracker.h"
#include "getpot/GetPot"

#include "mex.h"
//#include "matrix.h"


using namespace std;

#ifndef WIN32

void createDebugDirectory()
{
}
#else
void createDebugDirectory()
{
}
//TODO windows code
#endif

void help()
{
    cout << "Usage:" << endl;
    cout << "   OPTIONS:" << endl;
    cout << "        -i, --input <input>: Input movie file, any standard movie format should work." << endl;
    cout << "        -z, --zoom  <zoom> : Zoom level, e.g. 4 or 10. Fractional values are also allowed." << endl << endl;
    cout << "   OPTIONS [OPTIONAL]:" << endl;
    cout << "        -o, --output <output>: Output json file, DEFAULT=traces.json" << endl;
    cout << "        -d, --debug          : Its only a flag that produces debug images and shows preview window" <<endl;
    cout << "        -h, --help           : Prints this help screen" << endl << endl;
    cout << "   EXAMPLES:" << endl;
    cout << "         ./euglena -i movie.mp4 -z 4 -o traces.json -d" << endl;
    cout << "         This takes an input movie.mp4 file where the zoom level was 4 and the debug flag was set." <<endl;
    cout << "         Traces will be stored in JSON format in trace.json, and (due to -d) a preview window" << endl;
    cout << "         will be displayed and debug images will be dumped in the current folder." << endl;

}

inline bool isfile (const std::string& name) {
    ifstream f(name.c_str());
    if (f.good()) {
        f.close();
        return true;
    } else {
        f.close();
        return false;
    }
}

void progressBar( double progress )
{
    int barWidth = 40;
    std::stringstream ss;
    ss << "[";
    int pos = barWidth * progress;
    for (int i = 0; i < barWidth; ++i) {
        if (i < pos) ss << "=";
        else if (i == pos) ss << ">";
        else ss << " ";
    }
    ss << "] " << int(progress * 100.0) << " %";
    std::string  str = ss.str();
//     std::cout << str;
//     std::cout.flush();
    mexPrintf("%s",str.c_str());
    mexEvalString("drawnow;");
    for (int i = 0; i < str.length(); ++i){
        //std::cout << "\b";
        mexPrintf("\b");
    }
}

//int main(int argc, char **argv)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    #define MOVIE             prhs[0]
    #define ZOOM              prhs[1]

    if( nrhs < 1 ){
        cerr << "Atleast 1 arguments required" << endl;
        cerr << "\tUsage: numvidframes( movieFileName)" << endl;
        return;
    }

    string fname;

    if( mxIsChar(MOVIE) ){
        char* input_buf = mxArrayToString(MOVIE);
        fname = input_buf;
        mxFree(input_buf);
        if ( !isfile(fname) ){
            cerr << "Cannot read " << fname << "!" << endl;
            return;
        }
    }
    else{
        cerr << "First arugment needs to be a movie file name, i.e. a string" << endl;
        return;
    }

    cv::VideoCapture cap(fname);
    double totalFrames = (double)cap.get(cv::CAP_PROP_FRAME_COUNT);


    plhs[0] = mxCreateDoubleScalar(totalFrames);
}
