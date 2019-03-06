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
#------------------------------------------------------------------#
#   Crontab_directory_Cleanup.sh                                   #
#                                                                  #
#   This script processes the inpouted directory for deleting      #
#   for deleting files older then the retention period.  This      #
#   script logs the activity of the process along with making a    #
#   backup of the files before deleting the files.  This script    #
#   is designed to be executed by cron once a day.                 #
#                                                                  #
#   This script only uses one Input Parameter which is the         #
#   directory to be processed.  A env file is needed for all the   #
#   parameters to be used within this script.                      #
#                                                                  #
#   Input Parameters:                                              #
#     $1    DIR  (Directory to be processed)                       #
#------------------------------------------------------------------#
#  History:                                                        #
#     12/1/2016  Initial Creation by Douglas Roach                 #
#------------------------------------------------------------------#
#------------------------------------------------------------------#
#    Initialize Variables                                          #
#------------------------------------------------------------------#
SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=`basename $SCRIPT`
SCRIPT_DIR=`dirname $SCRIPT`
WHO=`whoami`
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$SCRIPT_DIR
DIR=$1

. $SCRIPT_DIR/$DIR"_clean.env"

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

#------------------------------------------------------------------#
#  Main Processing                                                 #
#------------------------------------------------------------------#
#  This script checks the input directory for files older than the #
#  given rentention period.  The file are backed up using tar and  #
#  gzip.  The backups are retained for a gvien number of days.     #
#------------------------------------------------------------------#
LOG_FILE=`$SCRIPT_DIR/Log_Creation_Cleanup.sh $LOG_DIR $LOG_NAME $LOG_RETENTION`
logMsg "`printf '=%.0s' {1..32}`  $DIR  Cleanup  `printf '=%.0s' {1..32}`"

#------------------------------------------------------------------#
#  Find all files that haven't been referenced based upon the      #
#  specified file retention period.  Save the list in a file.      #
#------------------------------------------------------------------#
find $CLEAN_DIR -name "*" -mtime +$FILE_RETENTION -type f > $FILE_LIST
logMsg "Getting list of files old than $FILE_RETENTION days"

#------------------------------------------------------------------#
#  Check if there is an exclusion list.  If so remove the excluded #
#  from the list.                                                  #
#------------------------------------------------------------------#
if [[ -f $EXCLUDE_LIST ]]; then
    logMsg "Processing Exclusion list: $EXCLUDE_LIST"
    while read EXCLUDE; do
        cat $FILE_LIST | grep -v "$EXCLUDE$" > $FILE_LIST.new
        mv $FILE_LIST.new $FILE_LIST
    done < $EXCLUDE_LIST
else
    logMsg "No Exclusion list"
fi

#------------------------------------------------------------------#
#  Make tar file of all the files to be deleted.                   #
#------------------------------------------------------------------#
TAR_FILE=$TAR_DIR/`echo $CLEAN_DIR | tr -d /`$(date +.%m.%d.%Y).tar
cat $FILE_LIST | xargs tar -cvf $TAR_FILE
RC=$?
logMsg "Created tar file of all the files to be deleted. RC:$RC"
gzip $TAR_FILE
RC=$?
logMsg "Changed tar file to a gzip file.  RC:$RC"


#------------------------------------------------------------------#
#    Process through the file list deleting the files.             #
#------------------------------------------------------------------#
while read FILE; do
    rm -f $FILE
    RC=$?
    logMsg "Removed file:$FILE  RC:$RC"
done < $FILE_LIST

#------------------------------------------------------------------------------#
#   Check for old Log File older than the specified Number of Days to keep     #
#   and delete them to prevent the File System from filling up.                #
#------------------------------------------------------------------------------#
find $TAR_DIR -name "*" -mtime +$FILE_RETENTION -type f | xargs rm -f
find $LOG_DIR -name "*" -mtime +$LOG_RETENTION -type f | xargs rm -f
logMsg "Removed old backups and logs"
logMsg "`printf -- '-%.s' {1..80}`"

RC=0
exitScript
