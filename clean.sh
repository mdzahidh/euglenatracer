root=$(pwd)
rm -fr ${root}/local/bin
rm -fr ${root}/local/lib
rm -fr ${root}/local/include
rm -fr ${root}/local/share
rm -fr ${root}/local/man

cd ffmpeg-2.8.4
make clean

cd ${root}/opencv/build
make clean
rm -f CMakeCache.txt

cd ${root}/build
make clean
rm -f CMakeCache.txt

cd ${root}/matlab/json-c
make clean
