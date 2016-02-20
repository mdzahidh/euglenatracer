#ifndef __TRACKER_H__
#define __TRACKER_H__


#include <algorithm>
#include <opencv2/opencv.hpp>


#if 0
#include "munkres-cpp/src/munkres.h"
#include "munkres-cpp/src/matrix.h"
#endif


#include "intersection.h"


#ifndef M_PI
#define M_PI 3.14159265358979
#endif

class Euglena{
public:
    int _eugId;
    cv::RotatedRect _rect;
    Euglena(const cv::RotatedRect& rect):
        _eugId(-1),
        _rect(rect)
    {
    }
};

#define DIMENSION 6

class State{
public:
    cv::Point2f _pos;
    cv::Point2f _velocity;
    cv::Point2f _size;
    float       _angle;

    State():
        _pos(cv::Point2f(0,0)),
        _velocity(cv::Point2f(0,0)),
        _angle(0)
    {
    }
    State(const cv::RotatedRect& rect):
        _pos(rect.center),
        _velocity(cv::Point2f(0,0)),
        _size(cv::Point2f(rect.size.width,rect.size.height)),
        _angle(rect.angle)
    {
    }

    State(const cv::RotatedRect& rect, const cv::Point2f &velocity):
        _pos(rect.center),
        _velocity(velocity),
        _size(cv::Point2f(rect.size.width,rect.size.height)),
        _angle(rect.angle)
    {
    }

    float distanceSq( const State& other ) const
    {
        cv::Mat weight = cv::Mat::ones(DIMENSION,1,CV_32F);
        weight.at<float>(0,1) = 10.0 / _size.x;
        weight.at<float>(1,1) = 10.0 / _size.y;
        weight.at<float>(2,1) = 20.0 / _size.x;
        weight.at<float>(3,1) = 20.0 / _size.y;
        weight.at<float>(4,1) = 50.0 / _size.x;
        weight.at<float>(5,1) = 50.0 / _size.y;
        cv::Mat diff = other.toMatrix() - toMatrix();
        return diff.mul(weight).dot(diff);
    }

    cv::Mat toMatrix() const
    {
        cv::Mat state = cv::Mat_<float>(DIMENSION,1);
        state.at<float>(0) = _pos.x;
        state.at<float>(1) = _pos.y;
        state.at<float>(2) = _velocity.x;
        state.at<float>(3) = _velocity.y;
        state.at<float>(4) = _size.x;
        state.at<float>(5) = _size.y;

        //state.at<float>(2) = _angle;
        return state;
    }


    static State fromMatrix( cv::Mat state )
    {
        State st;
        st._pos.x = state.at<float>(0);
        st._pos.y = state.at<float>(1);
        st._velocity.x = state.at<float>(2);
        st._velocity.y = state.at<float>(3);
        st._size.x = state.at<float>(4);
        st._size.y = state.at<float>(5);
        //st._angle = state.at<float>(2);
        return st;
    }
};

class AssignmentProblem{
protected:
    int     _numTracks;
    int     _numEuglena;
public:
    virtual void init(int numTracks, int numEuglenas) = 0;
    virtual double& operator()(int i,int j) = 0;
    virtual void printCostMatrix() const = 0;
    virtual void solve(std::vector< std::pair<int,int> > &assignments, std::vector<int> &unassignedTracks, std::vector<int> &unassignedEuglena)  = 0;
};

class AssignmentProblemGreedy : public AssignmentProblem{
public:
    cv::Mat     _costMatrix;
    double      _costThreshold;

    AssignmentProblemGreedy( int numTracks, int numEuglena, double costThreshold=500.0)
    {
        _costThreshold  = costThreshold;
        init(numTracks,numEuglena);
    }
    virtual void init(int numTracks, int numEuglenas)
    {
        _costMatrix = cv::Mat::zeros(numTracks,numEuglenas,CV_64F);
    }

