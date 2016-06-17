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

VNAME="robot"
TYPE="AUV"
let "NB_ROBOT = 5"
      
START_POS="0,0" 

nsplug meta_shoreside.moos targ_shoreside.moos -f WARP=$TIME_WARP \
   VNAME="shoreside" SHARE_LISTEN=$SHORE_LISTEN

for i in `seq 1 $NB_ROBOT`; do

	let "pair_impair = i % 2"

	if [ $pair_impair = "0" ] ; 

		then
			let "positionX = i * 15"
			MOTIF_POS="$positionX,-70"
		
	    	else

			let "positionX = i * 15"
			MOTIF_POS="$positionX,-60"    
	fi
	
    nsplug meta_vehicle.moos targ_$VNAME$i.moos -f WARP=$TIME_WARP \
    VNAME=$VNAME$i      START_POS=$START_POS                  \
    VPORT="900"$i       SHARE_LISTEN="930"$i                  \
    VTYPE=$TYPE      COOL_FAC=$COOL_FAC  COOL_STEPS=$COOL_STEPS\
    CONCURRENT=$CONCURRENT  ADAPTIVE=$ADAPTIVE

     nsplug meta_vehicle.bhv targ_$VNAME$i.bhv -f VNAME=$VNAME$i     \
    START_POS=$START_POS MOTIF_POS=$MOTIF_POS  
   

done 

if [ ${JUST_MAKE} = "yes" ] ; then
    exit 0
fi

#-------------------------------------------------------
#  Part 3: Launch the processes
#-------------------------------------------------------

for i in `seq 1 $NB_ROBOT`; do
	
	printf "Launching $VNAME$i MOOS Community (WARP=%s) \n" $TIME_WARP
	pAntler targ_$VNAME$i.moos >& /dev/null &
	sleep .25
done

printf "Launching $SNAME MOOS Community (WARP=%s) \n"  $TIME_WARP
pAntler targ_shoreside.moos >& /dev/null &
printf "Done \n"

#-----------------------------------------------------------
#  Part 4: Launch uMAC and kill everything upon exiting uMAC
#-----------------------------------------------------------

uMAC targ_shoreside.moos

printf "Killing all processes ... \n"
let "shoreside = 1"
let "condition_arret = shoreside + NB_ROBOT"

for i in `seq 1 $condition_arret`; do
	kill %$i
done 

printf "Done killing processes.   \n"


