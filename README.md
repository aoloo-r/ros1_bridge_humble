# ROS1–ROS2 Bridge on Ubuntu 22.04

This repository demonstrates bridging topics between ROS 1 Noetic (running in a Docker container) and a local ROS 2 Humble environment on Ubuntu 22.04.
Overview

    ROS 1 side: Runs in a Docker container (ros:noetic-ros-base-focal) with host networking (--net=host).
    ROS 2 side: Installed locally on Ubuntu 22.04 (ros-humble-desktop or ros-humble-ros-base).
    Bridging is done with a prebuilt or locally compiled ros1_bridge, which dynamically translates messages/services between ROS 1 and ROS 2.

Prerequisites

    Native Docker on Ubuntu 22.04 (not Docker Desktop).
    ROS 2 Humble installed on the host (e.g., sudo apt-get install ros-humble-desktop).
    (Optional) A prebuilt bridging package folder, ros-humble-ros1-bridge/ (obtained by building a special Docker image or by installing ros-humble-ros1-bridge directly).

Step-by-Step Usage

    Run the ROS 1 container with host networking:

docker run -it --net=host ros:noetic-ros-base-focal bash

Inside the container:

## Install a demo talker (if not installed)
apt-get update && apt-get install -y ros-noetic-rospy-tutorials

## Source ROS 1 and run roscore
source /opt/ros/noetic/setup.bash
roscore &   # or use another tab/shell

## In a second tab, run a talker publishing on /chatter
source /opt/ros/noetic/setup.bash
rosrun rospy_tutorials talker

On the host (Ubuntu 22.04 with ROS 2):

## Point to the container’s roscore on localhost:11311
export ROS_MASTER_URI=http://localhost:11311

## Source your ROS 2 environment
source /opt/ros/humble/setup.bash

## Source the ros1_bridge overlay (if you have it locally)
cd ros-humble-ros1-bridge
source install/local_setup.bash

## Run the dynamic bridge
ros2 run ros1_bridge dynamic_bridge

In another host terminal, you can check ROS 2 topics:

    source /opt/ros/humble/setup.bash
    ros2 topic list          # should include /chatter
    ros2 topic echo /chatter # see "hello world" messages from ROS1

Result

You’ll see messages published by Noetic inside the container (on /chatter) appearing under ROS 2 in your host environment, confirming that the bridge is operational.
Common Issues

    Cannot contact master: Ensure --net=host is used on a native Docker install, and export ROS_MASTER_URI=http://localhost:11311 is set on the host.
    No /chatter topic: Make sure a ROS 1 talker is actually publishing. The dynamic bridge creates new bridges only if a publisher is detected.
    Package 'ros1_bridge' not found: You must source the correct workspace that contains the ros1_bridge build.
