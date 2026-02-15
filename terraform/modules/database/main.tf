# RDS Postgres

# Subnet Group RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# SG Database
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Permitir acceso a PostgreSQL solo desde la Lambda"
  vpc_id      = var.vpc_id

  # Ingreso: Solo desde el SG de la Lambda
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]
  }

  # Egreso
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "appdb"
  username               = "dbadmin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true # no crear un backup al borrar 
  publicly_accessible    = false

  tags = {
    Name = "${var.project_name}-db"
  }
}

# SSM Parameters (Secrets)
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/${var.project_name}/db_endpoint"
  type  = "String"
  value = aws_db_instance.postgres.endpoint
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/db_password"
  type  = "SecureString" # cifra automáticamente
  value = var.db_password
}

output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
