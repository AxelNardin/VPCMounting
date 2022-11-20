#!/bin/bash

############################ Variables ############################
credFile="./infos/credential.txt"
vpcID=""

publicSubnetID=""
privateSubnetID=""


publicSecurityGroupID=""
privateSecurityGroupID=""

instanceWBSERV=""
instanceDBSERV=""

internetGatewayID=""
natGatewayID=""

publicRoutingTableID=""
privateRoutingTableID=""

defaultIPv4="0.0.0.0/0"
defaultCidr="10.0.0.0/16"
defaultPublicSubnet="10.0.0.0/24"
defaultPrivateSubnet="10.0.1.0/24"

############################ Functions ############################

startProgram() {
	echo " "
	echo " #################################################################### "
	echo " #   _    ______  ________  ___                  __  _              # "
	echo " #  | |  / / __ \/ ____/  |/  /___  __  ______  / /_(_)___  ____    # "
	echo " #  | | / / /_/ / /   / /|_/ / __ \/ / / / __ \/ __/ / __ \/ __ \   # "
	echo " #  | |/ / ____/ /___/ /  / / /_/ / /_/ / / / / /_/ / / / / /_/ /   # "
	echo " #  |___/_/    \____/_/  /_/\____/\__,_/_/ /_/\__/_/_/ /_/\__, /    # "
	echo " #                                                       /____/     # "
	echo " #  --------------------                      --------------------  # "
	echo " #                            Mini-Project                          # "
	echo " #                     ESIEE E5 - Cloud Security                    # "
	echo " #                                                                  # "
	echo " # Students : Pauline SOLERE        (AIC) |  Sebastien WARY (CYB)   # "
	echo " #            Vincent FOUILHAC-GARY (AIC) |  Axel NARDIN    (CYB)   # "
	echo " #                                                                  # "
	echo " #                        Version 1.6 | 2023                        # "
	echo " #                                                                  # "
	echo " #################################################################### "
	echo " "

	startDate=$(date +"%T (%d/%m/%Y)") # Get start time

	echo " [START] Starting VPCMounting V1.1 "
	echo " [START] Programm started at ${startDate} "
	echo " [INFOS] To exit please press CTRL+C at any moment "
	echo " "
}

stopProgram() {
	echo " "
	endDate=$(date +"%T (%d/%m/%Y)") # Get end time
	echo " [ END ] Programm ended at ${endDate} "
	echo " [ END ] VPCMouting is finished, thank for using"
	exit 
}

AWS_Login() {
	echo " [INFOS] You are logged as : "
	aws sts get-caller-identity > ${credFile}
	sed '1d;$d' infos/credential.txt # Get credentials and prompt them
	echo " "
	echo " [INFOS] If informations are not corrects, please check the './aws' file and change credentials"
	infoChecker
}
 
informationCollector() {
	echo " [PROMT] Please select VPC CIRD, don't fill for default settings (Format : XXX.XXX.XXX.XXX/XX)"
	read -p '  --> ' cidr
	echo ""
	echo " [PROMT] Please select Public Subnet CIDR, don't fill for default settings (Format : XXX.XXX.XXX.XXX/XX)"
	read -p '  --> ' publicSubnet
	echo " "
	echo " [PROMT] Please select Private Subnet CIDR, don't fill for default settings  (Format : XXX.XXX.XXX.XXX/XX)"
	read -p '  --> ' privateSubnet
	echo " "
	keyChecker
	echo " [PROMPT] Please enter your IPv4 to connect remotely, don't fill for default settings (format : XXX.XXX.XXX.XXX/XX)"
	read -p '  --> ' ipv4
	
	if [ -z "$cidr" ] ; then
		cidr=$defaultCidr
	fi
	if [ -z "$publicSubnet" ]; then
		publicSubnet=${defaultPublicSubnet}
	fi
	if [ -z "$privateSubnet" ]; then
		privateSubnet=${defaultPrivateSubnet}
	fi
	if [ -z "$ipv4" ]; then
		ipv4=${defaultIPv4}
	fi
	echo " "
	echo " [INFOS] Options selected are : "
	echo "    |----> VPC                  : ${cidr} "
	echo "    |----> Public Subnet        : ${publicSubnet} "
	echo "    |----> Private Subnet       : ${privateSubnet} "
	echo "    |----> Key Name Server      : ${keyNameServer} "
	echo "    |----> Key Name Database    : ${keyNameDB} "
	echo "    |----> IPv4                 : ${ipv4} "
	echo " "
	infoChecker
}

