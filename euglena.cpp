#include <stdio.h>
#include <iostream>
#include <memory>

//#include <unistd.h>
//#include <sys/stat.h>

#include "json.h"
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

int processJSON(GetPot &cl, std::string &fname, int treshhold)
{
    float zoom = cl.follow(0.0f,2,"--zoom","-z");
    if( zoom == 0.0 ){
        cout << "You must specify zoom factor" << endl;
        help();
        return -1;
    }
    
    const string output = cl.follow("traces.json",2,"--out","-o");
    bool debug = cl.search(2,"--debug","-d");
    bool verbose = cl.search(2,"--verbose","-v");
    
    cv::VideoCapture cap(fname);
    cv::Mat frame;
    
    if (!cap.isOpened())
        return -1;
    
    EuglenaTracker tracker;
    tracker.setZoom(zoom);
    
    double totalFrames = cap.get(cv::CAP_PROP_FRAME_COUNT);
    int frameN = 0;
    while(1){
        if ( !cap.read(frame) ) break;
        
        tracker.track(frame,frameN);
        
        if( debug ){
            tracker.drawVis(frame,frameN, treshhold );
            char buffer[128];
            sprintf(buffer,"%05d.jpg",frameN);
            cv::imwrite(buffer,frame);
        }
        frameN++;
        
        if( verbose ){
            printf("Grabbing Frame: %d (Dead: %ld, Live: %ld)\n", frameN, tracker._trackMgr.getDeadTracks().size(), tracker._trackMgr.getLiveTracks().size());
        }
        progressBar( frameN / totalFrames );
    }
    tracker._trackMgr.writeToJSONFile(output, treshhold);
    return 0;
}

inline char separator()
{
#if defined _WIN32 || defined __CYGWIN__
    return '\\';
#else
    return '/';
#endif
}

std::string readJSONFile(const std::string &path) {
    FILE* file = fopen(path.c_str(), "rb");
    if (!file)
        return std::string("");
    fseek(file, 0, SEEK_END);
    long const size = ftell(file);
    unsigned long const usize = static_cast<unsigned long const>(size);
    fseek(file, 0, SEEK_SET);
    std::string text;
    char* buffer = new char[size + 1];
    buffer[size] = 0;
    if (fread(buffer, 1, usize, file) == usize)
        text = buffer;
    fclose(file);
    delete[] buffer;
    return text;
}

struct LED{
    int top,right,bottom,left;
};

LED findPreviousLEDState(const Json::Value &eventsToRun, double t)
{
    Json::ArrayIndex size = eventsToRun.size();
    int i = 0;
    while( i < size && eventsToRun[i]["time"].asDouble() <= t ) i++;
    i -= 1;
    LED led = {0,0,0,0};
    if (i >= 0){
        const Json::Value &event = eventsToRun[i];
        led.top    = event["topValue"].asLargestInt();
        led.right  = event["rightValue"].asLargestInt();
        led.bottom = event["bottomValue"].asLargestInt();
        led.left   = event["leftValue"].asLargestInt();
    }
    return led;
}

std::string stringf(const std::string fmt_str, ...) {
    int final_n, n = ((int)fmt_str.size()) * 2; /* Reserve two times as much as the length of the fmt_str */
    std::string str;
    std::unique_ptr<char[]> formatted;
    va_list ap;
    while(1) {
        formatted.reset(new char[n]); /* Wrap the plain char array into the unique_ptr */
        strcpy(&formatted[0], fmt_str.c_str());
        va_start(ap, fmt_str);
        final_n = vsnprintf(&formatted[0], n, fmt_str.c_str(), ap);
        va_end(ap);
        if (final_n < 0 || final_n >= n)
            n += abs(final_n - n + 1);
        else
            break;
    }
    return std::string(formatted.get());
}

