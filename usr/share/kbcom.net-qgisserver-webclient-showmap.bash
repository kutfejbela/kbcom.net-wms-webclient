#!/bin/bash

SHELL_GET_ID=$(shell_get_value "id")
SHELL_GET_GID=$(shell_get_value "gid")
GLOBAL_STRING_GEOMARRAY=""

if [ ! -z "$SHELL_GET_ID" ]
then
 GLOBAL_STRING_GEOMARRAY=$(get_geomarray_featureid "$SHELL_GET_ID")
fi

if [ ! -z "$SHELL_GET_GID" ]
then
 GLOBAL_STRING_GEOMARRAY=$(get_geomarray_featuregroupid "$SHELL_GET_GID")
fi

if [ ! -z "$GLOBAL_STRING_GEOMARRAY" ]
then
 IFS=' '
 GLOBAL_ARRAY_MAPBOX=( $(convert_mapbox_geomarray "$GLOBAL_STRING_GEOMARRAY") )

 if [ -z "${GLOBAL_ARRAY_MAPBOX[*]}" ]
 then
  SHELL_GET_ID=""
 else
  GLOBAL_CENTERX="${GLOBAL_ARRAY_MAPBOX[0]}"
  GLOBAL_CENTERY="${GLOBAL_ARRAY_MAPBOX[1]}"
  GLOBAL_ZOOMLEVEL="${GLOBAL_ARRAY_MAPBOX[2]}"
 fi
fi

if [ -z "$SHELL_GET_ID" ]
then
 GLOBAL_CENTERX="$CONFIG_WMS_BBOX_DEFAULTCENTERX"
 GLOBAL_CENTERY="$CONFIG_WMS_BBOX_DEFAULTCENTERY"
 GLOBAL_ZOOMLEVEL="$CONFIG_WMS_ZOOMLEVEL_DEFAULT"
fi


echo "<img id='wms_mapimg' draggable='false' width='${CONFIG_WMS_MAPIMAGE_WIDTH}' height='${CONFIG_WMS_MAPIMAGE_HEIGHT}' style='margin: 0; padding: 0; float: left; user-select: none; -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none;' ondragstart='return false;' onwheel='wms_mapimg_onwheel(this, event); return false;' onmousedown='wms_mapimg_onmousedown(this, event);' onmouseup='wms_mapimg_onmouseup(this, event);' onmouseleave='wms_mapimg_onmouseleave(this, event);' onload='wms_mapimg_onload();'><br>"

echo "<input id='button_wms_zoomin' type='button' value=' + ' onclick='wms_zoomin();'><br>"
echo "<input id='button_wms_zoomout' type='button' value=' - ' onclick='wms_zoomout();'><br>"

echo "<input id='button_wms_moveup' type='button' value=' ^ ' onclick='wms_movedown();'>"
echo "<input id='button_wms_movedown' type='button' value=' v ' onclick='wms_moveup();'><br>"
echo "<input id='button_wms_moveleft' type='button' value=' < ' onclick='wms_moveleft();'>"
echo "<input id='button_wms_moveright' type='button' value=' > ' onclick='wms_moveright();'>"

echo "<textarea id='wms_mapimgurl' style='width: 100px; height: 200px;'></textarea>"

echo "<script>
document.getElementById('wms_mapimg').addEventListener('wheel', function(){
 wms_mapimg_onwheel(this, event);
 event.preventDefault();
});

var global_minx=$CONFIG_WMS_BBOX_MINX;
var global_maxx=$CONFIG_WMS_BBOX_MAXX;
var global_miny=$CONFIG_WMS_BBOX_MINY;
var global_maxy=$CONFIG_WMS_BBOX_MAXY;

var global_width=global_maxx-global_minx;
var global_height=global_maxy-global_miny;
var global_zoomlevel_stepsquare=Math.pow($CONFIG_WMS_ZOOMLEVEL_STEP, 2);

var global_move_percentage=$CONFIG_WMS_MOVEPERCENTAGE/100;
var global_movex=0
var global_movey=0

var global_centerx_min=0;
var global_centerx_max=0;
var global_centery_min=0;
var global_centery_max=0;

var global_centerx=$GLOBAL_CENTERX;
var global_centery=$GLOBAL_CENTERY;
var global_zoomlevel=$GLOBAL_ZOOMLEVEL;
var global_zoomlevel_min=$CONFIG_WMS_ZOOMLEVEL_MIN;
var global_zoomlevel_max=$CONFIG_WMS_ZOOMLEVEL_MAX;

var global_zoom_widthrate=0;
var global_zoom_heightrate=0;
var global_zoom_centerx=0;
var global_zoom_centery=0;

var global_block_zoompan=false;

var global_drag_startx=0;
var global_drag_starty=0;
var global_is_dragdrop=false;
var global_drag_interval;

calculate_zoom();
wms_showmap();

