cmake_minimum_required (VERSION 2.6)

set( ENV{PKG_CONFIG_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/local/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}:")
if (UNIX)
    find_package(PkgConfig REQUIRED)
endif()

macro(CHECK_MODULE module_name define)
  set(${define} 0)
  if(PKG_CONFIG_FOUND)
    set(ALIAS               ALIASOF_${module_name})
    set(ALIAS_FOUND                 ${ALIAS}_FOUND)
    set(ALIAS_INCLUDE_DIRS   ${ALIAS}_INCLUDE_DIRS)
    set(ALIAS_LIBRARY_DIRS   ${ALIAS}_LIBRARY_DIRS)
    set(ALIAS_LIBRARIES         ${ALIAS}_LIBRARIES)

    PKG_CHECK_MODULES(${ALIAS} ${module_name})

    if(${ALIAS_FOUND})
      set(${define} 1)
      foreach(P "${ALIAS_INCLUDE_DIRS}")
        if(${P})
          list(APPEND MODULE_INCLUDE_DIRS ${${P}})
        endif()
      endforeach()

      foreach(P "${ALIAS_LIBRARY_DIRS}")
        if(${P})
          list(APPEND MODULE_LIBRARY_DIRS ${${P}})
        endif()
      endforeach()
      list(APPEND MODULE_LIBRARIES ${${ALIAS_LIBRARIES}})
    endif()
  endif()
endmacro()

project(euglena)


#find_package(OpenCV REQUIRED PATHS $ENV{OpenCV_ROOT_DIR}/share/OpenCV/ NO_DEFAULT_PATH)
if(NOT WIN32)
  find_package(OpenCV REQUIRED PATHS ./local/share/OpenCV/ NO_DEFAULT_PATH)
else(NOT WIN32)
  find_package(OpenCV REQUIRED PATHS ./local/x64/vc12/staticlib/ NO_DEFAULT_PATH)
endif(NOT WIN32)


CHECK_MODULE(libavresample HAVE_FFMPEG_RESAMPLE)
CHECK_MODULE(libswscale HAVE_FFMPEG_SWSCALE)
CHECK_MODULE(libavformat HAVE_FFMPEG_FORMAT)
CHECK_MODULE(libavcodec HAVE_FFMPEG_CODEC)
CHECK_MODULE(libswresample HAVE_FFMPEG_SWSCALE)
CHECK_MODULE(libavutil HAVE_FFMPEG_UTIL)

if(UNIX)
  #these variables are set by CHECK_MODULE macro
  foreach(P ${MODULE_INCLUDE_DIRS})
    ocv_include_directories(${P})
  endforeach()

  foreach(P ${MODULE_LIBRARY_DIRS})
    link_directories(${P})
  endforeach()
endif()

link_directories("C:/src/euglenalab/game/detection/local/lib")

if (OPENCV_FOUND)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenCV_INCLUDE_DIRS}")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenCV_INCLUDE_DIRS}")
endif()


set(UNIXFLAGS "")
if( NOT WIN32 )
    add_definitions(-Doverride=)
    set( UNIXFLAGS "-std=c++0x" )
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
      set( UNIXFLAGS "${UNIXFLAGS}" )
    endif()
    SET(EXTRA_LIBS "-lavresample -lswscale -lavformat -lavcodec -lswresample -lavutil")
elseif(WIN32)

endif()

IF(APPLE)
   FIND_LIBRARY(SECURITY_LIBRARY Security)
   FIND_LIBRARY(VT_LIBRARY VideoToolBox)
   FIND_LIBRARY(CM_LIBRARY CoreMedia)
   MARK_AS_ADVANCED (CM_LIBRARY
                     SECURITY_LIBRARY
                     VT_LIBRARY
                     )
   SET(EXTRA_LIBS ${SECURITY_LIBRARY} ${VT_LIBRARY} ${CM_LIBRARY})
ENDIF (APPLE)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${UNIXFLAGS}")

message(${OpenCV_LIBRARIES})

add_executable(euglena tracker.h tracker.cpp intersection.cpp intersection.h euglena.cpp)
target_link_libraries(euglena ${OpenCV_LIBRARIES} ${EXTRA_LIBS})
install (TARGETS euglena DESTINATION bin)
