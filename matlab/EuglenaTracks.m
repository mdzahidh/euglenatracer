classdef EuglenaTracks < handle 
   properties (Access = public)
       tracks
       timeTable
       lightTable
       trackID2IndexMap
       lightData
       videoFrames
       totalTime
       fps
       zoom
       metaData
       numFrames
       path
       compat
       fullMoviePath
       thresholdMoviePath
       fullMovieCache
       thresholdedMovieCache
       legacyDrawing
   end
   methods(Access = private)
       
       function J = insertShape(this,I,type,pos,varargin)
           if ~this.legacyDrawing
               J = insertShape(I,type,pos,varargin{:});
           else
               hshape = vision.ShapeInserter('Shape','Lines');
               J = step(hshape,I,int32(pos));
           end           
       end
       
       function J = insertText(this, I, pos, texts, varargin)
           if ~this.legacyDrawing
               J = insertText(I,pos,texts,varargin{:});
           else                             
               if ~iscell(texts)
                   texts = {texts};
               end
               hTxt = vision.TextInserter('%s','LocationSource', 'Input port', 'Color',[255,255,255]);
               numTexts = [];
               for i=1:length(texts)
                   if i < length(texts)
                       numTexts = [numTexts,uint8(texts{i}),0];
                   else
                       numTexts = [numTexts,uint8(texts{i})];
                   end                   
               end               
               J = step(hTxt,I,numTexts,int32(pos));
           end
       end
       
       function drawTrackByIndex(this, idx)           
           samples = this.tracks{idx}.samples;
           points = zeros(2,length(samples));
           for i = 1:length(samples)
               rect = samples{i}.rect;      
               points(:,i) = [rect{1},rect{2}]';
           end
           line(points(1,:),points(2,:));
       end
       
       function drawTrackByID(this, trackID)
           idx = this.findTrackID(trackID);
           this.drawTrackByIndex(idx);
       end
              
       function M = trackMovieByIndex(this,idx)
           M = trackMovie(this.getTrackByIndex(idx));            
       end
       
       function M = trackMovieByID( this, trackID )
           M = this.trackMovieByIndex( this.findTrackID( trackID ) );
       end
       
       function M = multiTrackMovie(this, tracks, varargin)
           minFrame = inf;
           maxFrame = 0;           
                     
           for i =1:length(tracks)
               minFrame = min(minFrame, tracks{i}.startFrame);
               maxFrame = max(maxFrame, tracks{i}.lastFrame);
           end
           
           M = this.movieFromFramesWithTracks( minFrame,maxFrame, tracks, varargin{:} );
       end
       
       
       function M = movieFromFramesWithTracks(this, startFrame, endFrame, tracks, varargin)
           
           minFrame = max(startFrame, 1);
           maxFrame = min(endFrame,this.getNumFrames());           
           
           textprogressbar('Making movie from frames: ');
           
           pointList = {};
           boxList = {};
           for i =1:length(tracks)
               pointList{i} = []; 
               boxList{i} = [];
           end
           
           totalFrames = maxFrame - minFrame + 1;
           M = uint8(zeros(480,640,3,totalFrames,'uint8'));
           sampleIdx = int32(zeros(length(tracks),totalFrames));
           
           for i = 1:length(tracks)
               t = tracks{i};
               for j=1:t.numSamples
                   s = t.samples{j};
                   sampleIdx(i,s.frame - minFrame + 1) = j;
               end
           end                      
           
           for f= minFrame:maxFrame
               j = f - minFrame + 1;
               frame = this.getVideoFrame(f);
               for i=1:length(tracks)
                   idx = sampleIdx(i,j);
                   if( idx > 0 )
                       s = tracks{i}.samples{idx};
                       points = pointList{i};
                       points(end+1) = s.rect{1};
                       points(end+1) = s.rect{2};
                       pointList{i} = points;
                       
                       boxPoints = this.rectPoints(s.rect);
                       boxList{i} = boxPoints;
                   end
               end
               
               allTexts = {};               
               allPositions = zeros(0,2);
               allLines = zeros(0,4);
                              
               for i=1:length(tracks)                                                                         
                   if f <= tracks{i}.lastFrame                       
                       points = pointList{i};
                       if length(points) > 2                            
                           for n=2:length(points)/2                               
                               id1x = n*2 - 3;
                               id1y = id1x + 1;                               
                               id2x = n*2 - 1;
                               id2y = id2x + 1;                               
                               lines = [ points(id1x), points(id1y), points(id2x), points(id2y) ];
                               allLines(end+1,:) = lines;
                           end
                       end

                       boxPoints = boxList{i};                       
                       if ~isempty(boxPoints)
                           boxPoints(:,end+1) = boxPoints(:,1);
                           
                           lines = [boxPoints(:,1)' boxPoints(:,2)';
                                   boxPoints(:,2)' boxPoints(:,3)';
                                   boxPoints(:,3)' boxPoints(:,4)';
                                   boxPoints(:,4)' boxPoints(:,1)'];
                           
                           allLines(end+1:end+4,:) = lines;
                           
                           loc = boxPoints(:,1);
                           allPositions(end+1,:) = loc';
                                                      
                           allTexts{end+1} = sprintf('%d',tracks{i}.trackID);                           
                       end                                                                     
                   end                                      
               end
               
               if ~isempty(allLines)
                   frame = this.insertShape(frame,'Line',allLines,'Color','black','SmoothEdges',false);
               end
               if ~isempty(allPositions)
                   frame = this.insertText( frame, allPositions, allTexts, 'BoxOpacity',0.0,'TextColor','white'); 
               end
               
               frame = this.annotateImage(f,frame);
               M(:,:,:,j) = frame;               
               textprogressbar(single(j)/single(totalFrames) * 100.0);
           end
           textprogressbar('Done');
       end
       function J = annotateImage( this, frame, I )
           
            leds = this.getLedStatesFromFrame( frame );
            time    = single(frame) * 1.0 / this.getFPS();
            zoom    = this.getMagnification();
            
            allLedTexts = {sprintf('%3d',leds(1));
                           sprintf('%3d',leds(2)); 
                           sprintf('%3d',leds(3)); 
                           sprintf('%3d',leds(4)) 
                           };
                           
            allLedPositions = [320,10;
                              640-50,240;
                              320,480-24-10;
                              10,240];
            J = I;            
            J = this.insertText(J,allLedPositions,allLedTexts,'BoxColor','black','TextColor','yellow');
            
            J = this.insertText(J,[10,10],sprintf('Frame %d (t = ~%4.2fs)',frame,time));

            % umpp = 100.0/30.00
            w = 30.0 * zoom / 4.0;
            line = [640 - int32(w) - 30,480-10, 640-10,480-10];

            if ~this.compat
                J = this.insertShape(J,'Line',line,'LineWidth',5,'Color','White');
            else
                J = this.insertShape(J,'Line',line,'Color','White');
            end
            
            loc = [640 - int32(w) - 30,480-40];
            J = this.insertText(J,loc,'100um');

       end
       
       function loadAllVideoFrames(this)            
            moviePath = strcat(this.path,'movie.mp4');
