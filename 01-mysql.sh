#!/bin/bash

#installing MySQL qith shell script

IP_DB="private IP of DB server"
LOG_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo "$0" | awk -F "." '{print $1F}') #get the script name without .sh
TIME_STAMP=$(date +%F-%H-%M-%S) #get the timestamp with date and time
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log" # log file name

 #create the log folder. -p is used here, If the folder does not exist, then it will create
 # If the folder alredy exist, then it will not give error
mkdir -p $LOG_FOLDER   

UID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#VALIDATE function
VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 $R failed $N, please check further" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 $G successfully $N" tee -a $LOG_FILE
    fi
}

echo "Script satrted executing at: $(date)" tee -a $LOG_FILE


if [ $UID -ne 0 ]   # check root user or not
then
    echo -e "$R user does not have root previlages. please run with root previlages $N" | tee -a $LOG_FILE
    exit 1  # exit from script
fi

#install mysql-server DB
dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "MySQL Server Installation"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "MySQL enable"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "MySQL start"

mysql -h $IP_DB -u root -pSuresh@12 -e 'show databases;' &>>$LOG_FILE

if [ #? -ne 0 ]
then
    echo "MySQL root password was not set. Setting it now" &>>$LOG_FILE
    mysql_secure_installation --set-root-pass Suresh@12
    VALIDATE $? "setting MySQL root password"
else    
    echo "MySQL root password was set already" | tee -a $LOG_FILE
fi


