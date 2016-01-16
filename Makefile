SRC := euglena.cpp intersection.cpp ./munkres-cpp/src/munkres.cpp

SRC_OBJS := $(SRC:.cpp=.o)
LIBS := -lopencv_objdetect  -lopencv_highgui -lopencv_videoio  -lopencv_video  -lopencv_imgproc -lopencv_core
CXXFLAGS := -O2 -Wall -std=c++11

all:euglena

%.o:%.cpp
	g++ $(CXXFLAGS) -c  $< -o $@

euglena:$(SRC_OBJS)
	g++ -o euglena $(SRC_OBJS) $(LIBS)

clean:
	rm -f eugelna $(SRC_OBJS)
