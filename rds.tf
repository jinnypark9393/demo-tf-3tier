# RDS Subnet Group 생성
resource "aws_db_subnet_group" "demo-3tier-aurora-subnet-group" {
  name = "demo-3tier-aurora-subnet-group"
  subnet_ids = [aws_subnet.demo-3tier-private3.id, aws_subnet.demo-3tier-private4.id]
}

# RDS Aurora for MySQL 생성
resource "aws_rds_cluster" "demo-3tier-aurora-mysql" {
  cluster_identifier = "demo-3tier-aurora-mysql-cluster"
  db_subnet_group_name = aws_db_subnet_group.demo-3tier-aurora-subnet-group.name
  vpc_security_group_ids = [aws_security_group.demo-3tier-rds-sg.id]
  engine = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.05.2"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  database_name = "testdb"
  master_username = "admin"
  master_password = "passwd1!"
  skip_final_snapshot = true # terraform destroy 수행 위함
}

# RDS Instance 생성
resource "aws_rds_cluster_instance" "demo-3tier-aurora-mysql-instance" {
  count = 2
  identifier = "demo-3tier-aurora-mysql-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.demo-3tier-aurora-mysql.id
  instance_class = "db.r6g.large"
  engine = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.05.2"
}