function wms_showmap()
{
 global_block_zoompan=true;

 if ( global_zoomlevel_max <= global_zoomlevel )
 {
  document.getElementById('button_wms_zoomin').disabled=1;
  global_zoomlevel=global_zoomlevel_max;
 }
 else
 {
  document.getElementById('button_wms_zoomin').disabled=0;
 }

 if ( global_zoomlevel <= global_zoomlevel_min )
 {
  document.getElementById('button_wms_zoomout').disabled=1;
  global_zoomlevel=global_zoomlevel_min;
 }
 else
 {
  document.getElementById('button_wms_zoomout').disabled=0;
 }

 if ( global_zoom_centerx <= global_centerx_min )
 {
  document.getElementById('button_wms_moveleft').disabled=1;
 }
 else
 {
  document.getElementById('button_wms_moveleft').disabled=0;
 }

 if ( global_centerx_max <= global_zoom_centerx )
 {
  document.getElementById('button_wms_moveright').disabled=1;
  global_zoom_centerx=global_centerx_max;
 }
 else
 {
  document.getElementById('button_wms_moveright').disabled=0;
 }

 if ( global_zoom_centery <= global_centery_min )
 {
  document.getElementById('button_wms_movedown').disabled=1;
  global_zoom_centery=global_centery_min;
 }
 else
 {
  document.getElementById('button_wms_movedown').disabled=0;
 }

 if ( global_centery_max <= global_zoom_centery )
 {
  document.getElementById('button_wms_moveup').disabled=1;
  global_zoom_centery=global_centery_max;
 }
 else
 {
  document.getElementById('button_wms_moveup').disabled=0;
 }

 document.getElementById('wms_mapimg').src='$GLOBAL_URL?type=wmsimage&zoomlevel=' + global_zoomlevel + '&centerx=' + global_zoom_centerx + '&centery=' + global_zoom_centery;
}

function calculate_zoom()
{
 global_zoom_widthrate=Math.pow(global_zoomlevel, 2)*global_zoomlevel_stepsquare;
 global_zoom_heightrate=Math.pow(global_zoomlevel, 2)*global_zoomlevel_stepsquare;

 if ( global_zoom_widthrate <= 1 )
 {
  global_movex=0;
  global_zoom_centerx=global_minx + Math.floor((global_maxx-global_minx)/2);
  global_centerx_min=global_zoom_centerx;
  global_centerx_max=global_zoom_centerx;
 }
 else
 {
  global_zoom_centerx=global_centerx;
  global_movex=Math.floor(global_move_percentage*(global_width/global_zoom_widthrate));
  global_centerx_min=global_minx+global_movex;
  global_centerx_max=global_maxx-global_movex;
 }

 if ( global_zoom_heightrate <= 1 )
 {
  global_movey=0;
  global_zoom_centery=global_miny + Math.floor((global_maxy-global_miny)/2);
  global_centery_min=global_zoom_centery;
  global_centery_max=global_zoom_centery;
 }
 else
 {
  global_zoom_centery=global_centery;
  global_movey=Math.floor(global_move_percentage*(global_height/global_zoom_heightrate));
  global_centery_min=global_miny+global_movey;
  global_centery_max=global_maxy-global_movey;
 }
}

function wms_hideflowframes()
{
 parent.document.getElementById('map_maptip').style.visibility=\"hidden\";
 parent.document.getElementById('map_maptip').width=0;
 parent.document.getElementById('map_maptip').height=0;
 parent.document.getElementById('searchresult_container').style.visibility=\"hidden\";
 parent.document.getElementById('searchresult_container').width=0;
 parent.document.getElementById('searchresult_container').height=0;
}

function wms_mapimg_click(object, event)
{
 var imgX = event.clientX - Math.floor(object.getBoundingClientRect().left);
 var imgY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop - Math.floor(object.getBoundingClientRect().top);
 var clickX = event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft + Math.floor(parent.document.getElementById('map').getBoundingClientRect().left);
 var clickY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop + parent.document.documentElement.scrollTop + Math.floor(parent.document.getElementById('map').getBoundingClientRect().top);

 wms_hideflowframes();

 // if ( imgX < ${CONFIG_WMS_MAPIMAGE_WIDTH} ) ${CONFIG_WMS_MAPIMAGE_HEIGHT}
 parent.document.getElementById('map_maptip').style.left=clickX;
 parent.document.getElementById('map_maptip').style.top=clickY;
 parent.document.getElementById('map_maptip').style.width=0;
 parent.document.getElementById('map_maptip').style.height=0;
 parent.document.getElementById('map_maptip').src='$GLOBAL_URL?type=wmsmaptip&zoomlevel=' + global_zoomlevel + '&centerx=' + global_centerx + '&centery=' + global_centery + '&x=' + imgX + '&y=' + imgY;
 document.getElementById('wms_mapimgurl').value='$GLOBAL_URL?type=wmsmaptip&zoomlevel=' + global_zoomlevel + '&centerx=' + global_centerx + '&centery=' + global_centery + '&x=' + imgX + '&y=' + imgY;
}

