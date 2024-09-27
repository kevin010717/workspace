#install
curl https://www.ncnynl.com/rcm.sh | bash -
rcm -si  install_ros2_now
# 1.1 Configuring environment
echo "source /opt/ros/jazzy/setup.zsh" >> ~/.zshrc
printenv | grep -i ROS
export ROS_DOMAIN_ID=0
echo "export ROS_DOMAIN_ID=0" >> ~/.zshrc
# 1.2 Using turtlesim, ros2, and rqt
sudo apt update
sudo apt install ros-jazzy-turtlesim 
ros2 pkg executables turtlesim #turtlesim install
ros2 run turtlesim turtlesim_node 
ros2 run turtlesim turtle_teleop_key #在Ubuntu中执行
ros2 node list
ros2 topic list
ros2 service list
ros2 action list
sudo apt update
sudo apt install '~nros-jazzy-rqt*' #rqt install 
rqt
ros2 run turtlesim turtle_teleop_key --ros-args --remap turtle1/cmd_vel:=turtle2/cmd_vel #remap turtle cmd
# 1.3 Understanding nodes
ros2 run turtlesim turtlesim_node
ros2 node list
ros2 run turtlesim turtle_teleop_key
ros2 node list
ros2 run turtlesim turtlesim_node --ros-args --remap __node:=my_turtle
ros2 node list
ros2 node info /my_turtle
# 1.4 Understanding topics
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
rqt_graph
ros2 topic echo /turtle1/cmd_vel
ros2 topic info /turtle1/cmd_vel
ros2 interface show geometry_msgs/msg/Twist
ros2 topic pub --once /turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
ros2 topic pub --rate 1 /turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
ros2 topic pub /pose geometry_msgs/msg/PoseStamped '{header: "auto", pose: {position: {x: 1.0, y: 2.0, z: 3.0}}}'
ros2 topic pub /reference sensor_msgs/msg/TimeReference '{header: "auto", time_ref: "now", source: "dumy"}'
ros2 topic hz /turtle1/pose
# 1.5 Understanding services
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
ros2 service list
ros2 service type /clear
ros2 service list -t
ros2 service info /clear
ros2 service find std_srvs/srv/Empty
ros2 interface show std_srvs/srv/Empty
ros2 interface show turtlesim/srv/Spawn
ros2 service call /clear std_srvs/srv/Empty
ros2 service call /spawn turtlesim/srv/Spawn "{x: 2, y: 2, theta: 0.2, name: ''}"
ros2 launch demo_nodes_cpp introspect_services_launch.py
# 1.6 Understanding parameters
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
ros2 param list
ros2 param get /turtlesim background_g
ros2 param set /turtlesim background_r 150
ros2 param dump /turtlesim > turtlesim.yaml
ros2 param load /turtlesim turtlesim.yaml
ros2 run turtlesim turtlesim_node --ros-args --params-file turtlesim.yaml
# 1.7 Understanding actions
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key #watch print
ros2 node info /turtlesim
ros2 node info /teleop_turtle
ros2 action list
ros2 action list -t
ros2 action type /turtle1/rotate_absolute
ros2 action info /turtle1/rotate_absolute
ros2 interface show turtlesim/action/RotateAbsolute
ros2 action send_goal /turtle1/rotate_absolute turtlesim/action/RotateAbsolute "{theta: 1.57}"
ros2 action send_goal /turtle1/rotate_absolute turtlesim/action/RotateAbsolute "{theta: -1.57}" --feedback
# 1.8 Using rqt_console to view logs
ros2 run rqt_console rqt_console
ros2 run turtlesim turtlesim_node
ros2 topic pub -r 1 /turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0,y: 0.0,z: 0.0}}"
ros2 run turtlesim turtlesim_node --ros-args --log-level WARN
# 1.9 Launching nodes
ros2 launch turtlesim multisim.launch.py
ros2 topic pub  /turtlesim1/turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
ros2 topic pub  /turtlesim2/turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: -1.8}}"
# 1.10 Recording and playing back data
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
mkdir bag_files
cd bag_files
ros2 topic list
ros2 topic echo /turtle1/cmd_vel
ros2 bag record /turtle1/cmd_vel
ros2 bag record -o subset /turtle1/cmd_vel /turtle1/pose
ros2 bag info subset
ros2 bag play subset
ros2 topic hz /turtle1/pose
ros2 run demo_nodes_cpp introspection_service --ros-args -p service_configure_introspection:=contents
ros2 run demo_nodes_cpp introspection_client --ros-args -p client_configure_introspection:=contents

