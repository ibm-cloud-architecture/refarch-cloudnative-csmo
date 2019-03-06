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
#--------------------------------------------------------------------------------#
#   TWA_param.sh                                                                 #
#                                                                                #
#   This script will add or delete dynamic variables stored in TWA's param       #
#   storage.  The inputs include what Function, PID, ITEM, and DATA each of are  #
#   are described below.  The available Functions are:                           #
#       ADD           which adds the variable in plain text to the param storage #
#       ADD_ENCRYPT   which adds the variable with the contents encrypted in the #
#                     param storage                                              #
#       DELETE        which will delete/remove the variable if the input is      #
#                     confirmed via a prompt  (Not recommended)                  #
#       FORCE_DELETE  which will delete/remove the variable without any          #
#                     confirmation                                               #
#                                                                                #
#   The param files default directory is                                         #
#       /opt/IBM/TWA_tws/TWS/ITA/cpa/config/jm_variables_files                   #
#                                                                                #
#   The variable name is comprised of the following:                             #
#       temp   This is a hard coded place holder for the param file name         # 
#       rba    This is a hard coded place holder for the application name        #
#       PID    This is a variable name that is passed to this script, usually    #
#              this is the PID number to keep uniqueness                         #
#       ITEM   This is a variable name that is passed to this script, usually    #
#              a descriptive name                                                #
#                                                                                # 
#   This script requires 3 parameters for delete and 4 for add functions.  The   #
#   Input Parameters which are explained below:                                  #
#                                                                                #
#   Input Parameters:                                                            #
#      $1    FUNCTION  (Function to be performed they are listed above           #
#      $2    PID       (Process Id of the process calling this script)           #
#      $3    ITEM      (Short description of variable)                           #
#      $4    DATA      (Data to be stored in the variable)                       #
#--------------------------------------------------------------------------------#
#  History:                                                                      #
#     12/1/2016  Initial Creation by Douglas Roach                               #
#--------------------------------------------------------------------------------#

#---------------------#
#   Initialization    #
#---------------------#
START_TIME=`date +%s`
SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=`basename $SCRIPT`
SCRIPT_DIR=`dirname $SCRIPT`
PATH=$PATH:$SCRIPT_DIR
USAGE="Usage: ${SCRIPT_NAME} Function PID Item Data\n\t\t\t  valid Functions: ADD, ADD_ENCRYPT, DELETE, FORCE_DELETE"
LOG_FILE=`Log_Creation_Cleanup.sh /opt/Bluemix/Logs Bluemix_RBA 30`

#---------------------#
#   Function section  #
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
FUNCTION=$1
PID=$2
ITEM=$3
DATA=$4

case $FUNCTION in
    ADD|ADD_ENCRYPT)     if [[ $# -lt 4 ]]; then usageError; fi;;
    DELETE|FORCE_DELETE) if [[ $# -lt 3 ]]; then usageError; fi;;
    *)                   usageError;;
esac
 
#-----------------------------------------------------#
#   Setup the TWA environment for using param command #
#-----------------------------------------------------#
export TWA_DIR=/opt/IBM/TWA_tws
export PROTOCOL=https 
export HOST=172.0.0.1
export PORT=33180
. $TWA_DIR/TWS/tws_env.sh

#---------------------#
#   Main Section      #
#---------------------#
case $FUNCTION in 
    ADD)          param -c temp.rba.$PID.$ITEM $DATA
                  RC=$?
                  logMsg "param add variable temp.$PID.$ITEM rc:$RC";;
    ADD_ENCRYPT)  param -ec temp.rba.$PID.$ITEM $DATA
                  RC=$?
                  logMsg "param add encrypted variable temp.$PID.$ITEM rc:$RC";;
    DELETE)       param -d temp.rba.$PID.$ITEM 
                  RC=$?
                  logMsg "param delete variable temp.$PID.$ITEM rc:$RC";;
    FORCE_DELETE) param -fd temp.rba.$PID.$ITEM
                  RC=$?
                  logMsg "param force delete variable temp.$PID.$ITEM rc:$RC";;
    *)            logMsg "param Invalid option rc:99"
                  usageError;;
esac

exitScript
