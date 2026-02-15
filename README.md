# Prueba Técnica Jelou

Esta solución demuestra la implementación de una arquitectura **Serverless** robusta, segura y escalable utilizando **Terraform** para la infraestructura y **GitHub Actions** para un ciclo de CI/CD profesional basado en etapas (Stages).

## Arquitectura y Herramientas

### 1. Infraestructura como Código (Terraform)
La infraestructura está modularizada en la carpeta `terraform/`:
- **Network**: Implementa una VPC con subredes privadas para aislar la base de datos de internet.
- **Database**: despliega un Amazon RDS (PostgreSQL) seguro.
- **Compute**: AWS Lambda (Node.js 20) ejecutándose dentro de la VPC.
- **API Gateway**: Punto de entrada HTTP expuesto a internet.

### 2. Aplicación Node.js compatible con Lambda
Localizada en `src/`, utiliza las siguientes herramientas:
- **Express.js**: Framework para la gestión de rutas y lógica de negocio.
- **pg (node-postgres)**: Cliente para la conexión y consultas a PostgreSQL.
- **@vendia/serverless-express**: Adaptador para ejecutar la app Express en el entorno de AWS Lambda.

---

## Ciclo de CI/CD (Workflows por Etapas)

Para emular un flujo profesional tipo **GitLab**, el pipeline se divide en acciones secuenciales:

1.  **`01 - Quality & Security`**: Se dispara automáticamente en cada `push`. Valida el formato de Terraform (`fmt`) y realiza un `audit` de vulnerabilidades en las librerías de Node.js.
2.  **`02 - Build & Terraform Plan`**: Se dispara tras el éxito de la calidad. Empaqueta la aplicación y genera el informe de cambios (`tfplan`) que verás en los logs.
3.  **`03 - Terraform Apply (Aceptación)`**: Es un paso **MANUAL**. Para verlo en acción, ve a **Actions** -> **03 - Terraform Apply** y ejecútalo. Esto desplegará la infraestructura real en AWS.
4.  **`04 - Terraform Destroy (Limpieza)`**: Al terminar de validar la prueba, ejecuta este workflow manual para eliminar todos los recursos de AWS y evitar cargos.

---

## Guía de Ejecución Paso a Paso

### 1. Pruebas Locales (Docker)
1. Copia la plantilla: `cp .env.example .env`
2. Levanta con Docker: `docker-compose up -d --build`
3. Valida salud: [http://localhost:3000/health](http://localhost:3000/health)
4. Prueba el CRUD localmente con los comandos detallados abajo.

### 2. Despliegue y Pruebas en AWS
1. Los **Secrets** ya se encuentran configurados en GitHub (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DB_PASSWORD`).
2. Para desplegar en la cuenta real, ejecuta el workflow `03 - Terraform Apply (Aceptación)`.
3. Al finalizar, la **URL de la API** aparecerá en los logs del job (Outputs de Terraform).
4. Usa esa URL para realizar las pruebas reales con los comandos `curl`.
5. Al finalizar la prueba, ejecuta el workflow `04 - Terraform Destroy (Limpieza)` para eliminar todos los recursos de AWS.

### 3. Comandos de Prueba (CRUD REST)

#### A. Pruebas Locales (Docker)
```bash
# Crear
curl -X POST http://localhost:3000/users -H "Content-Type: application/json" -d '{"name": "Bryam", "email": "bryam@example.com"}'

# Leer
curl -X GET http://localhost:3000/users/1

# Eliminar
curl -X DELETE http://localhost:3000/users/1
```

#### B. Pruebas Reales (AWS)
Una vez ejecutado el workflow `03 - Terraform Apply`, obtén tu **api_url** de los logs y ejecuta:
```bash
# Reemplaza <api_url> con el valor real (ej: https://abc123yz.execute-api.us-east-1.amazonaws.com)

# Crear Usuario en AWS
curl -X POST <api_url>/users -H "Content-Type: application/json" -d '{"name": "Bryam AWS", "email": "aws@example.com"}'

# Listar en AWS
curl -X GET <api_url>/users/1

# Borrar en AWS
curl -X DELETE <api_url>/users/1
```

---

## Que incluye esta solucion
- **FinOps**: Arquitectura diseñada para maximizar el uso del AWS Free Tier.
- **Seguridad**: Implementación de `.env`, secretos de GitHub y subredes privadas.
- **Calidad**: Bloqueo automático del pipeline si hay vulnerabilidades o código mal formateado.
- **Modularidad**: Infraestructura escalable y workflows desacoplados.