    virtual double& operator()(int i,int j)
    {
        return _costMatrix.at<double>(i,j);
    }
    void printMatrix(const cv::Mat& M) const
    {
        for(int i=0;i<M.rows;i++){
            for(int j=0;j<M.cols;j++){
                printf("%010.3f, ",_costMatrix.at<double>(i,j));
            }
            printf("\n");
        }
    }

    virtual void printCostMatrix() const
    {
        printMatrix(_costMatrix);
    }
    virtual void solve(std::vector< std::pair<int,int> > &assignments,
                       std::vector<int> &unassignedTracks,
                       std::vector<int> &unassignedEuglena) ;

};

#if 0
class AssignmentProblemHungarian : public AssignmentProblem{
private:
    int _dim;
    Matrix<double> _costMatrix;
public:
    AssignmentProblemHungarian(int numTracks,int numEuglena)
    {
        init(numTracks,numEuglena);
    }

    virtual void init(int numTracks, int numEuglena)
    {
        _numTracks = numTracks;
        _numEuglena = numEuglena;
        _dim = std::max(_numTracks,_numEuglena);
        _costMatrix = Matrix<double>(_dim,_dim);
        _costMatrix.clear();
    }

    virtual double& operator()(int i, int j)  {
        return _costMatrix(i,j);
    }

    virtual void printCostMatrix() const
    {
        for(int i=0;i<_dim;i++){
            for(int j=0;j<_dim;j++){
                printf("%010.3f, ",_costMatrix(i,j));
            }
            printf("\n");
        }
    }

    virtual void solve(std::vector< std::pair<int,int> > &assignments,
                       std::vector<int> &unassignedTracks,
                       std::vector<int> &unassignedEuglena) ;

};
#endif

class Predictor{
public:
    cv::KalmanFilter _kalman;

    Predictor(const State& initial):
        _kalman(DIMENSION,DIMENSION,0,CV_32F)
    {
        _kalman.measurementMatrix   = cv::Mat::eye(DIMENSION,DIMENSION,CV_32F);
        _kalman.transitionMatrix    = cv::Mat::eye(DIMENSION,DIMENSION,CV_32F);
        _kalman.processNoiseCov     = cv::Mat::eye(DIMENSION,DIMENSION,CV_32F) * 1e-4;
        _kalman.measurementNoiseCov = cv::Mat::eye(DIMENSION,DIMENSION,CV_32F) * 1e-4;
        _kalman.errorCovPost        = cv::Mat::eye(DIMENSION,DIMENSION,CV_32F) * 0.1;


        _kalman.processNoiseCov.at<float>(2,2) = 1e-6;
        _kalman.processNoiseCov.at<float>(3,3) = 1e-6;

        _kalman.statePre = initial.toMatrix();

        correct(initial);
    }
    State predict()
    {
        cv::Mat prediction = _kalman.predict();
        return State::fromMatrix(prediction);
    }

    void correct(const State &state)
    {
        _kalman.correct( state.toMatrix() );
    }
};

class TrackSample{
public:
    cv::RotatedRect _rect;
    int             _frameN;
    TrackSample( const cv::RotatedRect &rect, int frameN ) :
        _rect(rect), _frameN(frameN)
    {
    }
    std::string toJSON(std::string indent)
    {
        std::ostringstream ss;


        float angle  = _rect.angle;
        float width  = _rect.size.width;
        float height = _rect.size.height;

        // Normalizing the angle information.
        // angle = 0 is considered horizontal, i.e. the width is bigger than the height.
        if (_rect.size.height > _rect.size.width ){
            height = _rect.size.width;
            width  = _rect.size.height;
            angle  = angle + 90;
        }

        ss << indent << "{\n";
        ss << indent << " \"frame\":" << _frameN << ",\n";
        ss << indent << " \"rect\": [" << _rect.center.x << ","
           << _rect.center.y << ","
           << width << ","
           << height << ","
           << angle << "]\n";
        ss << indent << "}";
        return ss.str();
    }
};


