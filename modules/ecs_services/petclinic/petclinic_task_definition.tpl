[
    {
    "name": "${CONTAINER_NAME}",
    "essential": true,
    "image": "${IMAGE}",
    "memory": ${MEMORY},
    "portMappings": [
        { "containerPort": ${CONTAINER_PORT} }
    ],
    "environment": [
      { "name": "DATABASE", "value": "${DATABASE}" },
      { "name": "SPRING_DATASOURCE_URL", "value": "${SPRING_DATASOURCE_URL}" },
      { "name": "SPRING_DATASOURCE_USERNAME", "value": "${SPRING_DATASOURCE_USERNAME}" },
      { "name": "SPRING_DATASOURCE_PASSWORD", "value": "${SPRING_DATASOURCE_PASSWORD}" },
      { "name": "SPRING_DATASOURCE_INITIALIZATION_MODE", "value": "always" },
      { "name": "SPRING_DATASOURCE_CONTINUE_ON_ERROR", "value": "true" }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${awslogs-group}",
            "awslogs-region": "${awslogs-region}"
        }
    }
  }
]