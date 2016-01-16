#include <stdio.h>
#include <iostream>
//#include <unistd.h>
//#include <sys/stat.h>

#include "tracker.h"
#include "getpot/GetPot"


using namespace std;

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
    std::cout << str;
    std::cout.flush();
    for (int i = 0; i < str.length(); ++i){
        std::cout << "\b";
    }
}

int main(int argc, char **argv)
{
    GetPot cl(argc,argv);
    
    if (cl.search(2,"-h","--help") ){
        help();
        exit(0);
    }
    
    const string fname = cl.follow("",2,"--input","-i");
    if (fname.length() ==  0){
        cout << "input filename missing!" << endl;
        help();
        exit(-1);
    }

    int threshold = cl.follow(0,2,"--treshold","-t");
    
    float zoom = cl.follow(0.0f,2,"--zoom","-z");
    if( zoom == 0.0 ){
        cout << "You must specify zoom factor" << endl;
        help();
        exit(-1);
    }
    
    const string output = cl.follow("traces.json",2,"--out","-o");
    bool debug = cl.search(2,"--debug","-d");
    bool verbose = cl.search(2,"--verbose","-v");
    
    cv::VideoCapture cap(fname);
    cv::Mat frame;
    std::vector< Euglena > euglenaList;

    EuglenaTracker tracker;
    tracker.setZoom(zoom);
    
    double totalFrames = cap.get(cv::CAP_PROP_FRAME_COUNT);
    int frameN = 0;
    while(1){
        if ( !cap.read(frame) ) break;
        
        tracker.track(frame,frameN);
        
        if( debug ){
            tracker.drawVis(frame,frameN);
            
            cv::imshow("image",frame);

            char buffer[128];
            sprintf(buffer,"%05d.jpg",frameN);
            cv::imwrite(buffer,frame);

            if( (cv::waitKey(1)  & 0xff)  == 27 )
                break;
        }
        
        frameN++;
        
        if( verbose ){
            printf("Grabbing Frame: %d (Dead: %ld, Live: %ld)\n", frameN, tracker._trackMgr.getDeadTracks().size(), tracker._trackMgr.getLiveTracks().size());
        }
        progressBar( frameN / totalFrames );
    }

    tracker._trackMgr.writeToJSONFile(output, threshold);
    return 0;
}
