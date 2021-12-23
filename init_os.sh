#!/usr/bin/env bash
###########################################################
yum update -y && yum upgrade -y && \
###########################################################
# Restricting a Package to a Fixed Version Number with yum
# Use the yum versionlock plugin to lock a package or 
# packages to currently installed version. The plugin stores 
# a package list in `/etc/yum/pluginconf.d/versionlock.list, 
# which you can edit directly. Yum will normally attempt to 
# update all packages, but the plugin will exclude the packages 
# listed in the versionlock.list file.
yum install yum-plugin-versionlock -y && \
###########################################################