class Track{
public:
    int                         _trackId;
    int                         _debugId;
    int                         _startFrame;
    int                         _lastFrame;
    std::vector<TrackSample>    _samples;
    Predictor                   _predictor;
    State                       _predictedState;
    int                         _idleCounter;

    static int                  _trackCount;
    cv::Scalar                  _color;

    static cv::Scalar _COLORS[];

    Track( cv::RotatedRect &head, int startFrame, const State &initialState) :
         _startFrame(startFrame), _lastFrame(startFrame), _predictor(initialState), _idleCounter(0)
    {
        _trackId = _trackCount++;
        _samples.push_back(TrackSample(head,startFrame));
        _color = cv::Scalar(rand()%256,rand()%256,rand()%256,255);
        //_color = _COLORS[_trackId % 11];
    }
    int getNumSamples(){ return _samples.size();}
    const cv::RotatedRect& getHeadRect() const { return _samples[_samples.size()-1]._rect;}

    const State& predict()
    {
        _predictedState = _predictor.predict();
        return _predictedState;
    }

    const State& getPredictedState() const
    {
        return _predictedState;
    }
    std::string toJSON(std::string indent)
    {
        std::string json;
        std::ostringstream ss;

        ss << indent << "{\"trackID\":" << _trackId << ",\n"
           << indent << " \"startFrame\":" << _startFrame << ",\n"
           << indent << " \"lastFrame\":" << _lastFrame << ",\n"
           << indent << " \"numSamples\":" << _samples.size() << ",\n"
           << indent << " \"samples\": [\n";
        for(size_t i=0;i<_samples.size();i++){
            ss << _samples[i].toJSON(indent + "    ");
            if( i < _samples.size()-1 ){
                ss << ",\n";
            }
        }
        ss << indent << "\n";
        ss << indent << "]\n";
        ss << indent << "}";
        return ss.str();
    }
    cv::RotatedRect getPredictedPosition() const
    {
        cv::RotatedRect rect;
        rect.center = _predictedState._pos;
        rect.size   = _predictedState._size;
        rect.angle  = getHeadRect().angle;
        return rect;
    }

    void assign( cv::RotatedRect &rect, int frame )
    {
        cv::Point2f vel(0,0);
        if(_samples.size() > 1 ){
            float time = frame - _lastFrame;
            vel = (rect.center - _samples[_samples.size()-1]._rect.center);
            vel.x /= time;
            vel.y /= time;
        }
        _samples.push_back( TrackSample(rect,frame) );
        _lastFrame = frame;
        _predictor.correct( State(rect,vel) );
        _idleCounter = 0;
    }
    void notAssign()
    {
        _idleCounter ++ ;
    }

    int getIdleCounter()
    {
        return _idleCounter;
    }
};

#define IDLE_THRESHOLD 5

class TrackManager{
private:
    std::vector< Track > _liveTracks;
    std::vector< Track > _deadTracks;
    int                  _threshold;

    static float angleDiff( float angleA, float angleB )
    {
        float PI2 = 2*M_PI;

        angleA = fmod(angleA,PI2);
        angleB = fmod(angleB,PI2);

        float diff = angleB - angleA;

        if( diff > M_PI){
            return diff - PI2;
        }
        else if( diff < -M_PI ){
            return diff + PI2;
        }
        else {
            return diff;
        }
    }
    static float distanceSq(const Euglena& euglena, const Track& track, int frame)
    {
        const State &trackState = track.getPredictedState();
        float time = frame - track._lastFrame;
        cv::Point2f vel = (euglena._rect.center - track.getHeadRect().center);
        vel.x /= time;
        vel.y /= time;
        State eugState(euglena._rect,vel);
        return eugState.distanceSq( trackState );
    }
    static float spatialDistanceSq(const cv::RotatedRect &rectA, const cv::RotatedRect &rectB)
    {
        cv::Point2f diffCenters = rectA.center - rectB.center;
        return diffCenters.dot(diffCenters);
    }

