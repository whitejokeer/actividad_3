# Output para extraer la clave privada
output "private_key_pem" {
  description = "Clave privada en formato PEM para conectarse vía SSH"
  value       = tls_private_key.generated.private_key_pem
  sensitive   = true
}

# Output para obtener la IP pública de la instancia
output "instance_public_ip" {
  description = "Public IP of the Apollo Server instance"
  value       = aws_instance.apollo_instance.public_ip
}
