cmake_minimum_required(VERSION 3.10)
project(OSGTest)

# 查找 OpenSceneGraph
find_package(OpenSceneGraph REQUIRED COMPONENTS osgDB osgViewer osgUtil osgGA osgText osg)

# 包含 OpenSceneGraph 的头文件
include_directories(${OPENSCENEGRAPH_INCLUDE_DIRS})

# 添加可执行文件
add_executable(osg_test main.cpp)

# 链接 OpenSceneGraph 库
target_link_libraries(osg_test ${OPENSCENEGRAPH_LIBRARIES})
