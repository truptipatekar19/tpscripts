#!/bin/bash
### Created By: Trupti Patekar
### start Date: 03/20/2020
### Last  updatedon: 04/14/2020
####  This script is used to delete yesterday backup of HANA DB S4H TENANT SHS.

#########################    START   ###
 
SCRIPT_PATH=/root/scripts/backup_script/db_shs/
DATA_PATH=/usr/sap/S4H/HDBSID/backup/data
LOG_PATH=/usr/sap/S4H/HDBSID/${HOSTNAME}/trace
TENANT_N=SHS
TENANT_DIR=DB_"$TENANT_N"
TODAY_LST="$SCRIPT_PATH"TODAY_LIST
#LASTDAY_LST="$SCRIPT_PATH"LASTDAY_LIST
OLDER_LST="$SCRIPT_PATH"OLDFILE_LIST
T_DATE=`date "+%F"`

CHECK_LOGFILE_SIZE ()
{
if [ -e  $SCRIPT_PATH/$TENANT_DIR.log ]; then
MAXSIZE=52428800
FILE_SIZE=`stat -c %s  $SCRIPT_PATH/$TENANT_DIR.log`
        if [ "$MAXSIZE" -le "$FILE_SIZE" ];then
        rm  $SCRIPT_PATH/$TENANT_DIR.log
        fi
fi

if [ -e  $SCRIPT_PATH/"$TENANT_DIR"_error.log ]; then
MAXSIZE=52428800
FILE_SIZE=`stat -c %s  $SCRIPT_PATH/"$TENANT_DIR"_error.log`
        if [ "$MAXSIZE" -le "$FILE_SIZE" ];then
        rm  $SCRIPT_PATH/"$TENANT_DIR"_error.log
        fi
fi

if [ -e  $SCRIPT_PATH/status.log ]; then
MAXSIZE=52428800
FILE_SIZE=`stat -c %s  $SCRIPT_PATH/status.log`
        if [ "$MAXSIZE" -le "$FILE_SIZE" ];then
        rm  $SCRIPT_PATH/status.log
        fi
fi
}

	backup_status ()
	{
	echo -e "\n"   >> $SCRIPT_PATH/status.log
	echo "                        DATE: `date`                           " | tee -a  $SCRIPT_PATH/status.log > $SCRIPT_PATH/mail_status.log
	echo "                           Old Backup deletion Summary                    " | tee -a  $SCRIPT_PATH/status.log >> $SCRIPT_PATH/mail_status.log
	echo "                              Tenant Name: "$TENANT_DIR"                                        " | tee -a $SCRIPT_PATH/status.log >> $SCRIPT_PATH/mail_status.log
	}
	backup_status	


	CHECK_BF ()
	{
		cd $DATA_PATH/"$TENANT_DIR"
		find $DATA_PATH/"$TENANT_DIR"  -maxdepth 1 -type f -daystart  -mtime 0 -print | grep -xv "." > $TODAY_LST
#		find $DATA_PATH/"$TENANT_DIR"  -maxdepth 1 -type f -daystart  -mtime 1 -print | grep -xv "." > $LASTDAY_LST
		find $DATA_PATH/"$TENANT_DIR"  -maxdepth 1 -type f -daystart  -mtime +0 -print  | grep -xv "." > $OLDER_LST

			if [ `grep -c ^ "$TODAY_LST"` -eq "5" ]; then
				echo "Backup files are verified" >> $SCRIPT_PATH/$TENANT_DIR.log 
			else
				echo "Backup files are not verified" >> $SCRIPT_PATH/"$TENANT_DIR"_error.log
				echo "		Backup files are not verified	"	| tee -a  $SCRIPT_PATH/status.log >> $SCRIPT_PATH/mail_status.log
			mail -s "$(hostname) HANA TENANT $TENANT_DIR Backup Summary" -r username@fake.com  username@fake.com < $SCRIPT_PATH/mail_status.log
				exit 200
			fi

	}


#	CHECK_SIZE ()
#	{

