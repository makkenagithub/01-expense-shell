#!/bin/bash

#deploying nodejs with shell script in backend server

IP="Private IP of DB server"
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs 18"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs 20"

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd expense
    VALIDATE $? "expense user addition"
else 
    echo -e "expense user already exist $Y SKIPPING $N"
fi

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Copying backend code"

mkdir -p /app
VALIDATE $? "/app directory creation"

cd /app
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extracting backend code"

npm install &>>$LOG_FILE
VALIDATE $? "npm install"

cp /home/ec2-user/backend.service /etc/systemd/system
VALIDATE $? "backend service file copy"

npm install mysql &>>$LOG_FILE
VALIDATE $? "MySQL client installation"

mysql -h $IP -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "MySQL schema load"

systemctl daemon-reload
VALIDATE $? "npm install"

systemctl enable backend
VALIDATE $? "backend service enable"

systemctl restart backend
VALIDATE $? "backend service restart "