function wms_mapimg_onwheel(object, event)
{
 var local_wheeldelta;

 if (global_block_zoompan)
 {
  return;
 }

 if ( event.wheelDelta )
 {
  local_wheeldata=event.wheelDelta;
 }
 else
 {
  local_wheeldata=-event.deltaY;
 }

 if ( local_wheeldata >= 0 )
 {
 if ( global_zoomlevel_max <= global_zoomlevel )
  {
   return;
  }
 }
 else
 {
 if ( global_zoomlevel <= global_zoomlevel_min )
  {
   return;
  }
 }

 var imgX = event.clientX - Math.floor(object.getBoundingClientRect().left);
 var imgY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop - Math.floor(object.getBoundingClientRect().top);

 global_centerx=global_zoom_centerx + Math.floor((global_width/($CONFIG_WMS_MAPIMAGE_WIDTH*global_zoom_widthrate))*(imgX-($CONFIG_WMS_MAPIMAGE_WIDTH/2)));
 global_centery=global_zoom_centery - Math.floor((global_height/($CONFIG_WMS_MAPIMAGE_HEIGHT*global_zoom_heightrate))*(imgY-($CONFIG_WMS_MAPIMAGE_HEIGHT/2)));

 if ( local_wheeldata >= 0 )
 {
  wms_zoomin();
 }
 else
 {
  wms_zoomout();
 }
}

function wms_mapimg_onmousedown(object, event)
{
 if (global_block_zoompan)
 {
  return;
 }

 wms_hideflowframes();

 global_drag_startx=event.clientX;
 global_drag_starty=event.clientY;
 global_is_dragdrop=true;

// var e = window.event;
// var local_x = e.clientX;
// var local_y = e.clientY;
// global_drag_interval=setIntreval(wms_drag_showmap, 1000);
}

function wms_mapimg_onmouseup(object, event)
{
 if (global_block_zoompan)
 {
  return;
 }

 global_is_dragdrop=false;

 var local_deltaX=event.clientX-global_drag_startx;
 var local_deltaY=event.clientY-global_drag_starty;

 if (local_deltaX == 0 && local_deltaY == 0)
 {
  wms_mapimg_click(object, event);
  return;
 }

 global_zoom_centerx=global_centerx-Math.floor((local_deltaX/${CONFIG_WMS_MAPIMAGE_WIDTH})*(global_width/global_zoom_widthrate));
 global_zoom_centery=global_centery+Math.floor((local_deltaY/${CONFIG_WMS_MAPIMAGE_HEIGHT})*(global_height/global_zoom_heightrate));

 wms_movecenter();
 wms_showmap();
}

function wms_mapimg_onmouseleave(object, event)
{
 if (global_block_zoompan)
 {
  return;
 }

 if ( ! global_is_dragdrop )
 {
  return false;
 }

 global_is_dragdrop=false;

 var local_deltaX=event.clientX-global_drag_startx;
 var local_deltaY=event.clientY-global_drag_starty;

 global_zoom_centerx=global_centerx-Math.floor((local_deltaX/${CONFIG_WMS_MAPIMAGE_WIDTH})*(global_width/global_zoom_widthrate));
 global_zoom_centery=global_centery+Math.floor((local_deltaY/${CONFIG_WMS_MAPIMAGE_HEIGHT})*(global_height/global_zoom_heightrate));

 wms_movecenter();
 wms_showmap();
}

function wms_mapimg_onload()
{
 global_block_zoompan=false;
 wms_hideflowframes();
}

function wms_zoomin()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoomlevel++;

 calculate_zoom();
 wms_showmap();
}

function wms_zoomout()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoomlevel--;

 calculate_zoom();
 wms_showmap();
}

function wms_movecenter()
{
 if ( global_zoom_centery <= global_centery_min )
 {
  global_centery=global_centery_min;
 }
 else
 {
  global_centery=global_zoom_centery;
 }

 if ( global_centery_max <= global_zoom_centery )
 {
  global_centery=global_centery_max;
 }
 else
 {
  global_centery=global_zoom_centery;
 }

 if ( global_zoom_centerx <= global_centerx_min )
 {
  global_centerx=global_centerx_min;
 }
 else
 {
  global_centerx=global_zoom_centerx;
 }

 if ( global_centerx_max <= global_zoom_centerx )
 {
  global_centerx=global_centery_max;
 }
 else
 {
  global_centerx=global_zoom_centerx;
 }
}

function wms_moveup()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoom_centery-=global_movey;
 wms_movecenter();

 wms_showmap();
}

function wms_movedown()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoom_centery+=global_movey;
 wms_movecenter();

 wms_showmap();
}

function wms_moveleft()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoom_centerx-=global_movex;
 wms_movecenter();

 wms_showmap();
}

function wms_moveright()
{
 if (global_block_zoompan)
 {
  return;
 }

 global_zoom_centerx+=global_movex;
 wms_movecenter();

 wms_showmap();
}

</script>"