ros2 service list
ros2 service echo --flow-style /add_two_ints
ros2 bag record --all-services
ros2 bag record --service /add_two_ints
# ros2 bag info <bag_file_name>
#ros2 bag play --publish-service-requests <bag_file_name>
ros2 service echo --flow-style /add_two_ints
# 2.1 Using colcon to build packages
sudo apt install python3-colcon-common-extensions
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
git clone https://github.com/ros2/examples src/examples -b jazzy
colcon build --symlink-install
colcon test
source install/setup.zsh
ros2 run examples_rclcpp_minimal_subscriber subscriber_member_function
ros2 run examples_rclcpp_minimal_publisher publisher_member_function
echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ~/.zsh
echo "export _colcon_cd_root=/opt/ros/jazzy/" >> ~/.zsh
# 2.2 Creating a workspace
source /opt/ros/jazzy/setup.zsh
cd ~/ros2_ws/src/
git clone https://github.com/ros/ros_tutorials.git -b jazzy
cd ~/ros2_ws/
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build
source /opt/ros/jazzy/setup.zsh
source install/local_setup.zsh
ros2 run turtlesim turtlesim_node
# 2.3 Creating a package
cd ~/ros2_ws/src
ros2 pkg create --build-type acolcon buildment_cmake --license Apache-2.0 --node-name my_node my_package
ros2 pkg create --build-type ament_python --license Apache-2.0 --node-name my_node my_package_py
cd ~/ros2_ws/
colcon build
colcon build --packages-select my_package
colcon build --packages-select my_package_py
source install/local_setup.zsh
ros2 run my_package my_node
# 2.4 Writing a simple publisher and subscriber (C++)
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_cmake --license Apache-2.0 cpp_pubsub
cd ros2_ws/src/cpp_pubsub/src
wget -O publisher_lambda_function.cpp https://raw.githubusercontent.com/ros2/examples/jazzy/rclcpp/topics/minimal_publisher/lambda.cpp
wget -O subscriber_lambda_function.cpp https://raw.githubusercontent.com/ros2/examples/jazzy/rclcpp/topics/minimal_subscriber/lambda.cpp
#edit package.xml cmakelist.txt
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build --packages-select cpp_pubsub
source install/local_setup.zsh 
ros2 run cpp_pubsub talker
ros2 run cpp_pubsub listener
# 2.5 Writing a simple publisher and subscriber (Python)
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_python --license Apache-2.0 py_pubsub
cd ~/ros2_ws/src/py_pubsub/py_pubsub/
wget https://raw.githubusercontent.com/ros2/examples/jazzy/rclpy/topics/minimal_publisher/examples_rclpy_minimal_publisher/publisher_member_function.py
wget https://raw.githubusercontent.com/ros2/examples/jazzy/rclpy/topics/minimal_subscriber/examples_rclpy_minimal_subscriber/subscriber_member_function.py
#edit package.xml setup.py setup.cfg
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build --packages-select py_pubsub
source install/local_setup.zsh 
ros2 run py_pubsub talker
ros2 run py_pubsub listener
# 2.6 Writing a simple service and client (C++)
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_cmake --license Apache-2.0 cpp_srvcli --dependencies rclcpp example_interfaces
touch ~/ros2_ws/src/cpp_srvcli/src/add_two_ints_server.cpp
touch ~/ros2_ws/src/cpp_srvcli/src/add_two_ints_client.cpp
#edit *.cpp cmakelist.txt
cd ~/ros2_ws/
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build --packages-select cpp_srvcli
source ~/ros2_ws/install/local_setup.zsh
ros2 run cpp_srvcli server
ros2 run cpp_srvcli client 2 3
# 2.7 Writing a simple service and client (Python)
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_python --license Apache-2.0 py_srvcli --dependencies rclpy example_interfaces
touch ~/ros2_ws/src/py_srvcli/py_srvcli/service_member_function.py
touch ~/ros2_ws/src/py_srvcli/py_srvcli/client_member_function.py
# edit *.py setup.py
cd ~/ros2_ws/
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build --packages-select py_srvcli
source ~/ros2_ws/install/local_setup.zsh
ros2 run py_srvcli service
ros2 run py_srvcli client 2 3
# 2.8 Creating custom msg and srv files 
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_cmake --license Apache-2.0 tutorial_interfaces
mkdir tutorial_interfaces/msg tutorial_interfaces/srv
echo "int64 num">>tutorial_interfaces/msg/Num.msg
cat <<EOF >>tutorial_interfaces/msg/Sphere.msg
geometry_msgs/Point center
float64 radius
EOF
cat <<EOF >>tutorial_interfaces/srv/AddThreeInts.srv
int64 a
int64 b
int64 c
---
int64 sum
EOF
cat <<EOF >>tutorial_interfaces/CMakeLists.txt
find_package(geometry_msgs REQUIRED)
find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Num.msg"
  "msg/Sphere.msg"
  "srv/AddThreeInts.srv"
  DEPENDENCIES geometry_msgs # Add packages that above messages depend on, in this case geometry_msgs for Sphere.msg
)
EOF
sed -i '$d' tutorial_interfaces/package.xml
cat <<EOF >>tutorial_interfaces/package.xml
<depend>geometry_msgs</depend>
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<exec_depend>rosidl_default_runtime</exec_depend>
<member_of_group>rosidl_interface_packages</member_of_group>
</package>
EOF

