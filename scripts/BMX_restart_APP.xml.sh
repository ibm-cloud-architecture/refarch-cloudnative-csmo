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
#   BMX_restart_APP.xml.sh                                                    #
#                                                                             #
#   This script will create a TWA XML Job file for submission and submit the  #
#   XML file using curl.  This script takes input from a NOI event and saves  #
#   the data temporarily in the TWA param storage.  This allows for the       #
#   variable information to be combined with data items stored already in the #
#   TWA param storage.                                                        #
#                                                                             #
#   The XML Job is created using an XML Job template with the actual command  #
#   to be executed being created within this script.                          #
#                                                                             #
#   The list the input parameters to be supplied from a NOI event:            #
#                                                                             #
#   Input Parameters:                                                         #
#     $1    BMX_API    (The Bluemix API/URL)                                  #
#     $2    BMX_ORG    (The Bluemix Organization Name)                        #
#     $3    BMX_SPACE  (The Bluemix Space Name)                               #
#     $4    BMX_APP    (The Bluemix Application Name)                         # 
#-----------------------------------------------------------------------------#
#  History:                                                                   #
#     12/1/2016  Initial Creation by Douglas Roach                            #
#-----------------------------------------------------------------------------#
#------------------------#
#    Initialization      #
#------------------------#
START_TIME=`date +%s`
SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=`basename $SCRIPT`
SCRIPT_DIR=`dirname $SCRIPT`
PATH=$PATH:$SCRIPT_DIR
USAGE="Usage: ${SCRIPT_NAME} Bluemix-API-URL Bluemix-Organization Bluemix-Space Bluemix-Application"
LOG_FILE=`/opt/IBM/RBA/bin/Log_Creation_Cleanup.sh /opt/Bluemix/Logs Bluemix_RBA 30`
PID=$$
USER=`whoami`

#---------------------#
#   function section  #
#---------------------#
function logMsg()  {
    echo -e "$(date '+%a %b %d %H:%M:%S %Y') : $1" >> $LOG_FILE
}  #logMsg

function exitScript {
    END_TIME=`date +%s`
    RUN_TIME=$((END_TIME-START_TIME))
    logMsg "$SCRIPT_NAME Bluemix took $RUN_TIME Seconds.  Return Code:$RC"
    exit $RC
}  #exitScript

function usageError {
    logMsg "$USAGE rc:99"
    RC=99
    exitScript
}  #usageError

#---------------------#
#   Input Section     #
#---------------------#
BMX_API=$1
BMX_ORG=$2
BMX_SPACE=$3
BMX_APP=$4

if [[ $# -lt 4 ]]; then
       usageError
fi

#----------------------#
#   Main Section       #
#----------------------#
#-----------------------------------------------------#
#   Add dynamic parameters from NOI to param storage  #
#-----------------------------------------------------#
TWA_param.sh ADD $PID BMX_API $BMX_API
TWA_param.sh ADD $PID BMX_ORG $BMX_ORG
TWA_param.sh ADD $PID BMX_SPACE $BMX_SPACE
TWA_param.sh ADD $PID BMX_APP $BMX_APP

#-----------------------------------------------------#
#   Set variables for processing XML template         #
#-----------------------------------------------------#
COMMAND="/opt/IBM/RBA/bin/BMX_restart_APP.sh"
VAR1="\${agent:rba.bluemix.$USER.username}"
VAR2="\${agent:rba.bluemix.$USER.password}"
VAR3="\${agent:temp.rba.$PID.BMX_API}"
VAR4="\${agent:temp.rba.$PID.BMX_ORG}"
VAR5="\${agent:temp.rba.$PID.BMX_SPACE}"
VAR6="\${agent:temp.rba.$PID.BMX_APP}"
XML_TEMPLATE=$SCRIPT_DIR/rba.xml.template
XML_OUT=/tmp/$PID.BMX_restart_APP.xml

#-----------------------------------------------------#
#   Process the XML template creating XML Job         #
#-----------------------------------------------------#
while read LINE; do
    FIRST_CHAR=`echo ${LINE:0:1}`
    LINE_DATA=`echo ${LINE:1}`
    if [[ $FIRST_CHAR == "#" ]]; then 
        echo "$LINE_DATA" >> $XML_OUT
    elif [[ $FIRST_CHAR == "$" ]]; then
        FIRST_HALF=`echo $LINE_DATA | awk -F"+" '{print $1}'`
        SECOND_HALF=`echo $LINE_DATA | awk -F"+" '{print $2}'`
        echo "$FIRST_HALF$COMMAND $VAR1 $VAR2 $VAR3 $VAR4 $VAR5 $VAR6$SECOND_HALF" >> $XML_OUT
    fi
done < $XML_TEMPLATE

#-----------------------------------------------------#
#   Setup environment for submitting the XML Job      #
#-----------------------------------------------------#
TWA_DIR=/opt/IBM/TWA_tws
PROTOCOL=https
HOST=127.0.0.1
PORT=33180
. $TWA_DIR/TWS/tws_env.sh

#-----------------------------------------------------#
#   Submit the XML Job using curl                     #
#-----------------------------------------------------#
$TWA_DIR/TWS/ITA/cpa/ita/curl --data "@$XML_OUT" --keystore $TWA_DIR/TWS/ITA/cpa/ita/cert/TWSClientKeyStore.kdb --keystash $TWA_DIR/TWS/ITA/cpa/ita/cert/TWSClientKeyStore.sth --keylabel client "$PROTOCOL://$HOST:$PORT/ita/JobManager/job" --silent --show-error  

RC=$?
logMsg "$SCRIPT_NAME : BMX_restart_App.xml:$RC"

#-----------------------------------------------------#
#   Remove the dynamic parameters in param storage    #
#-----------------------------------------------------#
TWA_param.sh FORCE_DELETE $PID BMX_API
TWA_param.sh FORCE_DELETE $PID BMX_ORG 
TWA_param.sh FORCE_DELETE $PID BMX_SPACE 
TWA_param.sh FORCE_DELETE $PID BMX_APP 

exitScript

