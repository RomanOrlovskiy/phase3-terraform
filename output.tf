output "service_url" {
  description = "Application Load balancer URL"
  value       = "https://${module.ecs_cluster.alb_url}"
}