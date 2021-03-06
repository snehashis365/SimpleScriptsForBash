#!/bin/bash
#Declaring required variables
LGREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NORMAL='\033[0m'
DEL_LINE='\033[2K' #Escape sequence to delete the content of the line
BEEP='' #Alarm off by default
NOTIFY='' #Notify on reply off by default
DEFAULT_IP_FLAG=true
NO_REPLY=false #To help handle connection status change
DOT_COUNT=0
IP='8.8.8.8' #Default IP to be tested
DELAY=1
#Function to handle Ctrl+C
function endScript ()
{
	#Handle Clean up here | Plans are to show a summary at script exit | Exit message added
	echo -e "\nDetected Control Break\nExiting....."
	echo -e "***************************************************"
	exit 2
}

#Function to convert seconds to more understandable time format
function formatTime () 
{
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        let "sec=num%60"
        let "num=num/60"
        if((num>59));then
            let "min=num%60"
            let "num=num/60"
            let "hour=num"
			echo -e "$hour hour(s), $min minute(s) and $sec second(s)\n"
        else
            let "min=num"
			echo -e "$min minute(s) and $sec second(s)\n"
        fi
    else
        let "sec=num"
		echo -e "$sec second(s)\n"
    fi
}

#Function to show help message
function help ()
{
	echo "This script will check ping with provided IP/domain/Default Google DNS and show the connection status"
   echo
   echo "Syntax: ./pingChecker.sh [-h|a|t <SECONDS>]"
   echo "options:"
   echo "h     Print this Help."
   echo "n	   Notify on reply"
   echo "a     Turn alarm On when there is no reply."
   #echo "v     Verbose mode."
   echo "t     Set the life time of every ping."
   echo
}

#Function to check ping reply and show status
function checkPing ()
{
	if [ $# -gt 0 ]
	then
		IP=$1
		DEFAULT_IP_FLAG=false
	fi
	if [ "$DEFAULT_IP_FLAG" = true ]
	then
		echo "Checking default Google DNS"
	fi	
	echo -e "${BLUE}Pinging${NORMAL}.....${LGREEN}${IP}${NORMAL}\n"
	while((1)) #The script runs infinitely unless control break(Ctrl+c) occurs
	do
		OUTPUT=$(ping -w ${DELAY} ${IP} | grep "Destination Host Unreachable\|100% packet loss")
		if test -z "$OUTPUT"
		then
			if [ "$NO_REPLY" = true ]
			then
				echo -ne "\n${BLUE}Connection Restored!${NORMAL}"
				NO_REPLY=false
				DOT_COUNT=0
				
				echo -ne "\nApprox ${RED}down${NORMAL} time: ${LGREEN}"
				formatTime $SECONDS #Convert the seconds to easy to understand time format
			fi
			if [ $DOT_COUNT -gt 0 -a $DOT_COUNT -le 5 ] #To avoid flooding with '.'
			then
				echo -ne "."
			else
				echo -ne "${DEL_LINE}\r${LGREEN}Connection OK${NORMAL}${NOTIFY}"
				DOT_COUNT=0
			fi
			let "DOT_COUNT=DOT_COUNT+1" 
			#Increment the counter
		else
			if [ "$NO_REPLY" = false ]
			then
				echo -e "\n${BLUE}Connection Lost!${NORMAL}\n"
				NO_REPLY=true
				SECONDS=0
				DOT_COUNT=0
			fi
			if [ $DOT_COUNT -gt 0 -a $DOT_COUNT -le 5 ]
			then
				echo -ne ".${BEEP}"
			else
				echo -ne "${DEL_LINE}\r${RED}No Reply${NORMAL}${BEEP}"
				DOT_COUNT=0
			fi
			let "DOT_COUNT=DOT_COUNT+1"
		fi
	done

}

#Setting trap to call endScript function with SIGINT(2)
trap "endScript" 2
#This script will check ping with provided IP/domain/Default Google DNS and show the connection status
#Updated every 1s by default| Options and option argument handling added still a prorotype

#Options and options arguments handling:-
while getopts ":hnat:" opt; do
	case ${opt} in
		h ) #Display Help message
			help
			exit 2
			;;
		n ) #Turn on Notify on reply
			NOTIFY='\007'
			;;
		a ) #Turn on the alarm on no reply
			if [[ "$NOTIFY" == '\007' ]]
			then
				echo -e "${RED}Notify on Reply and Alarm are on at the same time${NORMAL}\nThis will cause constant beeping no matter the connection state"
				while true; do
					echo -ne "${BLUE}Do you want to continue anyway? ${NORMAL}"
					read yn
					case $yn in
						[Yy]* )
							BEEP='\007'
							break
							;;
						[Nn]* ) 
							exit 2
							;;
						* ) echo "Please answer [Y/y/yes] or [N/n/no]";;
					esac
				done
			else
				BEEP='\007'
			fi
			;;
		t ) #Manually set duration
			if [[ "$OPTARG" == *"."* ]]
			then
				echo -e "${RED}Invalid option:${NORMAL} '$OPTARG' is not an INTEGER" 1>&2
				exit 2
			else
				DELAY=$OPTARG
			fi
			;;
		\? )
			echo "Invalid option: $OPTARG" 1>&2
			exit 2
			;;
		: ) 
			echo -e "${RED}Invalid option:${NORMAL} -$OPTARG requires an argument <INTEGER>"
			exit 2
      		;;
	esac
done
shift $((OPTIND -1))

#Main script logic here on
echo -e "******${LGREEN}Connection Status ${BLUE}notifier${NORMAL} by ${LGREEN}Snehashis${NORMAL}******"
echo -e "${BLUE}Duration: ${RED}${DELAY}s"
echo -ne "${BLUE}Notify: "
if test -z "$NOTIFY"
then
	echo -e "${LGREEN}Off"
else
	echo -e "${RED}On"
fi
echo -ne "${BLUE}Alarm: "
if test -z "$BEEP"
then
	echo -e "${LGREEN}Off"
else
	echo -e "${RED}On"
fi
echo -ne "${NORMAL}"
#Calling function with given argument to check ping
#The idea to check multiple IP at once will be handled here by calling the function as many times needed
#while [[ $# -gt 0 ]]
#do
	checkPing $1
#	shift
#done
#The layout is written in comment line for now will keep working