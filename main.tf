#configure aws provider
provider "aws" {
  region = "us-east-2"
}
resource "aws_security_group" "ssh" {
  name_prefix = "terraformJenkins"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}



#define resource
resource "aws_instance" "linux" {
  ami                    = "ami-0d80c4e4338722fc6"
  instance_type          = "t2.micro"
  key_name               = "letmein"
  count                  = 1
  vpc_security_group_ids = [aws_security_group.ssh.id]
  user_data              = <<EOF
              #!/bin/bash
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo 
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key 
sudo yum upgrade 
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
              EOF
}

# Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins_artifacts_bucket" {
  # Specify the name of the bucket to be created
  bucket = "jenkins-artifacts-bucket528"

  # Set the ACL (Access Control List) to "private" to ensure the bucket is not publicly accessible
  acl = "private"

  # Define tags for the bucket (optional)
  tags = {
    Name = "Jenkins Artifacts Bucket"
  }
}

# Apply a bucket policy to make the bucket private
resource "aws_s3_bucket_policy" "jenkins_artifacts_bucket_policy" {
  # Specify the ID of the bucket to apply the policy to
  bucket = aws_s3_bucket.jenkins_artifacts_bucket.id

  # Define the policy using JSON encoding
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Deny all actions on all resources by any principal
        Action    = "s3:*"
        Effect    = "Deny"
        Resource  = "${aws_s3_bucket.jenkins_artifacts_bucket.arn}/*"
        Principal = "*"
      }
    ]
  })
}

