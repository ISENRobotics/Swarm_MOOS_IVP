#!/bin/bash 
#-------------------------------------------------------
#  Part 1: Check for and handle command-line arguments
#-------------------------------------------------------
TIME_WARP=1
JUST_MAKE="no"
COOL_FAC=50
COOL_STEPS=1000
CONCURRENT="true"
ADAPTIVE="false"

for ARGI; do
    #help:
    if [ "${ARGI}" = "--help" -o "${ARGI}" = "-h" ] ; then 
        HELP="yes"
        UNDEFINED_ARG=""	
    #time warmp
    elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 1 ]; then 
        TIME_WARP=$ARGI
    elif [ "${ARGI:0:6}" = "--warp" ] ; then
        WARP="${ARGI#--warp=*}"
        UNDEFINED_ARG=""
    elif [ "${ARGI}" = "--just_build" -o "${ARGI}" = "-j" ] ; then
	JUST_MAKE="yes"
    elif [ "${ARGI:0:6}" = "--cool" ] ; then
        COOL_FAC="${ARGI#--cool=*}"
        UNDEFINED_ARG=""
    elif [ "${ARGI:0:5}" = "--key" ] ; then
        KEY="${ARGI#--key=*}"
        UNDEFINED_ARG=""

    elif [ "${ARGI}" = "--adaptive" -o "${ARGI}" = "-a" ] ; then
        ADAPTIVE="true"
        UNDEFINED_ARG=""
    elif [ "${ARGI}" = "--unconcurrent" -o "${ARGI}" = "-uc" ] ; then
        CONCURRENT="false"
        UNDEFINED_ARG=""
    else 
	printf "Bad Argument: %s \n" $ARGI
	exit 0
    fi
done
if [ "${HELP}" = "yes" ]; then
    printf "%s [SWITCHES]            \n" $0
    printf "Switches:                \n"
    printf "  --warp=WARP_VALUE      \n"
    printf "  --adaptive, -a         \n"
    printf "  --unconcurrent, -uc       \n"
    printf "  --cool=COOL_FAC        \n"
    printf "  --just_build, -j       \n"
    printf "  --help, -h             \n"
    exit 0;
fi
#-------------------------------------------------------
#  Part 2: Create the .moos and .bhv files. 
#-------------------------------------------------------

VNAME1="AUV1"
VNAME2="AUV2"
VNAME3="AUV3"
TYPE="AUV"

SHORESIDE_POS="0,0"

START_POS1="0,-30"
START_POS2="0,-180"
START_POS3="120,-30"

STOP_POS1="0,-180"
STOP_POS2="0,-30"
STOP_POS3="120,-180"

OBSTACLE_POS="{110,-60:110,-70:130,-70:130,-60}"

nsplug meta_shoreside.moos targ_shoreside.moos -f WARP=$TIME_WARP \
   VNAME="shoreside" SHARE_LISTEN=$SHORE_LISTEN

#start first vehicle:
nsplug meta_vehicle.moos targ_$VNAME1.moos -f WARP=$TIME_WARP  \
   VNAME=$VNAME1      START_POS=$START_POS1                    \
   VPORT="9001"       SHARE_LISTEN="9301"                      \
   VTYPE=$TYPE          COOL_FAC=$COOL_FAC  COOL_STEPS=$COOL_STEPS\
   CONCURRENT=$CONCURRENT  ADAPTIVE=$ADAPTIVE

nsplug meta_vehicle.bhv targ_$VNAME1.bhv -f VNAME=$VNAME1      \
    START_POS=$START_POS1 STOP_POS=$STOP_POS1 OBSTACLE_POS=$OBSTACLE_POS SHORESIDE_POS=$SHORESIDE_POS  

#start second vehicle:                                                                                                   
nsplug meta_vehicle.moos targ_$VNAME2.moos -f WARP=$TIME_WARP  \
   VNAME=$VNAME2      START_POS=$START_POS2                   \
   VPORT="9002"       SHARE_LISTEN="9302"                      \
   VTYPE=$TYPE          COOL_FAC=$COOL_FAC  COOL_STEPS=$COOL_STEPS\
   CONCURRENT=$CONCURRENT  ADAPTIVE=$ADAPTIVE

nsplug meta_vehicle.bhv targ_$VNAME2.bhv -f VNAME=$VNAME2      \
    START_POS=$START_POS2 STOP_POS=$STOP_POS2 OBSTACLE_POS=$OBSTACLE_POS SHORESIDE_POS=$SHORESIDE_POS

#start third vehicle:                                                                                                   
nsplug meta_vehicle.moos targ_$VNAME3.moos -f WARP=$TIME_WARP  \
   VNAME=$VNAME3      START_POS=$START_POS3                   \
   VPORT="9003"       SHARE_LISTEN="9303"                      \
   VTYPE=$TYPE          COOL_FAC=$COOL_FAC  COOL_STEPS=$COOL_STEPS\
   CONCURRENT=$CONCURRENT  ADAPTIVE=$ADAPTIVE

nsplug meta_vehicle.bhv targ_$VNAME3.bhv -f VNAME=$VNAME3      \
    START_POS=$START_POS3 STOP_POS=$STOP_POS3 OBSTACLE_POS=$OBSTACLE_POS SHORESIDE_POS=$SHORESIDE_POS


if [ ${JUST_MAKE} = "yes" ] ; then
    exit 0
fi

#-------------------------------------------------------
#  Part 3: Launch the processes
#-------------------------------------------------------
printf "Launching $VNAME1 MOOS Community (WARP=%s) \n" $TIME_WARP
pAntler targ_$VNAME1.moos >& /dev/null &
sleep .25
printf "Launching $VNAME2 MOOS Community (WARP=%s) \n" $TIME_WARP
pAntler targ_$VNAME2.moos >& /dev/null &
sleep .25
printf "Launching $VNAME3 MOOS Community (WARP=%s) \n" $TIME_WARP
pAntler targ_$VNAME3.moos >& /dev/null &
sleep .25
printf "Launching $SNAME MOOS Community (WARP=%s) \n"  $TIME_WARP
pAntler targ_shoreside.moos >& /dev/null &
printf "Done \n"

uMAC targ_shoreside.moos

printf "Killing all processes ... \n"
kill %1 %2 %3 %4
printf "Done killing processes.   \n"


