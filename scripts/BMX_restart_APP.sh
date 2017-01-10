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
#   BMX_restart_APP.sh                                                        #
#                                                                             #
#   This script uses Cloud Foundry commands to log onto the supplied Bluemix  #
#   API/URL, Organization, and Space using the supplied Username & Password.  #
#   Then the script issues a restart against the supplied Bluemix Application #
#                                                                             #
#   This script requires the six Input Parameters which are explained below.  #
#                                                                             #
#   Input Parameters:                                                         #
#     $1    BMX_USER      (Bluemix User ID)                                   #
#     $2    BMX_PASSWORD  (Bluemix Users Password)                            #
#     $3    BMX_API       (Bluemix API/URL)                                   #
#     $4    BMX_ORG       (Bluemix Organization Name)                         #
#     $5    BMX_SPACE     (Bluemix Space Name)                                #
#     $6    BMX_APP       (Bluemix Application Name)                          #
#-----------------------------------------------------------------------------#
#  History:                                                                   #
#     12/1/2016  Initial Creation by Douglas Roach                            #
#-----------------------------------------------------------------------------#
#------------------------------------------------------------------#
#    Initialize Variables                                          #
#------------------------------------------------------------------#
START_TIME=`date +%s`
SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=`basename $SCRIPT`
SCRIPT_DIR=`dirname $SCRIPT`
PATH=$PATH:$SCRIPT_DIR
USAGE="Usage: ${SCRIPT_NAME} Bluemix_Username Bluemix_Password Bluemix_API_URL Bluemix_Organization Bluemix_Space Bluemix_Application"
LOG_FILE=`Log_Creation_Cleanup.sh /opt/Bluemix/Logs Bluemix_RBA 30`

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
#BMX_USER=$1
#BMX_PASSWORD=$2
BMX_API=$3
BMX_ORG=$4
BMX_SPACE=$5
BMX_APP=$6

if [[ $# -lt 6 ]]; then
	usageError
fi

#---------------------#
#   Main Section      #
#---------------------#
#---------------------------------------#
#   Log on to Cloud Foundry             #
#---------------------------------------#
cf login -a $BMX_API -u $1 -p $2 -o $BMX_ORG -s $BMX_SPACE &>>$LOG_FILE
RC=$?
if [[ $RC -ne 0 ]]; then
	logMsg "$SCRIPT_NAME Logon to Bluemix using Cloud Foundry failed RC:$RC Bluemix API:$BM_API"
	logMsg "$SCRIPT_NAME Bluemix User:$BMX_USER Bluemix Org:$BMX_ORG Bluemix Space:$BMX_SPACE"
	exitScript
fi

#------------------------------------------#
#   Issue restart for Bluemix Application  #
#------------------------------------------#
cf restart $BMX_APP &>>$LOG_FILE
RC=$?
if [[ $RC -ne 0 ]]; then
	logMsg "$SCRIPT_NAME Cloud Foundry restart Application failed RC:$RC Bluemix App:$BMX_APP"
	exitScript
fi

RC=0
exitScript

