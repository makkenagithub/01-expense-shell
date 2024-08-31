#!/bin/bash

#deploying nginx with shell script in frontend server

#IP="Private IP of DB server"
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
        echo -e "$2 $R FAILED $N, please check further" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 $G SUCCESSFULLY $N" tee -a $LOG_FILE
    fi
}

echo "Script satrted executing at: $(date)" tee -a $LOG_FILE


if [ $UID -ne 0 ]   # check root user or not
then
    echo -e "$R user does not have root previlages. please run with root previlages $N" | tee -a $LOG_FILE
    exit 1  # exit from script
fi

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Nginx installation"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Frontend code download"

rm -rf /usr/share/nginx/html/*
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting front end code"

cp /home/ec2-user/frontend.conf /etc/nginx/default.d
VALIDATE $? "Copying front end config file"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling nginx"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restarting nginx"