colcon build --packages-select tutorial_interfaces
source ~/ros2_ws/install/local_setup.zsh
ros2 interface show tutorial_interfaces/msg/Num
ros2 interface show tutorial_interfaces/msg/Sphere
ros2 interface show tutorial_interfaces/srv/AddThreeInts
# C++ err:.hpp not found
# python edit .py packages.xml to test api
# 2.9 Implementing custom interfaces
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_cmake --license Apache-2.0 more_interfaces
mkdir more_interfaces/msg
cat <<EOF >>~/ros2_ws/src/more_interfaces/msg/AddressBook.msg
uint8 PHONE_TYPE_HOME=0
uint8 PHONE_TYPE_WORK=1
uint8 PHONE_TYPE_MOBILE=2

string first_name
string last_name
string phone_number
uint8 phone_type
EOF
# edit .cpp packages.xml CMakeLists.txt
cd ~/ros2_ws
colcon build --packages-up-to more_interfaces
source install/local_setup.bash
ros2 run more_interfaces publish_address_book
source install/setup.bash
ros2 topic echo /address_book
# 2.10 Using parameters in a class (C++)
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src/
ros2 pkg create --build-type ament_cmake --license Apache-2.0 cpp_parameters --dependencies rclcpp
# edit cpp_parameters_node.cpp CMakeLists.txt
rosdep install -i --from-path src --rosdistro jazzy -y
source install/setup.zsh
ros2 run cpp_parameters minimal_param_node
ros2 param list
ros2 param set /minimal_param_node my_parameter earth
# edit launch/cpp_parameters_launch.py CMakeLists.txt
colcon build --packages-select cpp_parameters
source install/setup.zsh
# 2.11 Using parameters in a class (Python)
ros2 pkg create --build-type ament_python --license Apache-2.0 python_parameters --dependencies rclpy
# edit python_parameters_node.py setup.py
rosdep install -i --from-path src --rosdistro jazzy -y
colcon build --packages-select python_parameters
source install/setup.zsh
ros2 run python_parameters minimal_param_node
ros2 param list
ros2 param set /minimal_param_node my_parameter earth
# edit launch/python_parameters_launch.py setup.py
colcon build --packages-select python_parameters
source install/setup.zsh
ros2 launch python_parameters python_parameters_launch.py
2.12 Using ros2doctor to identify issues
ros2 doctor
ros2 run turtlesim turtle_teleop_key
ros2 doctor
ros2 topic echo /turtle1/color_sensor
ros2 topic echo /turtle1/pose
ros2 doctor
ros2 doctor --report
# 2.12 Creating and using plugins (C++)
ros2 pkg create --build-type ament_cmake --license Apache-2.0 --dependencies pluginlib --node-name area_node polygon_base
ros2 pkg create --build-type ament_cmake --license Apache-2.0 --dependencies polygon_base pluginlib --library-name polygon_plugins polygon_plugins
# edit .hpp .cpp CMakeLists.txt plugins.xml
colcon build --packages-select polygon_base polygon_plugins
source install/setup.zsh
ros2 run polygon_base area_node
# 3.1 Managing Dependencies with rosdep