keyChecker() {
	
	echo " [PROMPT] Have you got two key.pem in keys folder ? Type YES ou NO to continue "
	read -p '  --> ' infoCheck
	echo " "
	if [ $infoCheck = "YES" ]; then 
		echo " [PROMPT] Please select Server Key name present in keys folder (Format : MyKeyPair)"
		read -p '  --> ' keyNameServer
		echo " "
		echo " [PROMPT] Please select Database Key name present in keys folder (Format : MyKeyPair)"
		read -p '  --> ' keyNameDB
		echo " "
	else
		echo " [PROMPT] Please select new server key name (Format : MyKeyPair)"
		read -p '  --> ' keyNameServer
		echo " "
	    	echo " [INFOS] Creating Server Key Pair... "
		bin=&(aws ec2 create-key-pair --key-name ${keyNameServer} --query "KeyMaterial" --output text > keys/${keyNameServer}.pem | chmod 700 keys/${keyNameServer}.pem)
		echo " "
		echo " [PROMPT] Please select new databse key name (Format : MyKeyPair)"
		read -p '  --> ' keyNameDB
		echo " "
		echo " [INFOS] Creating Database Key Pair... "
		bin=&(aws ec2 create-key-pair --key-name ${keyNameDB} --query "KeyMaterial" --output text > keys/${keyNameDB}.pem | chmod 700 keys/${keyNameDB}.pem)
		echo " "
	fi
	echo " [INFOS] Key initialization done "
	echo " "
}

infoChecker() {
	echo " [PROMPT] Informations are corrects ? Type YES ou NO to continue..."
	read -p '  --> ' infoCheck
	echo " "
	if [ $infoCheck = "YES" ]; then
	        echo " [INFOS] Continue..."
	        echo " "
	else
	        echo " [INFOS] Please check Informations to continue. Aborting programm... "
	        stopProgram
	fi
}


resumeLog() {	
	echo " "
	echo " [INFOS] Please find below a resume of every created elements : "
	echo " [INFOS] Resuming Created ID : "
	echo "    |----> VPC                    : ${vpcID} "
	echo "    |----> Public Subnet          : ${publicSubnetID} "
	echo "    |----> Private Subnet         : ${privateSubnetID} "
	echo "    |----> Public Security Group  : ${publicSecurityGroupID} "
	echo "    |----> Private Security Group : ${privateSecurityGroupID} "
	echo "    |----> Internet Gateway       : ${internetGatewayID} "
	echo "    |----> Elastic IP             : ${natIpAllocation} "
	echo "    |----> NAT Gateway            : ${natGatewayID} "
	echo "    |----> Public Routing Table   : ${publicRoutingTableID} "
	echo "    |----> Private Routing Table  : ${privateRoutingTableID} "
	echo "    |----> Web Server Instance    : ${instanceWEBSERV} "
	echo "    |----> DB Server Instance     : ${instanceDBSERV} "
	echo " [INFOS] Resuming Created IP  : "
	echo "    |----> Public IP              : ${webPublicIP} "
	echo "    |----> Public Subnet          : ${publicSubnet} "
	echo "    |----> Private Subnet         : ${privateSubnet} "
	echo "    |----> Private Web Server     : ${webPrivateIP} "
	echo "    |----> Private DB Server      : ${dbPrivateIP} "
	echo " "
}


createVirtualNetwork() {
	echo " [INFOS] Creating Virtual Network "
	echo "    |----> Creating VPC "
	vpcID=$(aws ec2 create-vpc --cidr-block ${cidr} --query Vpc.VpcId --output text --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=My Automatic Secure Web Server}]') 
	
	echo "    |----> Creating Public Subnet "
	aws ec2 create-subnet --vpc-id ${vpcID} --cidr-block ${publicSubnet} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet}]' > infos/publicSubnet.txt
	
	echo "    |----> Creating Private Subnet "
	aws ec2 create-subnet --vpc-id ${vpcID} --cidr-block ${privateSubnet} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]' > infos/privateSubnet.txt
	
	echo "    |----> Getting Public and Private Subnets ID "
	aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpcID}" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}" > infos/subnetsInfo.txt
	publicSubnetID=$(cat infos/subnetsInfo.txt | jq '.[0].ID' | cut -f2 -d '"' | cut -f1 -d '"' )
	privateSubnetID=$(cat infos/subnetsInfo.txt | jq '.[1].ID' |  cut -f2 -d '"' | cut -f1 -d '"')

	echo "    |----> Creating Internet Gateway for VPC "
	internetGatewayID=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=VPC Internet Gateway}]')

	echo "    |----> Attaching Internet Gateway to VPC "
	aws ec2 attach-internet-gateway --vpc-id ${vpcID} --internet-gateway-id ${internetGatewayID}
	echo " [INFOS] Virtual Network Created "
	echo " "
}
	
	
finalizeVirtualNetwork() {	
	echo " [INFOS] Finalizing Virtual Network "
	echo "    |----> Creating Elastic IP  "
	natIpAllocation=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)

	echo "    |----> Creating NAT Gateway "
	natGatewayID=$(aws ec2 create-nat-gateway --allocation-id ${natIpAllocation} --subnet-id ${publicSubnetID} --query NatGateway.NatGatewayId --output text --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT Gateway}]')

	echo "    |------> Waiting for NAT Gateway creation "
	while :; do
		statusNAT=$(aws ec2 describe-nat-gateways --nat-gateway-id ${natGatewayID} --query NatGateways[].State --output text)
		if [ ${statusNAT} == "available" ]; then 
			echo "    |------> NAT Gateway Available "
			break 
		else  
			sleep 10
			echo "    |------> NAT Gateway NOT Available, waiting 10 more seconds "
		fi
	done
	echo "    |----> Creating route for NAT Gateway "
	aws ec2 create-route --route-table-id ${privateRoutingTableID} --destination-cidr-block ${ipv4} --nat-gateway-id ${natGatewayID}
	
	echo " [INFOS] Virtual Network Finilized "
	echo " "
}


