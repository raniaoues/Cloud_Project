# ============================================
# FRONTEND — Instance EC2 publique (Angular + Nginx)
# ============================================

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type

  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]

  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # 🔥 IMPORTANT: évite cache user_data (très important pour debugging)
  user_data_replace_on_change = true

  # ============================================
  # USER DATA (Angular build + Nginx deploy)
  # ============================================
  user_data = base64encode(templatefile("${path.module}/user_data_frontend.sh", {
    github_repo  = var.github_repo
    alb_dns_name = aws_lb.main.dns_name
    app_port     = var.app_port
  }))

  # ============================================
  # DEPENDENCIES (important pour éviter race conditions)
  # ============================================
  depends_on = [
    aws_lb.main,
    aws_lb_target_group.backend
  ]

  tags = {
    Name    = "${var.project_name}-frontend"
    Project = var.project_name
  }
}