    static float overlapArea(const cv::RotatedRect &rectA, const cv::RotatedRect &rectB)
    {
        std::vector<cv::Point2f> ctr;
        rotatedRectangleIntersection(rectA, rectB,ctr);
        if( ctr.size() > 1)
            return cv::contourArea(ctr);
        else
            return 0;
    }

    static bool sortFunc(const Track& a, const Track &b)
    {
        return a._startFrame < b._startFrame;
    }

public:
    const std::vector<Track>& getLiveTracks() const { return _liveTracks; };
    const std::vector<Track>& getDeadTracks() const { return _deadTracks; };

    void reset()
    {
        Track::_trackCount = 0;
    }

    void track( std::vector<Euglena> &euglenas, int frame, float lengthScaleFactor );

    void toJSONString( std::string &output, int threshold )
    {
        std::ostringstream ss;
        std::vector<Track> allTracks;

        for(size_t i=0;i<_deadTracks.size();i++){
            if( _deadTracks[i]._samples.size() > threshold ){
                allTracks.push_back( _deadTracks[i] );
            }
        }
        for(size_t i=0;i<_liveTracks.size();i++){
            if( _liveTracks[i]._samples.size() > threshold ){
                allTracks.push_back( _liveTracks[i] );
            }
        }

        std::sort( allTracks.begin(), allTracks.end(), sortFunc );

        ss << "[\n";
        for(size_t i=0;i<allTracks.size();i++){
            ss << allTracks[i].toJSON("    ");
            if( i < allTracks.size()-1 ){
                ss << ",\n";
            }
            else if(allTracks.size() > 0 ){
                ss << "\n";
            }
        }

        ss << "]\n";
        output = ss.str();
    }

    void writeToJSONFile( std::string fileName, int threshold )
    {
        FILE *fp = fopen(fileName.c_str(),"w");
        std::string json;
        toJSONString(json, threshold);
        fwrite(json.c_str(),json.length(),1,fp);
        fclose(fp);
    }

};


class EuglenaTracker {
public:
    cv::Ptr<cv::BackgroundSubtractor>   _fgbg;
    cv::Mat                             _elementErode;
    cv::Mat                             _elementDilate;
    TrackManager                        _trackMgr;
    std::vector<Euglena>                _euglenas;
    float                               _zoom;
    float                               _lengthScaleFactor;
    float                               _areaScaleFactor;

    EuglenaTracker()
    {

        Track::_trackCount = 0;

#if defined(CV_VERSION_EPOCH) && (CV_VERSION_EPOCH < 3)
        _fgbg = new cv::BackgroundSubtractorMOG2(500,16,false);
#else
        // This is for OpenCV >= 3.0.0
        _fgbg = cv::createBackgroundSubtractorMOG2();
#endif
        _elementErode  = getStructuringElement( cv::MORPH_ELLIPSE, cv::Size( 3, 3 ) );
        _elementDilate = getStructuringElement( cv::MORPH_ELLIPSE, cv::Size( 5, 5 ));
        setZoom(10.0f);
    }

    void setZoom(float zoom)
    {
        _zoom = zoom;
        _lengthScaleFactor = zoom / 10.0f;
        _areaScaleFactor = _lengthScaleFactor * _lengthScaleFactor;
    }

    void filterGoodEuglenas(std::vector<Euglena> &euglenas)
    {
        //printf("areaScale: %f\n",_areaScaleFactor);
        std::vector<Euglena> goodEuglenas;
        //for(const auto &e: euglenas){
        for( size_t i=0;i<euglenas.size();i++){
            auto &e = euglenas[i];
            float area = e._rect.size.width * e._rect.size.height;
            //if ( area > (250.0*_areaScaleFactor) && area < (1500*_areaScaleFactor) && ( (e._rect.size.width / e._rect.size.height) >= 1.5) ){
            if ( area > (150.0*_areaScaleFactor) && area < (1500*_areaScaleFactor) ){
                goodEuglenas.push_back( e );
            }
        }
        euglenas = goodEuglenas;
    }
    void track(const cv::Mat &im, int frameN)
    {
        _euglenas.clear();
        detectEuglena(im, _euglenas);
        filterGoodEuglenas(_euglenas);
        _trackMgr.track(_euglenas,frameN, _lengthScaleFactor);
    }

