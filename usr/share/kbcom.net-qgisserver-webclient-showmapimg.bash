#!/bin/bash

SHELL_GET_CENTERX=$(shell_get_value "centerx")
SHELL_GET_CENTERY=$(shell_get_value "centery")
SHELL_GET_ZOOMLEVEL=$(shell_get_value "zoomlevel")

SHELL_GET_CENTERX=$(check_value_integer "$SHELL_GET_CENTERX" "$CONFIG_WMS_BBOX_MINX" "$CONFIG_WMS_BBOX_MAXX" "$CONFIG_WMS_BBOX_DEFAULTCENTERX")
SHELL_GET_CENTERY=$(check_value_integer "$SHELL_GET_CENTERY" "$CONFIG_WMS_BBOX_MINY" "$CONFIG_WMS_BBOX_MAXY" "$CONFIG_WMS_BBOX_DEFAULTCENTERY")
SHELL_GET_ZOOMLEVEL=$(check_value_integer "$SHELL_GET_ZOOMLEVEL" "$CONFIG_WMS_ZOOMLEVEL_MIN" "$CONFIG_WMS_ZOOMLEVEL_MAX" "$CONFIG_WMS_ZOOMLEVEL_DEFAULT")

LOCAL_BBOX=$(calculate_bbox "$SHELL_GET_ZOOMLEVEL" "$SHELL_GET_CENTERX" "$SHELL_GET_CENTERY")
download_image_wms "$LOCAL_BBOX"
