#include "tracker.h"


#if 0
#define Munkres Munkres<double>
#endif

#define rgb(r,g,b) cv::Scalar(b,g,r,255)

cv::Scalar Track::_COLORS []  = {rgb(158,1,66),rgb(213,62,79),rgb(244,109,67),rgb(253,174,97),rgb(254,224,139),rgb(255,255,191),rgb(230,245,152),rgb(171,221,164),rgb(102,194,165),rgb(50,136,189),rgb(94,79,162)};

int Track::_trackCount = 0;

void AssignmentProblemGreedy::solve(std::vector< std::pair<int,int> > &assignments, std::vector<int> &unassignedTracks, std::vector<int> &unassignedEuglena)
{
    std::vector<int> assignedTracks(_costMatrix.rows, 0);
    std::vector<int> assignedEuglena(_costMatrix.cols, 0);
    int iter = std::min(_costMatrix.rows,_costMatrix.cols);
    cv::Mat M = _costMatrix.clone();

    for(int i=0;i<iter;i++){
        cv::Point minLoc;
        double minVal,maxVal;
        cv::minMaxLoc(M,&minVal,&maxVal,&minLoc);
        M.row(minLoc.y) = cv::Mat::ones(1,M.cols,M.type()) * 1e10;
        M.col(minLoc.x) = cv::Mat::ones(M.rows,1,M.type()) * 1e10;

        if( minVal < _costThreshold ){
            assignments.push_back( std::pair<int,int>(minLoc.y,minLoc.x) );
            assignedTracks[minLoc.y] = 1;
            assignedEuglena[minLoc.x] = 1;
            //printf("Assignment Cost: %f, ",minVal );
        }else{
            break;
        }
    }

    for(size_t i=0;i<assignedTracks.size();i++){
        if( !assignedTracks[i] )
            unassignedTracks.push_back( i );
    }

    for(size_t i=0;i<assignedEuglena.size();i++){
        if( !assignedEuglena[i] )
            unassignedEuglena.push_back( i );
    }
}

#if 0
void AssignmentProblemHungarian::solve(std::vector< std::pair<int,int> > &assignments, std::vector<int> &unassignedTracks, std::vector<int> &unassignedEuglena)
{
    std::vector<int> assignedTracks(_numTracks, 0);
    std::vector<int> assignedEuglena(_numEuglena, 0);

    Munkres m;
    m.solve(_costMatrix);
    for(int t = 0; t < _numTracks; t++){
        for(int e=0;e < _numEuglena; e++){
            if( _costMatrix(t,e) == 0 ){
                assignments.push_back( std::pair<int,int>(t,e));
                assignedTracks[t] = 1;
                assignedEuglena[e] = 1;
                break;
            }
        }
    }

    for(size_t i=0;i<assignedTracks.size();i++){
        if( !assignedTracks[i] )
            unassignedTracks.push_back( i );
    }

    for(size_t i=0;i<assignedEuglena.size();i++){
        if( !assignedEuglena[i] )
            unassignedEuglena.push_back( i );
    }
}
#endif

