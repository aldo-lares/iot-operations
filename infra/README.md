# Infrastructure as Code (Bicep)

Este directorio contiene las plantillas de Bicep para desplegar la infraestructura de IoT Operations en Azure.

## Estructura de Archivos

```
infra/
├── main.bicep           # Plantilla principal de Bicep
├── main.bicepparam      # Archivo de parámetros (valores por defecto)
├── bicepconfig.json     # Configuración de análisis y validación
└── README.md           # Esta documentación
```

## Requisitos Previos

- Azure CLI instalado
- Bicep CLI (se instala automáticamente con Azure CLI)
- Acceso a una suscripción de Azure
- PowerShell o Bash

## Parámetros de Entrada

### Parámetro: `projectName`
- **Descripción**: Nombre del proyecto (minúsculas, sin espacios)
- **Tipo**: string
- **Ejemplo**: `iotops`
- **Uso en nombres**: `rg-iotops-eastus-a1b2c3d4`

### Parámetro: `location`
- **Descripción**: Región de Azure para el resource group
- **Tipo**: string
- **Ejemplos válidos**: `eastus`, `westus`, `northeurope`, `westeurope`, `southeastasia`

### Parámetro: `environment`
- **Descripción**: Identificador del ambiente
- **Tipo**: string
- **Valores permitidos**: `dev`, `staging`, `prod`
- **Defecto**: `dev`

### Parámetro: `tags`
- **Descripción**: Etiquetas de recurso (pares clave-valor)
- **Tipo**: object
- **Defecto**: Incluye project, owner, costCenter

### Parámetro: `deploymentDate`
- **Descripción**: Marca de tiempo del despliegue en UTC (ISO 8601)
- **Tipo**: string
- **Defecto**: `utcNow('u')` (establecido automáticamente en la plantilla)

## Convención de Nombres

El resource group se crea con el siguiente patrón:

```
rg-{projectName}-{location}-{uniqueSuffix}
```

**Ejemplo**: `rg-iotops-eastus-a1b2c3d4`

- `rg-` → Prefijo para Resource Group
- `iotops` → Nombre del proyecto
- `eastus` → Ubicación
- `a1b2c3d4` → Suffix único basado en el ID de suscripción (previene conflictos de nombres)

## Despliegue

### Opción 1: Usando el archivo de parámetros (Recomendado)

```powershell
# Validar la plantilla
az deployment sub validate `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam

# Desplegar
az deployment sub create `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam
```

### Opción 2: Pasando parámetros en línea de comandos

```powershell
# Desplegar con parámetros específicos
az deployment sub create `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters projectName=iotops location=westus environment=prod
```

### Opción 3: Bash/Shell

```bash
# Validar
az deployment sub validate \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Desplegar
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## Compilar Bicep a ARM Template

Para compilar la plantilla Bicep a formato ARM JSON:

```powershell
az bicep build --file infra/main.bicep --outfile infra/main.json
```

## Validación y Linting

El archivo `bicepconfig.json` define las reglas de validación. Para validar localmente:

```powershell
# Validación de sintaxis
az bicep build --file infra/main.bicep --outfile /dev/null

# Ver advertencias durante la validación
az bicep build --file infra/main.bicep --outdir .
```

## Customización

### Editar parámetros por defecto

Modifica `main.bicepparam`:

```bicepparam
param projectName = 'tu-proyecto'
param location = 'tu-region'
param environment = 'prod'
```

### Agregar recursos adicionales

1. Abre `main.bicep`
2. Agrega nuevos parámetros si es necesario (sección `Parameters`)
3. Define los recursos en la sección `Resources`
4. Agrega outputs en la sección `Outputs`

## Mejores Prácticas Implementadas

✅ Usar `targetScope = 'subscription'` para crear resource groups  
✅ Parámetros con descripciones y tipos explícitos  
✅ Suffix único usando `uniqueString()` para evitar conflictos de nombres  
✅ Archivos `.bicepparam` en lugar de JSON (mejor práctica actual)  
✅ Etiquetas consistentes en recursos (con `deploymentDate` basado en `utcNow()` por default en parámetros)  
✅ Comentarios informativos  
✅ Outputs para capturar IDs y nombres de recursos  
✅ Configuración de análisis (bicepconfig.json)

## Solución de Problemas

### Error: "Resource group already exists"
El nombre del resource group ya existe en tu suscripción. Verifica:
- El `projectName` sea único
- El `location` sea correcto
- Que no exista un RG con ese nombre

### Error: "Insufficient privileges"
Asegúrate de que tu usuario/service principal tenga permisos:
- `Microsoft.Resources/subscriptions/resourceGroups/write`
- En el scope de suscripción

### Validar permisos:
```powershell
az role assignment list --assignee (az account show --query user.name -o tsv)
```

## Referencias

- [Documentación de Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Naming conventions for Azure resources](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
 - [Funciones permitidas y restricciones](https://aka.ms/bicep/core-diagnostics#BCP065)