    void drawVis(cv::Mat &out, int frameN, int threshold = 0 )
    {
        drawTracks(out,_trackMgr.getLiveTracks(),frameN, threshold);
        //drawEuglena(out, _euglenas);
    }

    void detectEuglena(const cv::Mat &im, std::vector<Euglena>  &euglenas);

    static cv::RotatedRect rectifyRect(cv::RotatedRect &rect)
    {
        float width  = rect.size.width;
        float height = rect.size.height;
        float angle = rect.angle;

        if (height > width){
            rect.size.width = height;
            rect.size.height = width;
            rect.angle = angle + 90;
        }
        return rect;
    }

    static void drawBox(cv::Mat &im, const cv::RotatedRect &box, const cv::Scalar  &color, int thickness)
    {
        cv::Point2f pts[4];
        box.points(pts);
        for(int i=0;i<4;i++){
            cv::line(im,pts[i],pts[(i+1)%4],color,thickness);
        }
    }

    static void drawEuglena( cv::Mat &im, const std::vector<Euglena> &euglenas)
    {
//        for(auto &e : euglenas){
        for( size_t i=0;i<euglenas.size();i++){
            auto &e = euglenas[i];
            drawBox(im,e._rect,cv::Scalar(255,255,255,0),2);
    //         if( e._eugId >= 0 ){
    //             std::stringstream ss;
    //             ss << e._eugId;
    //             cv::putText(im,ss.str(),e._rect.center,cv::FONT_HERSHEY_SCRIPT_SIMPLEX,1,cv::Scalar(0,0,255,255),2,8);
    //         }
        }
    }

    static void drawTracks( cv::Mat &im, const std::vector< Track > &tracks, int frame, int threshold = 0 )
    {

        //im.setTo(cv::Scalar(255,255,255));

//        for(auto &track: tracks ){
          for( size_t i=0;i<tracks.size();i++){
            auto &track = tracks[i];


//            if ( !(track._trackId == 1386 ||
//                   track._trackId == 1116 ||
//                   track._trackId == 1273 ||
//                   track._trackId == 1512 ||
//                   track._trackId == 1353) ) continue ;

            if (track._samples.size() > threshold ){
                for(int i = track._samples.size()-1;i>=1 && (track._samples.size() - i) < 10000;--i){
                    float frac  = std::min( (track._samples.size() - i)/10.0f, 1.0f );
//                    int thickness = round((1.0-frac) * 5.0 + frac * 1.0);
//                  int thickness = round((1.0-frac) * 5.0 + frac * 1.0);
//                  int thickness =  2.0;
                    int thickness = 1.0;
                    cv::line(im,track._samples[i]._rect.center,track._samples[i-1]._rect.center,
                            track._color,
                            thickness
                            );
                }
                const State& predictedState = track.getPredictedState();
//                drawBox(im,track.getPredictedPosition(),track._color,1);
                cv::line(im,predictedState._pos,predictedState._pos + predictedState._velocity*10,cv::Scalar(0,0,0,255),1,8);
                drawBox(im,track.getHeadRect(),track._color,1);
                std::stringstream ss;
//                ss << track._debugId;
                ss << track._trackId;
                cv::putText(im,ss.str(),track.getHeadRect().center,cv::FONT_HERSHEY_SCRIPT_SIMPLEX,0.5,cv::Scalar(255,255,255,255),1,8);
            }
        }
    }

};

#endif