///////////////////////////////////////////////////////////////////////
void TrackManager::track( std::vector<Euglena> &euglenas, int frame, float lengthScaleFactor)
{
//    for(auto &t: _liveTracks){
    for( size_t i=0;i<_liveTracks.size();i++){
        auto &t = _liveTracks[i];
        t.predict();
    }

    std::vector< Euglena > assignableEuglenas;
    std::vector< Euglena > unassignedEuglenas;

    if(_liveTracks.size() > 0 ){
        for(size_t e=0; e<euglenas.size(); e++){

            Euglena &euglena = euglenas[e];
            cv::RotatedRect &euglenaRect = euglenas[e]._rect;

            std::vector<float> spDistances(_liveTracks.size());

            for(size_t t=0;t<_liveTracks.size();t++){
                spDistances[t] = spatialDistanceSq( euglenaRect, _liveTracks[t].getPredictedPosition() );
            }

            if ( *std::min_element(spDistances.begin(),spDistances.end()) < (euglenaRect.size.width*euglenaRect.size.width*4) ){
                euglenas[e]._eugId = assignableEuglenas.size();
                assignableEuglenas.push_back( euglena );
            }
            else{
                unassignedEuglenas.push_back( euglena );
            }
        }
    }
    else{
        unassignedEuglenas =  euglenas;
    }

    if( (_liveTracks.size() > 0) && (assignableEuglenas.size() > 0) ){
        size_t nT = _liveTracks.size();
        size_t nE = assignableEuglenas.size();
        AssignmentProblemGreedy assignmentProblem(nT,nE, lengthScaleFactor *lengthScaleFactor * 1000.0);

        for(size_t t=0;t<nT;t++){
            _liveTracks[t]._debugId = t;
            for(size_t e=0;e<nE;e++){
                assignmentProblem(t,e) =  distanceSq( assignableEuglenas[e], _liveTracks[t], frame );
            }
        }

        std::vector< std::pair<int, int> > assignments;
        std::vector< int > orphanTracks;
        std::vector< int > orphanEuglena;

        assignmentProblem.solve(assignments,orphanTracks,orphanEuglena);

        //for(auto assignment: assignments ){
        for( size_t i=0;i<assignments.size();i++){
            auto &assignment = assignments[i];

            int trackId = assignment.first;
            int eugId   = assignment.second;
            _liveTracks[trackId].assign( assignableEuglenas[eugId]._rect, frame );
        }

        // for(auto trackId: orphanTracks ){
        for( size_t i=0;i<orphanTracks.size();i++){
            auto &trackId = orphanTracks[i];
            _liveTracks[trackId].notAssign();
        }

        // for(auto eugId: orphanEuglena ){
        for( size_t i=0;i<orphanEuglena.size();i++){
            auto &eugId = orphanEuglena[i];
            Euglena &euglena = assignableEuglenas[eugId];
            _liveTracks.push_back( Track( euglena._rect, frame, State(euglena._rect) ) );
        }
    }

    // Filter liveTracks
    std::vector<Track> newLiveTracks;
    // for(auto track: _liveTracks){
    for( size_t i=0;i<_liveTracks.size();i++){
        auto &track = _liveTracks[i];

        if( track.getIdleCounter() < IDLE_THRESHOLD )
            newLiveTracks.push_back( track );
        else{
#ifndef EUGLENA_LIVE
            _deadTracks.push_back(track);
#endif
        }
    }

    _liveTracks = newLiveTracks;

    // for(auto &eug: unassignedEuglenas){
    for( size_t i=0;i<unassignedEuglenas.size();i++){
        auto &eug = unassignedEuglenas[i];
        _liveTracks.push_back( Track( eug._rect, frame, State(eug._rect) ) );
    }
}


void EuglenaTracker::detectEuglena(const cv::Mat &im, std::vector<Euglena>  &euglenas)
{
    cv::Mat fgmask;
    cv::Mat gray;
    cv::Mat grayN;
    cv::cvtColor(im,gray,CV_BGR2GRAY);
    //cv::normalize(gray,grayN,0,255,cv::NORM_MINMAX);
    cv::equalizeHist(gray,grayN);

    //cv::normalize(gray,grayN,255,255,cv::NORM_L2);

#if defined(CV_VERSION_EPOCH) && (CV_VERSION_EPOCH < 3)
    (*_fgbg)(grayN,fgmask,-1);
#else
        // For OpenCV >= 3.0.0
    _fgbg->apply(grayN,fgmask,-1);
#endif

    cv::Mat dst;

    cv::threshold(fgmask,fgmask, 127,255, cv::THRESH_BINARY);
    cv::morphologyEx( fgmask, fgmask, cv::MORPH_ERODE,  _elementErode );
    cv::morphologyEx( fgmask, fgmask, cv::MORPH_DILATE, _elementDilate );

    static int count = 0;

#if 0
    char buffer[128];
    sprintf(buffer,"%05d_mask.jpg",count);
    cv::imwrite(buffer,fgmask);

    sprintf(buffer,"%05d_gray.jpg",count);
    cv::imwrite(buffer,grayN);

    count ++;
#endif

    std::vector<std::vector<cv::Point> > contours;
    cv::findContours( fgmask, contours,
                    cv::RETR_TREE,cv::CHAIN_APPROX_SIMPLE);

    euglenas.clear();
    // for(auto &c : contours){
    for( size_t i=0;i<contours.size();i++){
            auto &c = contours[i];
        //if ( cv::contourArea(c) > 250.0 ){
            cv::RotatedRect rect = cv::minAreaRect(c);
            euglenas.push_back( Euglena(rectifyRect(rect)) );
        //}
    }
}
