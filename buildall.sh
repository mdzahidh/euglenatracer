command -v cmake >/dev/null 2>&1 || { echo >&2 "Please install cmake before running this script.  Aborting."; exit 1; }

OSX_SDK_VERSION="10.9"
export MACOSX_DEPLOYMENT_TARGET=${OSX_SDK_VERSION}
root=$(pwd)
cd ffmpeg-2.8.4
./configure --prefix=$(pwd)/../local  --enable-pic --enable-avresample --disable-iconv --disable-lzma --disable-bzlib --disable-zlib --disable-encoders --disable-muxers --disable-demuxers --disable-decoders --enable-decoder=h264,mov --disable-indevs --disable-outdevs --disable-sdl --disable-securetransport --disable-parsers --enable-parser=h264,mov

#for windows
#Install MSYS
#Install MSYS 64 bit tool chain
#Open Visual Studio Command Prompt in 64 toolchain
#Run MingW64_shell.bat from MSYS directory
#Then Run the following
#./configure --prefix=$(pwd)/../local  --enable-pic --enable-avresample --disable-iconv --disable-lzma --disable-bzlib --disable-zlib -disable-outdevs --disable-sdl --disable-securetransport 

make && make install

cd ${root}/opencv
mkdir build
cd build
export PKG_CONFIG_PATH=$(pwd)/../../local/lib/pkgconfig:$PKG_CONFIG_PATH

cmake -DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${OSX_SDK_VERSION}.sdk" -DCMAKE_OSX_DEPLOYMENT_TARGET=${OSX_SDK_VERSION} -DBUILD_PERF_TESTS=OFF -DBUILD_TESTS=OFF -DBUILD_PNG=ON -DBUILD_JPEG=ON -DBUILD_TIFF=ON -DWITH_OPENEXR=OFF -DBUILD_ZLIB=ON -DWITH_WEBP=OFF -DBUILD_opencv_python2=OFF -DWITH_OPENGL=ON -DWITH_GSTREAMER=OFF -DWITH_GSTREAMER_0_10=OFF -D-DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/../../local" ../
make && make install

cd ${root}
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/local" ../
make && make install

cd ${root}/matlab/json-c
./autogen.sh
./configure --prefix=$(pwd)/../../local --enable-shared=no --with-pic
make && make install

cd ${root}/matlab/matlab_json
matlab -nodisplay -nosplash -nodesktop -r "make('-I../../local/include','-L../../local/lib'); exit;"
cp ${root}/matlab/matlab-json/*.mex* ${root}/matlab/
