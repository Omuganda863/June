# Configure the AWS Provider
provider "aws" {
  version = "5.0"
  region  = "us-east-1"
  access_key = "your_access_key"
  secret_key = "your_secret_key"

}

# Create a VPC
resource "aws_vpc" "MyVPC" {
  cidr_block = "10.0.0.0/16"
}

#creates an IGW
resource "aws_internet_gateway" "Internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "June's Gateway"
  }
}
#subnet 1
resource "aws_subnet" "june_subnet" {
  vpc_id     = aws_vpc.MyVPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet1"
  }
}
#subnet 2

resource "aws_subnet" "subnet-1" {
vpc_id            = aws_vpc.MyVPC.id
cidr_block        = "10.0.1.0/24"
availability_zone = "us-east-1a"

tags = {
    Name = "instance-subnet"
   }
}
#create a routing table
resource "aws_route_table" "public-subnet-route" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_gateway.id
 }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.Internet_gateway.id
 }

  tags = {
    Name = "Prod"
  }
}
#security group
resource "aws_security_group" "web_traffic" {
  name        = "Welcome_WAN"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.MyVPC.id
# the ingress block allows all traffic from the web to reach the internal network
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#This block allows all traffic from the internal network to access the WAN
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-access"
  }
}
#create an elastic ip

#create a NI and attach it to a subnet
resource "aws_network_interface" "issa-interface" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web_traffic.id]

}
resource "aws_eip" "one" {
    #for use in a vpc not an ec2, hence vpc = bool
  vpc                       = true
  network_interface         = aws_network_interface.issa-interface.id
  associate_with_private_ip = "10.0.1.50"
  #creation of an EIP depends on the creation of the Gateway
  depends_on                = [aws_internet_gateway.Internet_gateway]
}
#When creating the ec2 instance we will associate it to a NIC which contains the Elastic Ip facilitating communication with the web
resource "aws_instance" "web-server-instance" {
  ami               = "ami of the instance goes here"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "generate a key pair from the ec2 menu for connection"

  network_interface {
    #indicates the number of interfaces allocated to the instance
    device_index         = 0
    #associate it with the nic we created
    network_interface_id = aws_network_interface.issa-interface.id
  }
