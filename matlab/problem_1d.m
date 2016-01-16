%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zahid Hossain (zhossain@stanford.edu), 
% Honesty Kim (honestyk@stanford.edu)
% Riedel-Kruse Lab, Stanford Bioengineering, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load your data
%  replace ./data1 with appropriate path. All the tracks with atleast 10
%  samples will be loaded, feel free to change it.

exp = EuglenaTracks( './data1' ,10);

%% Check video
%  The previous step would produce a video by the name
%  tracks_thresholded_<threshold>.avi inside the data folder.
%  Play with that video and pick an interesting TrackID to extract here.

track = exp.getTrackByID( PLACE_YOUR_ID_HERE );

%% Make a movie out if this track
M = exp.movieFromTracks( track );

%% Watch the movie or save it
%  Uncomment whichever you want to do

% implay(M);
% exp.movieSave( 'problem_1c_single_track', M);

%% Extract coordinate of this track
%  A single track is a chain of oriented boxes. We also call each box a 
%  sample.
%
%  The output are: x,y coordinate of the center of the boxes,
%  width and height of the boxes, angles of orientation and the 
%  frame number these boxes appeared. A frame is a video frame and the
%  first number number is 1, just like anything else in Matlab.
%
%  NOTE: the boxes may not appear consecutively in frames, i.e.
%        one box may appear at frame# 10 and the next at frame# 13.
%        and so on.
[x,y,width,height,angles,frames] = exp.extractTrackData( track );


%% Compute the point velocity at every sample point (box center) of this track
%  Here we are simply doing a forward differencing in both x and y to
%  compute point velocities. Note the usage of exp.getFPS() to convert
%  frame numbers to actual time.

dt = (frames(2:end) - frames(1:end-1)) * (1.0/exp.getFPS());
vx = (x(2:end) - x(1:end-1)) ./ dt;
vy = (y(2:end) - y(1:end-1)) ./ dt;

%% Compute the average SPEED here
%% TODO
%%

%% Look at the video, use the scale bar or the function exp.getUMPP()
%  that returns the length scale in micro meter per pixel to estimate
%  the size of Euglena and compute the drag force below
%
%  NOTE: the width and height from the track data may not be a good
%  estimate of euglena size as these numbers are very conservative.

% YOUR DRAG FORCE COMPUTATION HERE