void annotateImage( cv::Mat &frame, const LED& state, int nFrame, double t, double zoom, int width, int height)
{
    double w = 30.0 * zoom / 4.0;
    
    cv::line(frame, cv::Point2f(width-w-30,height-10),cv::Point2f(width-10,height-10),cv::Scalar(255,255,255,255),5 );
    
    cv::putText(frame,"100um",cv::Point2f(width-w-40,height-20),cv::FONT_HERSHEY_COMPLEX,1.0,cv::Scalar(255,255,255,255),1,8);
    
    std::string s = stringf("Frame %d ( t = ~%4.2fs)", nFrame, t);
    cv::putText(frame,s,cv::Point2f(10,20),cv::FONT_HERSHEY_COMPLEX,0.5,cv::Scalar(0,255,255,255),1,8);
    
    s = stringf("%3d",state.top);
    cv::putText(frame,s,cv::Point2f(width/2,30),cv::FONT_HERSHEY_COMPLEX,1,cv::Scalar(0,255,255,255),1,8);
    
    s = stringf("%3d",state.right);
    cv::putText(frame,s,cv::Point2f(width-60,height/2),cv::FONT_HERSHEY_COMPLEX,1,cv::Scalar(0,255,255,255),1,8);
    
    s = stringf("%3d",state.bottom);
    cv::putText(frame,s,cv::Point2f(width/2,height-20),cv::FONT_HERSHEY_COMPLEX,1,cv::Scalar(0,255,255,255),1,8);
    
    s = stringf("%3d",state.left);
    cv::putText(frame,s,cv::Point2f(0,height/2),cv::FONT_HERSHEY_COMPLEX,1,cv::Scalar(0,255,255,255),1,8);

}

int processTrackedVideo(GetPot &cl, std::string &folder, int threshold )
{
    if ( folder[folder.length()-1] != separator() ){
        folder = folder + separator();
    }
 
    bool verbose = cl.search(2,"--verbose","-v");
    
    std::string jsonFile = folder + "lightdata.json";
    std::string jsonString = readJSONFile(jsonFile);
    
    if (jsonString.length() == 0 )
        return -1;
    
    Json::Reader jsonReader;
    Json::Value  jsonRoot;
    
    jsonReader.parse(jsonString, jsonRoot);
    
    double magnification = jsonRoot["metaData"]["magnification"].asDouble();
    
    Json::Value eventsToRun = jsonRoot["eventsToRun"];
    
    double offset = eventsToRun[ 0 ]["time"].asDouble();
    double totalTime = eventsToRun[ eventsToRun.size()- 1 ]["time"].asDouble() - offset;
    std::string vidName = folder + "movie.mp4";
    cv::VideoCapture cap(vidName);
    
    if( !cap.isOpened() )
        return -1;
    
    double totalFrames = cap.get(cv::CAP_PROP_FRAME_COUNT);
    int width  = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_WIDTH));
    int height = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_HEIGHT));
    
    double T = totalTime / totalFrames;
    
    EuglenaTracker tracker;
    tracker.setZoom(magnification);
    cv::Mat frame;
    
    cv::Size S = cv::Size((int) cap.get(CV_CAP_PROP_FRAME_WIDTH),    // Acquire input size
                          (int) cap.get(CV_CAP_PROP_FRAME_HEIGHT));
    
    cv::VideoWriter  outVideo;
    
    outVideo.open(folder + "tracks_thresholded_10.avi",CV_FOURCC('M', 'J', 'P', 'G'),25,S);
    if (!outVideo.isOpened()){
        std::cout << "Error opening output video" << std::endl;
        return -1;
    }
    
    int nFrame = 0;
    while(1){
        double t = T * nFrame;
        LED state = findPreviousLEDState(eventsToRun, t + offset);
        
        if ( !cap.read(frame) ) break;
        
        tracker.track(frame,nFrame);
        tracker.drawVis(frame,nFrame, threshold );
        annotateImage(frame, state, nFrame, t/1000.0, magnification, width, height);
        outVideo << frame;
        
        nFrame++;
        
        if( verbose ){
            printf("Grabbing Frame: %d (Dead: %ld, Live: %ld)\n", nFrame, tracker._trackMgr.getDeadTracks().size(), tracker._trackMgr.getLiveTracks().size());
        }
        progressBar( nFrame / totalFrames );
    }
    tracker._trackMgr.writeToJSONFile(folder+"tracks.json", threshold);
    return 0;
}

int main(int argc, char **argv)
{
    GetPot cl(argc,argv);
    
    if (cl.search(2,"-h","--help") ){
        help();
        exit(0);
    }
    
    string fname = cl.follow("",2,"--input","-i");
    if (fname.length() ==  0){
        cout << "input filename missing!" << endl;
        help();
        exit(-1);
    }

    bool trackedVideo = cl.search(2,"-tv","--tracked-video");
    
    int threshold = cl.follow(0,2,"--treshold","-t");
    
    if (!trackedVideo){
        return processJSON(cl,fname,threshold);
    }
    else{
        return processTrackedVideo(cl,fname,threshold);
    }
    return 0;
}