%             v = VideoReader(moviePath);
%             textprogressbar('Loading all video frames: ');
%             
% %            this.videoFrames = cell(this.numFrames,1);
% %             i = 1;
% %             while hasFrame(v)
% %                 this.videoFrames{i} = readFrame(v);
% %                 i = i + 1;
% %                 textprogressbar(i / this.getNumFrames() * 100.0);
% %             end
% 
%             this.videoFrames = uint8(zeros(480,640,3,this.getNumFrames()));
%             this.videoFrames = read(v,[1,this.getNumFrames()]);            
%             textprogressbar('Done');
             this.videoFrames = readvid(moviePath);
       end
       
       function f = getVideoFrame(this,i)
           if isempty(this.videoFrames)
              this.loadAllVideoFrames(); 
           end
           f = this.videoFrames(:,:,:,i);
       end
               
   end
   methods (Access = public)
       function this  = EuglenaTracks(path,threshold,varargin)
            v = version();
            v = str2double(v(1:3));
            this.compat = false;
            this.legacyDrawing = false;
            
            if v <= 8.1
                this.compat = true;
            end
            
            if v <= 8.0
                this.legacyDrawing = true;
            end
            
           % EuglenaTracks(path,
            if path(end) ~= filesep || path(end) ~= '/'
                path = strcat(path,filesep);
            end
               
            this.videoFrames = {};
            this.path = path;
            debug = true;
                        
            lightDataPath = strcat(path,'lightdata.json');            
            fid = fopen(lightDataPath);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            data = fromjson(str);
            
            this.lightData = data.eventsToRun;
            this.metaData  = data.metaData;
            
            this.zoom = int32(this.metaData.magnification);
            
            this.totalTime = single(this.lightData{end}.time - this.lightData{1}.time) / 1000.0;
                        
                                    
            moviePath = strcat(path,'movie.mp4');            
            this.numFrames = numvidframes(moviePath);         
            this.fps = this.numFrames / this.totalTime
                        
            cachePath = strcat(path,sprintf('cache_%d.mat',threshold));
            fid = fopen(cachePath);
            if( fid >=0 )
                display('Loading tracks from cache');
                fclose(fid);
                cache = load(cachePath);
                this.tracks = cache.tracks;
                this.lightTable = cache.lightTable;
                this.timeTable = cache.timeTable;
                this.trackID2IndexMap = cache.trackID2IndexMap;
                display('Done');
            else
                debugPath = sprintf('%sdebug',this.path);
                mkdir(debugPath);
                delete(sprintf('%sdebug/*.jpg',this.path));
            
                display('Extracting tracks');                        
                if ~debug
                    json = euglena(moviePath,this.zoom,'threshold',threshold);
                else
                    json = euglena(moviePath,this.zoom,'threshold',threshold,'debug',debugPath);
                end
                this.tracks = fromjson(json);
                % Fixing 0 based indexing into 1 based
                for i=1:length(this.tracks)                                
                    this.tracks{i}.startFrame = this.tracks{i}.startFrame  + 1;
                    this.tracks{i}.lastFrame = this.tracks{i}.lastFrame  + 1;                   
                    for j=1:this.tracks{i}.numSamples
                        this.tracks{i}.samples{j}.frame = this.tracks{i}.samples{j}.frame + 1;
                    end
                end
                
                this.timeTable = int32(zeros(length(this.tracks), 4 ));
                for i = 1:length(this.tracks)   
                    this.timeTable(i,:) = [this.tracks{i}.trackID, this.tracks{i}.startFrame+1, this.tracks{i}.lastFrame+1, this.tracks{i}.numSamples];
                end            
                this.trackID2IndexMap = containers.Map( this.timeTable(:,1), 1:length(this.tracks) );
            
                this.lightTable = single(zeros(length(this.lightData),5));
            
                baseTime = 0;
                if length(this.lightData) > 0
                    baseTime = double(this.lightData{1}.time);
                end

                for i = 1:length(this.lightData)
                    l = this.lightData{i};
                    this.lightTable(i,:) = [ single((double(l.time) - (baseTime))/1000.0), single(l.topValue), single(l.rightValue), ...
                                             single(l.bottomValue), single(l.leftValue) ];
                end
                
                tracks     = this.tracks;
                lightTable = this.lightTable;
                timeTable  = this.timeTable;
                trackID2IndexMap = this.trackID2IndexMap;
                
                save(cachePath,'tracks', 'lightTable', 'timeTable','trackID2IndexMap');
            end
            
            this.fullMoviePath = sprintf('%sdebug.avi',this.path);
            fid = fopen(this.fullMoviePath);
            if( fid < 0 )
                disp('Creating full movie with all the tracks (regardless of threshold )');
                disp('This may take a while but the result will be cached');
                M = this.movieDebugFromFrames( 1, this.getNumFrames() );
                this.fullMovieCache = M;
                display('Saving...');
                this.movieSave(this.fullMoviePath,M);                
                disp(sprintf('Saved as %s',this.fullMoviePath));
            end
            
            this.thresholdMoviePath = sprintf('%stracks_thresholded_%d.avi',this.path,threshold);
            fid = fopen(this.thresholdMoviePath);
            if( fid < 0 )
                disp('Creating movie with thresholded tracks');
                disp('This may take a while but the result will be cached');
                M = this.movieFromFrames( 1, this.getNumFrames() );
                this.thresholdedMovieCache = M;
                display('Saving...');
                this.movieSave(this.thresholdMoviePath,M);
                disp(sprintf('Saved as %s',this.thresholdMoviePath));
            end
       end
       
       function umpp = getUMPP(this)
           umpp = 100.0/30.0 * 4.0 / double(this.zoom);
       end
       
       function n = getNumTracks(this)
           n = length(this.tracks);
       end
       
       function n = getNumFrames(this)
           n = this.numFrames;
       end
              
       function time = getTotalTime(this)
           time = this.totalTime;
       end
       
       function fps = getFPS(this)
           fps = this.fps;
       end
       
       function mag = getMagnification(this)
           mag = this.zoom;
       end
       
       function M = movieLoad(this)
           if isempty(this.thresholdedMovieCache)
%                v = VideoReader(this.thresholdMoviePath);
%                this.thresholdedMovieCache = read(v,[1,v.NumberOfFrames]);
                this.thresholdedMovieCache = readvid(this.thresholdMoviePath);
           end
           M = this.thresholdedMovieCache;
       end
       
       function M = movieDebugLoad(this)
           if isempty(this.fullMovieCache)
%                v = VideoReader(this.fullMoviePath);
%                this.fullMovieCache = read(v,[1,v.NumberOfFrames]);
                this.fullMovieCache = readvid(this.fullMoviePath);
           end
           M = this.fullMovieCache;
       end
       
       function idx = findTrackID(this,trackID)
           idx = this.trackID2IndexMap(trackID );
       end
       
       function filteredTracks = findTracksBetweenFrames(this,startFrame, endFrame)
            filter = ~(this.timeTable(:,3) < startFrame | this.timeTable(:,2) > endFrame);
            filteredTracks = this.tracks(filter);            
       end
                         
              
       function track = getTrackAt(this,index)
           track = this.tracks{index};
       end
       
       function track = getTrackByID(this,id)
           idx = this.findTrackID(id);
           track = this.getTrackAt(idx);
       end
       
              
       function M = movieFromTracks(this, track, varargin)
           if isa(track,'cell')
               M = this.multiTrackMovie(track, varargin{:});
           else
               M = this.multiTrackMovie({track}, varargin{:});
           end
       end
       
       
       function M = movieFromFrames(this, startFrame, endFrame, varargin)
           M = this.movieFromFramesWithTracks(startFrame,endFrame,this.tracks,varargin{:});
       end
              
           
       function [x,y,width,height,angles,frames] = extractEuglenaFromFrames( this, startFrame, endFrame )
           
           x      = [];
           y      = [];
           width  = [];
           height = [];
           angles = [];
           frames = [];
           
           for i=1:this.getNumFrames()
               t = this.tracks{i};
               if ~(t.startFrame > endFrame || t.lastFrame < startFrame)
                   for j = 1:t.numSamples
                       s = t.samples{j};
                       if (s.frame) >= startFrame && (s.frame <= endFrame)
                           x(end+1)      = s.rect{1};
                           y(end+1)      = s.rect{2};
                           width(end+1)  = s.rect{3};
                           height(end+1) = s.rect{4};
                           angles(end+1) = s.rect{5};
                           frames(end+1) = s.frame;
                       end
                   end
               end
           end
           
       end
       
       function leds = getLedStatesFromTime( this, t )
           mask = t < this.lightTable(:,1);
           idx = find(mask);
           if isempty(idx)
               leds = [0,0,0,0];
               return
           end
           
           idx = idx(1);
           if idx == 1
               leds = [0,0,0,0];
               return
           else
               leds = this.lightTable(idx-1,2:end);
               return
           end
       end              
       
       function leds = getLedStatesFromFrame( this, frame )
           leds =  this.getLedStatesFromTime( (single(frame)-1) * 1.0/this.getFPS() );
       end
       
       function M = movieDebugFromFrames(this,startFrame,endFrame)
           textprogressbar('Creating debug movie: ');
           
           totalFrames = endFrame - startFrame + 1;           
           M = uint8(zeros(480,640,3,totalFrames,'uint8'));           
           
           startFrame = max(startFrame,1);
           endFrame   = min(endFrame, this.getNumFrames());
           
           
           for i=startFrame:endFrame
               imageFile = sprintf('%sdebug/%05d.jpg', this.path,i-1);
               I = imread(imageFile);
               I = this.annotateImage( i, I );
               M(:,:,:,i-startFrame+1) = I;
               textprogressbar( (i - startFrame + 1) / totalFrames * 100 );
           end
           textprogressbar('Done');
       end
   end
   
    
   methods(Static)
       
       
       function drawPoints( points )
           points(:,end+1) = points(:,1);
           line(points(1,:),points(2,:));
       end
       
       function points = rectPoints( rect )
           center_x = single(rect{1});
           center_y = single(rect{2});
           width    = single(rect{3});
           height   = single(rect{4});
           angle    = single(rect{5});
           ca = cosd(angle);
           sa = sind(angle);
           M = [ca,-sa;sa,ca];
           points = zeros(2,4);
           halfWidth = width/2.0;
           halfHeight = height/2.0;
           points(:,1) = [- halfWidth, - halfHeight]';
           points(:,2) = [halfWidth, - halfHeight]';
           points(:,3) = [halfWidth, + halfHeight]';
           points(:,4) = [- halfWidth,+ halfHeight]';
           points = M * points + repmat([center_x,center_y]',1,4);
       end
       
       function figure()
           figure();
           axis ij;
           xlim([0,639]);
           ylim([0,439]);
       end
       
       
       function allClippedTracks = clipTracksBetweenFrames(tracks, startFrame, endFrame)
           
           allClippedTracks = {};
           
           if ~iscell(tracks)
               tracks = {tracks};
           end
           
           for i = 1:length(tracks)
               t = tracks{i};
               if t.startFrame > endFrame || t.lastFrame < startFrame 
                   %completely outside, so just ignore                   
               elseif t.startFrame >= startFrame && t.lastFrame <= endFrame
                   %completely inside, so just take the whole thing
                   allClippedTracks{end+1} = t;
               else
                   clippedTrack = t;
                   clippedTrack.samples = {};
                   minFrame = inf;
                   maxFrame = -1;
                   for j = 1:t.numSamples
                       sample = t.samples{j};
                       if sample.frame >= startFrame && sample.frame <= endFrame

                           minFrame = min(minFrame,sample.frame);
                           maxFrame = max(maxFrame,sample.frame);                      

                           clippedTrack.samples{end+1} = sample;
                       end
                   end

                   if ~isempty(clippedTrack.samples) 
                       clippedTrack.startFrame = minFrame;
                       clippedTrack.lastFrame = maxFrame;
                       clippedTrack.numSamples = length(clippedTrack.samples);
                       allClippedTracks{end+1} = clippedTrack;
                   end
               end
           end
       end
       
       function [center_x,center_y,width,height,angles,frames] = extractTrackData(track)
           N = track.numSamples;
           
           center_x = zeros(1,N);
           center_y = zeros(1,N);
           angles   = zeros(1,N);
           frames   = zeros(1,N);
           width    = zeros(1,N);
           height   = zeros(1,N);           
           
           for i=1:N
               s = track.samples{i};
               rect = s.rect;
               center_x(i) = rect{1};
               center_y(i) = rect{2};
               width(i)    = rect{3};
               height(i)   = rect{4};
               angles(i)   = rect{5};
               frames(i)   = s.frame;
           end
       end
       
       function drawTrack(track,varargin)           
           samples = track.samples;
           points = zeros(2,length(samples));
           for i = 1:length(samples)
               rect = samples{i}.rect;      
               points(:,i) = [rect{1},rect{2}]';
           end           
           line(points(1,:),points(2,:),varargin{:});
       end
       
       function movieSave(fname,M,varargin)
           v = VideoWriter(fname,varargin{:});
           open(v);
           writeVideo(v,M);
           close(v);
       end
       
       %this.insertShape(frame,'Line',allLines,'Color','black','SmoothEdges',false);
       
       
   end
end
