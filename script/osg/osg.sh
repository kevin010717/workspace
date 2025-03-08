sudo apt update
sudo apt install build-essential cmake git

sudo apt install libgl1-mesa-dev libglu1-mesa-dev \
libx11-dev libxi-dev libxrandr-dev libxinerama-dev \
libxcursor-dev libssl-dev libjpeg-dev libpng-dev \
libtiff-dev libopenexr-dev libcurl4-gnutls-dev \
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libgtk2.0-dev libqt5opengl5-dev libqt5svg5-dev \
libqt5webkit5-dev libqt5xmlpatterns5-dev \
libqt5x11extras5-dev libqt5concurrent5

git clone https://github.com/openscenegraph/OpenSceneGraph.git
cd OpenSceneGraph

mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
export OSG_DIR=/usr/local
export LD_LIBRARY_PATH=$OSG_DIR/lib:$LD_LIBRARY_PATH
export PATH=$OSG_DIR/bin:$PATH
osgversion

cd ~
mkdir osg_test
cd osg_test
