from EuglenaData import *

e = EuglenaData('/Users/zhossain/work/euglenatracer/matlab/data1')

print "UMPP:",  e.getUMPP()
print "Number of Tracks: ", e.getNumTracks()
print "Total Time: ", e.getTotalTime()
print "FPS: ", e.getFPS()
print "Zoom: ", e.getMagnification()
tracks = e.findTracksBetweenFrames(100,200)
print "Number of tracks between 100, and 200 are: ", len(tracks)
print [t['trackID'] for t in tracks]
print e.getTrackAt(0)['trackID']
singleTrack = e.getTrackByID(90)
print singleTrack
e.writeTrackDataToCSV(singleTrack,'track90.csv')

x,y,w,h,a,f = e.extractEuglenaBetweenFrames(100,200)
print "Number of euglenas between 100 and 200: ", len(x)
leds = e.getLedStateFromTime(45)
print 'LED State at Time 45 sec', leds

leds = e.getLedStateFromFrame(130)
print 'LED State at Time 100th frame', leds

x,y,w,h,a,f = e.extractTrackData(singleTrack)
print x
print y
print w
print h
print a
print f

clippedTracks = e.clipTracksBetweenFrames(tracks,100,200)
print "Number of tracks after clipping between 100, and 200 are: ", len(clippedTracks)
print clippedTracks