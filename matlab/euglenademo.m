%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EuglenaTrack( datapath, magnification, threshold, 'debug' )
%  where 
%       datapath = path where movie.mp4 and lightdata.json are stored.
%       magnification = 10 or 4 (depending on the BPU)
%       threshold = Extracted traces have length > threshold. 
%                   e.g. threshold  = 0 extracts every trace.
%       'debug' is a string and its optional, setting this as the last
%       argument will output a bunch of *.tiff files with all tracks drawn
%       on them. The number written on each track in these images are
%       "trackID"
%       
%       Other examples"
%       exp = EuglenaTracks('./demo1/',10,10,'debug');

exp = EuglenaTracks('./demo3/',10);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Printing some basic info about the experiment
disp( sprintf('Total number of tracks extracted   : %d'  , exp.getNumTracks()) );
disp( sprintf('Total number of frames in the video: %d'  , exp.getNumFrames()) );
disp( sprintf('Total time of the experiment       : %f s', exp.getTotalTime()) );
disp( sprintf('Frames per second                  : %f s', exp.getFPS()) );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Getting a single track, out of many. Note matlab uses 1 based indexing.
%  Here we are getting the first track in our list.
singleTrack = exp.getTrackByIndex(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating a movie from the single track
%  Color and other properites are optonal. For more information about  
%  color and other properties see the help of vision.ShapeInserter 
%  http://www.mathworks.com/help/vision/ref/vision.shapeinserter-class.html

disp('Displaying one track [ Close the movie window and press any key to continue]');
M = exp.trackMovie(singleTrack,'BorderColor','Custom', 'CustomBorderColor', uint8([255 0 0]));
implay(M);
pause();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% We can select all the tracks that intersect with a given time interval.
%  Tracks that straddles the time boundaries are also selected.
%  Note: findTracksBetweenFrames takes arguments in frame numbers. Here we
%  we are getting all the tracks from 0sec to 10 sec. Not the
%  multiplication with getFPS() to convert time into frame number and +1 is
%  added because matlab uses 1 based indexing.

disp('Displaying multiple tracks within the first 10 secs [ Close the movie window and press any key to continue]');
tracks = exp.findTracksBetweenFrames(0*exp.getFPS()+1,10*exp.getFPS()+1);
Mmulti = exp.trackMovie(tracks,'BorderColor','Custom', 'CustomBorderColor', uint8([255 255 0]));
implay(Mmulti);
pause();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Some of the tracks in the previous line extend beyond the time boundary.
%  Here is an example of how to clip all the tracks with the time boundary.

disp('Displaying the same multipe tracks but are clipped on the first 10sec boundary [ Close the movie window and press any key to continue]');
clippedTracks = exp.clipTracksBetweenFrames(tracks,0*exp.getFPS()+1,10*exp.getFPS());
Mmulti_clipped = exp.trackMovie(clippedTracks,'BorderColor','Custom', 'CustomBorderColor', uint8([255 255 0]));
implay(Mmulti_clipped);
pause;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Getting x,y and other geometry of each track
%  Each track is a collection of oriented rectangles; extractTrackData
%  will extract the x,y of the center of all the rectangles, as well as
%  width, height, angles and frame number for each. Therefore, if there are
%  N rectangles in this track, the dimentions of x,y,width,height, angles
%  and frames will be 1xN. So the first rectangle will have an
%  x(1),y(1),width(1),height(1), angle(1) and frame(1).
%
%  The angle is between -90 to 90 (in degress). 
%
%  Here we show an example of how to compute point velocities for the first clippedTrack 

[x,y,width,height,angles,frames] = exp.extractTrackData( clippedTracks{1} );

dt = (frames(2:end) - frames(1:end-1)) * (1.0/exp.getFPS());
vx = (x(2:end) - x(1:end-1)) ./ dt;
vy = (y(2:end) - y(1:end-1)) ./ dt;