#!/bin/bash
# IBM_PROLOG_BEGIN_TAG 
# This is an automatically generated prolog. 
#  
# Licensed Materials - Property of IBM 
#  
# (C) COPYRIGHT International Business Machines Corp. 2011,2012 
# All Rights Reserved 
#  
# US Government Users Restricted Rights - Use, duplication or 
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp. 
#  
# IBM_PROLOG_END_TAG 
#-----------------------------------------------------------------------------#
#   Log_Creation_Cleanup.sh                                                   #
#                                                                             #
#   This script will create a Daily Log File to be used to log activity       #
#   required by the calling App.  It will create the Log Directory if it      #
#   does not exist.  It will also remove old log files older than the         #
#   specified number of days to keep the log file.  This script requires      #
#   three Input Parameters which are explained below.                         #
#                                                                             #
#   Input Parameters:                                                         #
#      $1    DIR    (Directory Location for Log File)                         #
#      $2    LOG    (Name for the Log File)                                   #
#      $3    DAYS   (Number of Days to keep Log Files)                        #
#-----------------------------------------------------------------------------#
#  History:                                                                   #
#     12/1/2016  Initial Creation by Douglas Roach                            #
#-----------------------------------------------------------------------------#

#------------------------------------------------------------------#
#    Initialize Variables                                          #
#------------------------------------------------------------------#
SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=`basename $SCRIPT`
SCRIPT_DIR=`dirname $SCRIPT`
PATH=$PATH:$SCRIPT_DIR
USAGE="Usage: ${SCRIPT_NAME} Log-Directory Log-Name number-of-days"
umask 0111

case $# in
    2|3) :  ;;
    *) echo ${USAGE} 
       logger -i -t $SCRIPT_NAME "Bad Usage returning: 99"
       exit 99 ;;
esac

DIR=$1
LOG=$2
DAYS=${3:-30}

#------------------------------------------------------------------#
#    Check if log directory exists, if not create directory        #
#------------------------------------------------------------------#
DIR_CK=`ls -1 $DIR 2>/dev/null | wc -l`
if [ $DIR_CK -lt 1 ]; then
    Levels=`echo $DIR | awk -F/ '{ l += NF -1 } END { print l }'`
    Directory=`echo $DIR | awk '{print substr($1,2)}'`
    CDIR=""
    cd / 
    while [ $Levels -gt 0 ]; do
        MKDIR=`echo $Directory | awk -F"/" -v var=$1 '{print $1}'`
        if [ ! -d $MKDIR ]; then
            logger -i -t $SCRIPT_NAME "Creating Directory ($MKDIR) in ($CDIR) for Log File"
            mkdir $MKDIR
            chmod 777 $MKDIR
        fi
        CDIR=$CDIR"/"$MKDIR
        Startpos=$((`echo ${#MKDIR}`+2))
        Directory=`echo $Directory | awk -v "s=$Startpos" '{print substr($1,s)}'`
        Levels=$(($Levels-1))
        cd $CDIR
    done
fi

#------------------------------------------------------------------#
#    Set log file name and send the name back to caller            #
#------------------------------------------------------------------#
LOGFILE=$DIR/$LOG`echo "_"$(date +%m.%d.%Y)`.log
echo $LOGFILE

#------------------------------------------------------------------#
#    Write log message to log file & set permissions for new log   #
#------------------------------------------------------------------#
if [ -f $LOGFILE ]; then 
    echo "$(date '+%a %b %d %H:%M:%S %Y') : `printf '=%.0s' {1..80}`" >> $LOGFILE
else
    echo "$(date '+%a %b %d %H:%M:%S %Y') : $LOGFILE created on $(date +%m.%d.%Y) at $(date +%H:%M:%S)" > $LOGFILE
    echo "$(date '+%a %b %d %H:%M:%S %Y') : `printf '=%.0s' {1..80}`" >> $LOGFILE
    chmod 666 $LOGFILE
fi

#------------------------------------------------------------------#
#    Cleanup old log files based upon number of days to keep logs  #
#------------------------------------------------------------------#
find $DIR -name "*.log" -mtime +$DAYS -type f | xargs rm -f

exit 0 

