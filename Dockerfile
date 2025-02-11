# Use Ubuntu 22.04 (jammy) as the base image for ROS2 Humble
FROM ubuntu:jammy

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic utilities and build tools
RUN apt-get update && apt-get install -y \
    lsb-release \
    gnupg2 \
    curl \
    wget \
    git \
    build-essential \
    cmake

# --- Setup ROS2 Humble (officially supported on Jammy) ---
# Add the ROS2 Humble apt repository and its key
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu jammy main" \
      > /etc/apt/sources.list.d/ros2-latest.list

# --- Setup ROS Noetic (using Focal repository) ---
# Add the ROS1 repository pointing to Focal for Noetic
RUN echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros/ubuntu focal main" \
      > /etc/apt/sources.list.d/ros1-latest.list

# --- Add Ubuntu Focal repositories for additional system packages ---
RUN echo "deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse" \
      > /etc/apt/sources.list.d/ubuntu-focal.list && \
    echo "deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse" \
      >> /etc/apt/sources.list.d/ubuntu-focal.list && \
    echo "deb http://archive.ubuntu.com/ubuntu focal-security main restricted universe multiverse" \
      >> /etc/apt/sources.list.d/ubuntu-focal.list

# --- Pin ROS Noetic packages to use the Focal repository ---
# This forces packages with names starting with "ros-noetic-" to be installed from Focal.
RUN echo 'Package: ros-noetic-*' > /etc/apt/preferences.d/ros-noetic && \
    echo 'Pin: release n=focal' >> /etc/apt/preferences.d/ros-noetic && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/ros-noetic

# Update package lists after adding all repositories and pinning
RUN apt-get update

# --- Install ROS2 Humble and ROS Noetic ---
# We install the "ros-base" variant for Humble and "ros-core" for Noetic to keep the image smaller.
RUN apt-get install -y \
    ros-humble-ros-base \
    ros-noetic-ros-base \
    python3-colcon-common-extensions \
    python3-rosdep

# Initialize rosdep (needed for building packages)
RUN rosdep init && rosdep update

# --- Set up environment variables for convenience ---
ENV ROS2_SETUP=/opt/ros/humble/setup.bash
ENV ROS1_SETUP=/opt/ros/noetic/setup.bash

# --- Build the ros1_bridge ---
# Create a workspace for the bridge and clone the repository (default branch)
RUN mkdir -p /ros1_bridge_ws/src
WORKDIR /ros1_bridge_ws/src
RUN git clone https://github.com/ros2/ros1_bridge.git

# Build the bridge – we source ROS2 so that colcon picks up the ROS2 environment
WORKDIR /ros1_bridge_ws
RUN bash -c "source /opt/ros/humble/setup.bash && colcon build --cmake-force-configure"

# Automatically source the overlay when the container starts
RUN echo "source /ros1_bridge_ws/install/local_setup.bash" >> /root/.bashrc

# Set the default command to bash for interactive use
CMD ["bash"]
