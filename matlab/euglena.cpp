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

    if( nrhs < 2 ){
        cerr << "Atleast 2 arguments required" << endl;
        cerr << "\tUsage: euglena( movieFileName, zoom, [debug], [verbose] )" << endl;
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

    float zoom = 1;
    if( mxIsNumeric(ZOOM)){
        zoom = (float) mxGetScalar(ZOOM);
    }
    else{
        cerr << "Second arugment needs to be zoom factor, a scalar number" << endl;
        return;
    }

    int threshold  = 0;
    bool debug=false;
    bool verbose = false;
    std::string debugFolder = "./";

    for(int i=2;i<nrhs;i++){
        if ( mxIsChar(prhs[i]) ) {
            char* buf = mxArrayToString(prhs[i]);
            if( !strcmp(buf,"threshold")){
                if( nrhs <= (i+1) ){
                    cerr << "You must provide a threshold value" << endl;
                    mxFree(buf);
                    return;
                }
                if( mxIsNumeric(prhs[i+1]) ){
                    threshold = (int) mxGetScalar( prhs[i+1] );
                    i++;
                    continue;
                }
                else{
                    cerr << "Threshold must be a followed by a number" << endl;
                    mxFree(buf);
                    return;
                }
            }
            else if( !strcmp(buf, "verbose")) verbose = true;
            else if( !strcmp(buf, "debug"))  {
                debug = true;
                if( nrhs <= (i+1) ){
                    cerr << "You must provide a debug folder" << endl;
                    mxFree(buf);
                    return;
                }
                if( mxIsChar(prhs[i+1]) ){
                    char* buf = mxArrayToString(prhs[i+1]);
                    debugFolder = buf;
                    mxFree(buf);
                    i++;
                    continue;
                }
                else{
                    cerr << "debug must be a followed by a string [debug folder]" << endl;
                    mxFree(buf);
                    return;
                }
            }
            mxFree(buf);
        }
    }

    cv::VideoCapture cap(fname);
    cv::Mat frame;
    std::vector< Euglena > euglenaList;

    EuglenaTracker tracker;
    tracker.setZoom(zoom);

    double totalFrames = cap.get(cv::CAP_PROP_FRAME_COUNT);

    if (totalFrames > 0 && debug){
        createDebugDirectory();
    }

    int frameN = 0;
    while(1){
        if ( !cap.read(frame) ) break;

        tracker.track(frame,frameN);

        if( debug ){
            tracker.drawVis(frame,frameN);

            char buffer[128];
            sprintf(buffer,"%s/%05d.jpg",debugFolder.c_str(),frameN);
            cv::imwrite(buffer,frame);

        }

        frameN++;

        if( verbose ){
            printf("Grabbing Frame: %d (Dead: %ld, Live: %ld)\n", frameN, tracker._trackMgr.getDeadTracks().size(), tracker._trackMgr.getLiveTracks().size());
            std::cout.flush();
        }
        progressBar( frameN / totalFrames );
    }

    string json;
    tracker._trackMgr.toJSONString(json, threshold);
    char* output_buf = (char*) mxCalloc(json.length()+1,sizeof(char));
    strcpy(output_buf, json.c_str());
    plhs[0] = mxCreateString( output_buf );
}
