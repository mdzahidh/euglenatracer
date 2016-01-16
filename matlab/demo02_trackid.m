%% Regardless of the threshold parameter, all the tracks are extracted
%  (in image, jpg, format) for debugging purposes in the folder "debug".
%  The numbers written on each of this track is the trackId. 
%
%  The following code extracts only the tracks that have alteast 10
%  samples. If you have run demo01_basic_load.m before then this step
%  should be real quick as all the data were cached.

clc;clear;
exp = EuglenaTracks('./data1/',10);

%% We can make movie out of all or some images in the debug folder
%  In this example we create a movie from the first 100 frames.
M = exp.movieDebugFromFrames(1,exp.getNumFrames());
implay(M);
disp('Close the movie player and press any key to continue');
pause()
%% But given a trackID, you can find the corresponding track in matlab.
%  For example, trackID=90 seems quite interesting and long in the
%  debug folder, so lets investigate that closely.
%  NOTE: In your computer, trackID 90 may not exist and this step may FAIL.
%        In that case, just look the video
%        ./data1/tracks_thresholded_10.avi and pick any trackID.
track = exp.getTrackByID(90);

%% We can get all the geometry information of this track or any track by
%  the following. Euglena is deteced as oriented boxes, where x,y
%  are the center of the box. width and height are the corresponding lengths
%  where width is always the horizontal size and height the vertical.
%  "angles" is given in degrees and ranges from -90 to 90. Finaly, frames
%  is the frame number at which this euglena was detected. 
%
%  A track is basically a collection of such euglena boxes; so if there are
%  N boxes in the track, the dimention of each of the output variable will
%  be 1xN.

[x,y,width,height,angles,frames] = exp.extractTrackData(track);


%% Here is a very straightforward way to compute the point velocities 
%  of this track using forward differencing.

dt = (frames(2:end) - frames(1:end-1)) * (1.0/exp.getFPS());
vx = (x(2:end) - x(1:end-1)) ./ dt;
vy = (y(2:end) - y(1:end-1)) ./ dt;

%% You can visualize this track real quick by the following code
%  The options 'BorderColor' and etc are optional, please refer to 
%  the documentation of vision.ShapeInserter
%  (http://www.mathworks.com/help/vision/ref/vision.shapeinserter-class.html)
  
M = exp.movieFromTracks(track,'BorderColor','Custom','CustomBorderColor',[255,255,255]);
implay(M);
disp('Close the movie player and press any key to continue');
pause()

%% Finally, saving a movie
exp.movieSave('demo02_trackid',M);