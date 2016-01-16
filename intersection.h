#ifndef __INTERSECTION__H__
#define __INTERSECTION__H__

#include <opencv2/opencv.hpp>

namespace cv {

#if defined(CV_VERSION_EPOCH) && (CV_VERSION_EPOCH < 3)
enum RectanglesIntersectTypes {
    INTERSECT_NONE = 0, //!< No intersection
    INTERSECT_PARTIAL  = 1, //!< There is a partial intersection
    INTERSECT_FULL  = 2 //!< One of the rectangle is fully enclosed in the other
};
#endif

int rotatedRectangleIntersection( const RotatedRect& rect1, const RotatedRect& rect2, OutputArray intersectingRegion );
#endif
} //namespace


