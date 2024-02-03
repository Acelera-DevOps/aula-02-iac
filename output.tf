output "instance_public_ips" {
  value = aws_instance.web.*.public_ip
  description = "Exibe o ip publico das intancias"
}

output "web_instance_ids" {
  value = aws_instance.web.*.id
  description = "Exibe o id das intancias"
}