#		cd "$DATA_PATH"/DB_$TENANT_N
#			if [ $(stat -c%s `grep -e 0_1\$ $TODAY_LST`) -ge $(stat -c%s `grep -e 0_1\$ $LASTDAY_LST`) ] && [ $(stat -c%s `grep -e 2_1\$ $TODAY_LST`) -ge $(stat -c%s `grep -e 2_1\$ $LASTDAY_LST`) ] && [ $(stat -c%s `grep -e 3_1\$ $TODAY_LST`) -ge $(stat -c%s `grep -e 3_1\$ $LASTDAY_LST`) ] && [ $(stat -c%s `grep -e 4_1\$ $TODAY_LST`) -ge $(stat -c%s `grep -e 4_1\$ $LASTDAY_LST`) ] && [ $(stat -c%s `grep -e 5_1\$ $TODAY_LST`) -ge $(stat -c%s `grep -e 5_1\$ $LASTDAY_LST`) ]
#			then
#				echo "SUCCESS"
#				echo  "Backup File size is verified" >> $SCRIPT_PATH/$TENANT_DIR.log
#			else
#				echo "Backup File size is NOT verified" >> $SCRIPT_PATH/"$TENANT_DIR"_error.log 
#			fi
#	}


	CHECK_STATUS ()
	{

		cd $LOG_PATH/$TENANT_DIR
		#BACK_LOG=`grep "$T_DATE" backup.log  | grep -A90  "BACKUP DATA FOR SHS USING FILE" | grep -o " SAVE DATA finished successfully"\$`
		BACK_LOG=`grep "$T_DATE" backup.log  | grep -A90 "command: backup data using file" | grep -o " SAVE DATA finished successfully"\$ | tail -n1`
		BACK_LOG1=`echo $BACK_LOG`
		BACK1_LOG=`grep "$T_DATE" backup.log  | grep -A90 "command: BACKUP DATA FOR $TENANT_N USING FILE" | grep -o " SAVE DATA finished successfully"\$ | tail -n1`
		BACK1_LOG1=`echo $BACK1_LOG`
		
			#if [ "$BACK_LOG1" == "SAVE DATA finished successfully" ]; then
			if [ "$BACK_LOG1" == "SAVE DATA finished successfully" -o "$BACK1_LOG1" == "SAVE DATA finished successfully" ]; then
				echo "SUCCESS"
				echo "OK" >  $SCRIPT_PATH/$TENANT_N"_CH"
				echo "Today's backup $BACK_LOG1 for $TENANT_DIR" >> $SCRIPT_PATH/$TENANT_DIR.log
			else
				echo "Today's backup SAVE DATA NOT finished for $TENANT_DIR" >> $SCRIPT_PATH/"$TENANT_DIR"_error.log
				echo "Failed" >  $SCRIPT_PATH/$TENANT_N"_CH"
			fi

	}

	REMOVE_FILES ()
	{
		for line in `cat "$OLDER_LST"`
		do
			rm -v $line >> $SCRIPT_PATH/$TENANT_DIR.log
			if [ $? -eq 0 ]; then
				echo "$line old backup file deleted successfully" >> $SCRIPT_PATH/$TENANT_DIR.log
				echo "OK" >  $SCRIPT_PATH/$TENANT_N"_RE"
			else
				echo "Failed" >  $SCRIPT_PATH/$TENANT_N"_RE"
			fi
		done
	}	
	send_mail ()
	{
		if [ $(cat $SCRIPT_PATH/$TENANT_N"_CH") == "Failed" ];then
        		mail -s "$(hostname) HANA TENANT $TENANT_DIR Backup Summary" -r username@fake.com  username@fake.com < $SCRIPT_PATH/mail_status.log
		elif [ $(cat $SCRIPT_PATH/$TENANT_N"_RE") == "Failed" ];then
        		mail -s "$(hostname) HANA TENANT $TENANT_DIR Backup Summary" -r username@fake.com  username@fake.com < $SCRIPT_PATH/mail_status.log
		else
        		exit 201
		fi

	}

CHECK_LOGFILE_SIZE

echo -e "\n" >>  $SCRIPT_PATH/$TENANT_DIR.log
date >> $SCRIPT_PATH/$TENANT_DIR.log
echo -e "\n" >>  $SCRIPT_PATH/"$TENANT_DIR"_error.log
date >> $SCRIPT_PATH/"$TENANT_DIR"_error.log
CHECK_BF
	if [ "$(CHECK_STATUS)" == "SUCCESS" ]
	then
        	REMOVE_FILES
	else
		echo " "$(CHECK_STATUS)" " >> $SCRIPT_PATH/"$TENANT_DIR"_error.log
		echo "NA" >  $SCRIPT_PATH/$TENANT_N"_RE"
	fi

echo "                        Old Backup Deletion Status:  `cat $SCRIPT_PATH/$TENANT_N"_RE"`             " | tee -a $SCRIPT_PATH/status.log >> $SCRIPT_PATH/mail_status.log
echo "                      New Backup Completation Status:  `cat $SCRIPT_PATH/$TENANT_N"_CH"`         " | tee -a $SCRIPT_PATH/status.log >> $SCRIPT_PATH/mail_status.log

send_mail

#######   END   ############################
