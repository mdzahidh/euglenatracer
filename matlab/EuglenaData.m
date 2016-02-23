classdef EuglenaData < handle 
   properties (Access = public)
        tracks
        lightData
        metaData
        zoom
        timeTable
        lightTable
        trackID2IndexMap
        totalTime
        fps
        numFrames
   end
   
   methods (Access = public)
       function this  = EuglenaData(path)
            % EuglenaTracks(path,
            if path(end) ~= filesep || path(end) ~= '/'
                path = strcat(path,filesep);
            end
            
            tracksPath = strcat(path,'tracks.json');
            fid = fopen(tracksPath);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            this.tracks = fromjson(str);
                        
            lightDataPath = strcat(path,'lightdata.json');            
            fid = fopen(lightDataPath);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            data = fromjson(str);
            
            this.lightData = data.eventsToRun;
            this.metaData  = data.metaData;
            
            if isfield(this.metaData,'numFrames')
               this.numFrames = this.metaData.numFrames;
            else
               error('The lightdata.json is not updated, use newer version');
            end
                        
            this.zoom = int32(this.metaData.magnification);           
            this.totalTime = single(this.lightData{end}.time - this.lightData{1}.time) / 1000.0;
            this.fps = single(this.numFrames) / this.totalTime;
            
            this.timeTable = int32(zeros(length(this.tracks), 4 ));
            
            for i = 1:length(this.tracks)   
                this.timeTable(i,:) = [this.tracks{i}.trackID, this.tracks{i}.startFrame+1, this.tracks{i}.lastFrame+1, this.tracks{i}.numSamples];
            end            
            this.trackID2IndexMap = containers.Map( this.timeTable(:,1), 1:length(this.tracks) );
            
            this.lightTable = single(zeros(length(this.lightData),5));
                
            baseTime = 0;
            if ~isempty(this.lightData)
                baseTime = double(this.lightData{1}.time);
            end

            for i = 1:length(this.lightData)
                l = this.lightData{i};
                this.lightTable(i,:) = [ single((double(l.time) - (baseTime))/1000.0), single(l.topValue), single(l.rightValue), ...
                                         single(l.bottomValue), single(l.leftValue) ];
            end
       end
       
       function umpp = getUMPP(this)
           umpp = 100.0/30.0 * 4.0 / double(this.zoom);
       end
       
       function n = getNumTracks(this)
           n = length(this.tracks);
       end
       
       function time = getTotalTime(this)
           time = this.totalTime;
       end
       
       function mag = getMagnification(this)
           mag = this.zoom;
       end
       
       function fps = getFPS(this)
           fps = this.fps;
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
   end
   
   methods(Static)
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
       
   end
end