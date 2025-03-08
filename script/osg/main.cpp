#include <osgViewer/Viewer>
#include <osgDB/ReadFile>

int main(int argc, char** argv) {
    // 创建一个 Viewer
    osgViewer::Viewer viewer;

    // 加载模型
    osg::ref_ptr<osg::Node> model = osgDB::readNodeFile("cow.osg");
    if (!model) {
        std::cerr << "无法加载模型文件！" << std::endl;
        return -1;
    }

    // 设置场景数据
    viewer.setSceneData(model);

    // 运行 Viewer
    return viewer.run();
}