createPublicNetwork() {
	echo " [INFOS] Creating Virtual Public Network "
	echo "    |----> Creating a Routing Table for Public Subnet "
	publicRoutingTableID=$(aws ec2 create-route-table --vpc-id ${vpcID} --query RouteTable.RouteTableId --output text --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Subnet}]' )
	
	echo "    |----> Creating a Route for all traffic to Public Subnet "
	bin=$(aws ec2 create-route --route-table-id ${publicRoutingTableID} --destination-cidr-block ${ipv4} --gateway-id ${internetGatewayID})
	
	echo "    |----> Adding an infos/publicRoute.txt file "
	aws ec2 describe-route-tables --route-table-id ${publicRoutingTableID} > infos/publicRoute.txt

	echo "    |----> Associating Route Table to Public Subnet "
	bin=$(aws ec2 associate-route-table  --subnet-id ${publicSubnetID} --route-table-id ${publicRoutingTableID})
	
	echo " [INFOS] Virtual Public Network Created "
	echo " " 
}


createPrivateNetwork() {
	echo " [INFOS] Creating Virtual Private Network "
	echo "    |----> Creating a Routing Table for Private Subnet "
	privateRoutingTableID=$(aws ec2 create-route-table --vpc-id ${vpcID} --query RouteTable.RouteTableId --output text --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private Subnet}]' )

	echo "    |----> Creating a Route for all traffic to Private Subnet "
	bin=$(aws ec2 create-route --route-table-id ${privateRoutingTableID} --destination-cidr-block ${ipv4} --gateway-id ${internetGatewayID})
	
	echo "    |----> Adding an infos/privateRoute.txt file "
	aws ec2 describe-route-tables --route-table-id ${privateRoutingTableID} > infos/privateRoute.txt
	
	echo "    |----> Associating Route Table to Private Subnet "
	bin=$(aws ec2 associate-route-table  --subnet-id ${privateSubnetID} --route-table-id ${privateRoutingTableID})
	echo " [INFOS] Virtual Private Network Created "
	echo " "
}


createSecurityGroups() {
	echo " [INFOS] Creating Security Groups "
	echo "    |----> Creating Public Security Group "
	publicSecurityGroupID=$(aws ec2 create-security-group --group-name PublicSecurityGroup --description "Security group for Public Subnet" --vpc-id ${vpcID} --output text)
	bin=$(aws ec2 authorize-security-group-ingress --group-id ${publicSecurityGroupID} --protocol all --port all --cidr ${ipv4}) 

	echo "    |----> Creating Private Security Group "
	privateSecurityGroupID=$(aws ec2 create-security-group --group-name PrivateSecurityGroup --description "Security group for Private Subnet" --vpc-id ${vpcID} --output text)
	bin=$(aws ec2 authorize-security-group-ingress --group-id ${privateSecurityGroupID} --protocol all --port all --cidr ${ipv4})

	echo " [INFOS] Security Groups Created "
	echo " " 
}


createInstances() {
	echo " [INFOS] Creating Instances "
	echo "    |----> Creating and Running Web-Server Instance "
	bin=$(aws ec2 run-instances --image-id ami-0493936afbe820b28 --count 1 --instance-type t2.micro --key-name ${keyNameServer} --security-group-ids ${publicSecurityGroupID} --subnet-id ${publicSubnetID} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Web Server}]' --associate-public-ip-address > infos/web-serverInfo.txt)
instanceWEBSERV=$(cat infos/web-serverInfo.txt | jq '.Instances[].InstanceId' |  cut -f2 -d '"' | cut -f1 -d '"')
	
	echo "    |----> Creating and Running DB-Server Instance "
	bin=$(aws ec2 run-instances --image-id ami-0493936afbe820b28 --count 1 --instance-type t2.micro --key-name ${keyNameDB} --security-group-ids ${privateSecurityGroupID} --subnet-id ${privateSubnetID} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DB Server}]' --no-associate-public-ip-address > infos/db-serverInfo.txt)
instanceDBSERV=$(cat infos/db-serverInfo.txt | jq '.Instances[].InstanceId' |  cut -f2 -d '"' | cut -f1 -d '"')
	echo "    |----> Getting differents IPs "
	echo "    |------> Waiting 30sec for running instances "
	
	sleep 30
	
	webPrivateIP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=${instanceWEBSERV}" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text)
	
	dbPrivateIP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=${instanceDBSERV}" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text)
	
	webPublicIP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=${instanceWEBSERV}" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text)
	
	echo " [INFOS] Instances Created "
	echo " "
}


main() {
	startProgram
	AWS_Login
	informationCollector
	createVirtualNetwork
	createPublicNetwork
	createPrivateNetwork
	finalizeVirtualNetwork
	createSecurityGroups
	createInstances
	resumeLog
	
	stopProgram
}


main 












