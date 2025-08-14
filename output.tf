
  output "alb_dns_name_back" {
  value = aws_lb.backend_lb.dns_name
}

output "alb_dns_name_front" {
  value = aws_lb.frontend_lb.dns_name
}
