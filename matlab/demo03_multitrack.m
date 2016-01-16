%% We again trace the experiment from scratch, with threshold set to 10
clc;clear;
exp = EuglenaTracks('./data1/',10);

%% Next, lets find all the tracks that intersects the frames from 100 to 200
%  NOTE: the variable "tracks" is a list of tracks
tracks = exp.findTracksBetweenFrames(100,200);
disp( sprintf('There are %d selected',length(tracks)) );

%% We can use the exact same function exp.movieFromTracks to 
%  quickly visualize all the selected tracks together
%  NOTE: some tracks may straddle the frame boundaries therefore in the
%  visualization the frames may start at an earlier number and end much
%  later than 200.
M = exp.movieFromTracks(tracks);
implay(M);
disp('Close the movie player and press any key to continue');
pause()
%% We can take a list of tracks and clip them with the frame boundaries, e.g.
%  this time, the visualization will start sharply at frame 100 and end at
%  200 because all the tracks are properly clipped.
%  HINT: You can use the function exp.getFPS() to convert frame numbers
%  into time and vice versa.
clippedTracks = exp.clipTracksBetweenFrames(tracks,100,200);
M_clipped_frame = exp.movieFromTracks(clippedTracks);
implay(M_clipped_frame);
disp('Close the movie player and press any key to continue');
pause()

%% We can use exctract geometry information from these clipped tracks
%  to compute various statistics within a frame period or time period
%  precisely.
%
%  For example: in the following we extracted geometry from the first
%  clippedTrack.

[x,y,width,height,angles,frames] = exp.extractTrackData( clippedTracks{1} );