# Guía de laboratorio: DevOps / Cloud en una noche

Objetivo: llegar a la entrevista habiendo **hecho** (no solo leído) cada cosa del aviso.
Cada módulo tiene: 🎯 qué aprendes · 🛠️ pasos · 🧠 conceptos clave · 🗣️ cómo lo dices en la entrevista.

| # | Módulo | Tiempo | Cubre del aviso |
|---|--------|--------|-----------------|
| 0 | Preparar el entorno | 20 min | Git, Linux |
| 1 | Docker | 20 min | Dockers |
| 2 | Pipelines con templates | 60 min | CI/CD, templates de pipelines, Azure/GitLab/GitHub |
| 3 | Terraform e IaC | 90 min | IaC, Terraform, CloudFormation, Serverless, aprovisionamiento declarativo |
| 4 | Identidad y acceso | 45 min | Autenticación/autorización de repos y nubes |
| 5 | Kubernetes + GitOps | 60 min | Kubernetes, GitOps |
| 6 | Mapa DevSecOps | 30 min | Tu punto débil del CV |
| ☀️ | Mañana | 60 min | Historias STAR + preguntas (ver `PREGUNTAS.md`) |

> Si vas atrasado, **prioriza 2, 3 y 4**: son las responsabilidades literales del cargo.

---

## Módulo 0 — Preparar el entorno (20 min)

🛠️ **Instalar (Mac con Homebrew):**
```bash
brew install git gh terraform kind kubectl trivy
```
Y **Docker Desktop** (https://www.docker.com/products/docker-desktop/) — ábrelo y espera a que diga "running".

Verifica:
```bash
docker version && terraform version && kind version && kubectl version --client && trivy --version
```

🛠️ **Subir el lab a GitHub:**
```bash
cd ~/Documents/Claude/Mauu_Job/devops-lab
gh auth login                       # elige GitHub.com > HTTPS > login con navegador

git init -b main
git add . && git commit -m "lab inicial"
gh repo create devops-lab --public --source=. --push
```
Luego reemplaza `Mauu-cloud` en `.github/CODEOWNERS` y `gitops/argocd-application.yaml` por tu usuario, y haz commit + push.

---

## Módulo 1 — Docker (20 min)

🛠️
```bash
docker build -t devops-lab:local .
docker run --rm -p 8080:8080 devops-lab:local     # en otra terminal: curl localhost:8080
docker image ls devops-lab                         # mira el tamaño
trivy image --severity HIGH,CRITICAL devops-lab:local
```

🧠 Lee el `Dockerfile` y entiende cada línea:
- **Multi-stage build**: una etapa instala dependencias, la final solo copia lo necesario → imagen más chica y con menos superficie de ataque.
- **Usuario no root** (`USER 10001`): si alguien compromete la app, no es root dentro del contenedor.
- **`.dockerignore`**: no mandar al build lo que no se necesita (ni secretos).
- **Tag por SHA del commit** (lo hace el pipeline): trazabilidad, nunca usar `latest` en producción.

🗣️ *"Mis imágenes son multi-stage, corren sin root, y en el pipeline se escanean con Trivy antes de publicarse. Se etiquetan con el SHA del commit para saber exactamente qué código está desplegado."*

---

## Módulo 2 — Pipelines de CI con templates (60 min) ⭐ núcleo del cargo

🎯 El cargo dice *"creación y mantenimiento de templates de pipelines"*. Eso significa: **un equipo de plataforma escribe el pipeline una vez y los demás equipos lo reutilizan**, en vez de copiar y pegar YAML en 30 repos.

🛠️ **Paso 1 — Mira el pipeline correr.** Después del push del Módulo 0, ve a tu repo → pestaña **Actions**. Abre el run y mira los jobs: `test`, `secrets-scan`, `sast`, `docker`, `terraform-local`, `terraform-aws`.

🛠️ **Paso 2 — Lee los 3 archivos en `.github/workflows/`:**
- `_template-docker-build.yml` → template reutilizable (`on: workflow_call`), con **inputs** (parámetros) y **outputs**.
- `_template-terraform.yml` → otro template, usado **dos veces** con distinta carpeta.
- `ci.yml` → el pipeline "consumidor": solo llama a los templates con `uses:` y `with:`.

🛠️ **Paso 3 — Si algo falla, ¡mejor!** Es probable que:
- **Semgrep (SAST)** marque `app.run(host="0.0.0.0")` en `main.py` como riesgo. Arréglalo borrando el bloque `if __name__ == "__main__":` (en el contenedor usamos gunicorn, no hace falta). Commit, push y mira cómo pasa a verde.
- **Trivy** encuentre CVEs en la imagen base. Opciones reales: actualizar la imagen base, o documentar una excepción en `.trivyignore`.
Esto te da una historia real para contar: *"el pipeline detectó X y lo corregí así"*.

🛠️ **Paso 4 — Demuestra el control de secretos.** Crea una rama y agrega un secreto falso:
```bash
git checkout -b prueba-secreto
echo 'api_secret = "q8Zt3LmP0vX9rK2wB7nY4cH6jD1fG5sA"' > config.txt
git add . && git commit -m "prueba" && git push -u origin prueba-secreto
gh pr create --fill
```
Mira cómo `secrets-scan` (gitleaks) falla el PR. Después cierra el PR y borra la rama.

🛠️ **Paso 5 — Protege `main`** (esto es "gestionar autorización de repositorios"):
Repo → Settings → Branches → Add rule (o *Rulesets*) para `main`:
- ✅ Require a pull request before merging (+ 1 aprobación)
- ✅ Require review from Code Owners
- ✅ Require status checks to pass → selecciona `test`, `sast`, `secrets-scan`
- ✅ Block force pushes

🛠️ **Paso 6 — Compara con GitLab y Azure DevOps** (solo lectura, 10 min): `referencias/gitlab/` y `referencias/azure-devops/`.

🧠 **Conceptos clave**
| Plataforma | Cómo se reutiliza | Palabra clave |
|---|---|---|
| GitHub Actions | Reusable workflows (pipeline completo) y Composite actions (grupo de steps) | `workflow_call`, `uses:` |
| GitLab CI | Incluir YAML de otro repo y heredar jobs ocultos | `include:`, `extends:`, jobs `.ocultos` |
| Azure DevOps | Templates de stages/jobs/steps con parámetros tipados | `template:`, `parameters:`, `extends:` |

- **CI** = integrar y validar cada cambio (test, lint, scan, build). **CD** = entregar/desplegar automáticamente.
- **Versionar los templates** (`@v1`, `@main`, o por SHA) para que un cambio no rompa a todos los equipos a la vez.
- **Mínimo privilegio en el pipeline**: `permissions: contents: read` por defecto, y cada job pide solo lo que necesita.
- **Pinnear actions por SHA** en entornos serios: evita ataques de supply chain si alguien compromete un tag.

🗣️ *"Diseñaría templates centralizados en un repo de plataforma, versionados, con inputs para lo que cambia por equipo (nombre de imagen, carpeta, severidad del escaneo). El equipo solo escribe 10 líneas que llaman al template. Así la seguridad y las buenas prácticas quedan aplicadas por defecto."*

---

## Módulo 3 — Terraform e IaC (90 min) ⭐ núcleo del cargo

🎯 *"Aprovisionamiento declarativo"* = describes **cómo quieres que quede** la infraestructura, y la herramienta calcula qué cambiar. Lo opuesto a scripts imperativos ("crea esto, luego aquello").

🛠️ **Paso 1 — Ciclo completo sin nube (usa Docker como proveedor):**
```bash
cd terraform/local-docker
terraform init          # descarga el provider, prepara el backend
terraform fmt -recursive ..
terraform validate
terraform plan          # QUÉ va a cambiar (no toca nada)
terraform apply         # escribe "yes"
curl localhost:8081 ; curl localhost:8082
terraform state list    # lo que Terraform "recuerda" que administra
terraform output
```

🛠️ **Paso 2 — Entiende el state y el drift:**
```bash
docker rm -f devops-lab-qa     # "alguien" borra algo a mano (drift)
terraform plan                 # Terraform detecta que falta y propone recrearlo
terraform apply
```

🛠️ **Paso 3 — Modifica y observa el diff:** en `main.tf` cambia `external_port = 8082` por `8083` en `app_qa`, y corre `terraform plan`. Fíjate en el símbolo `-/+` (reemplazo) vs `~` (cambio en el lugar).

🛠️ **Paso 4 — Limpia:** `terraform destroy`

🛠️ **Paso 5 — Lee `terraform/modules/docker-app/`**: un módulo es un "template de infraestructura" (justo lo que pide el cargo). Se usa dos veces en `local-docker/main.tf` con distintos parámetros.

🛠️ **Paso 6 — Lee `terraform/aws-oidc/main.tf`** (se usa en el Módulo 4) y fíjate en el bloque `backend "s3"` comentado.

🛠️ **Paso 7 — Compara (10 min):** `referencias/cloudformation/s3-bucket.yaml` y `referencias/serverless/serverless.yml`.

🧠 **Conceptos clave (te los van a preguntar)**
- **State**: archivo donde Terraform guarda el mapeo entre tu código y los recursos reales. **Nunca a Git** (puede tener secretos).
- **Remote backend**: state en S3 / Azure Storage / GCS para que el equipo comparta el mismo estado.
- **State locking**: impide que dos personas hagan `apply` al mismo tiempo y corrompan el state (S3 con `use_lockfile`, o DynamoDB en versiones antiguas; Azure Storage usa blob lease).
- **Módulos**: reutilización. Se versionan (registry privado o tags de Git).
- **Entornos**: carpetas por entorno (dev/qa/prod) llamando a los mismos módulos, o workspaces. Carpetas es lo más claro.
- **`terraform import`** / bloques `import {}`: traer bajo Terraform recursos creados a mano.
- **En el pipeline**: en el PR corre `fmt`, `validate`, escaneo (Checkov/tfsec/tflint) y `plan` (y se publica el plan como comentario). El `apply` corre solo al hacer merge a main, idealmente con aprobación.

| | Terraform | CloudFormation | Serverless Framework |
|---|---|---|---|
| Nubes | Multi-cloud (AWS, Azure, GCP, K8s…) | Solo AWS | Principalmente AWS (Lambda) |
| State | Lo manejas tú (backend) | Lo maneja AWS (Stack) | Genera CloudFormation por debajo |
| Lenguaje | HCL | YAML/JSON | YAML |
| Cuándo | Plataforma multi-cloud, estándar de la industria | Equipos 100% AWS, integración nativa (StackSets, drift detection) | Apps serverless: funciones + API + eventos rápido |

🗣️ *"Para IaC uso Terraform con módulos reutilizables versionados, state remoto con locking y cifrado, y un pipeline que en cada PR hace fmt, validate, escaneo con Checkov y plan; el apply solo ocurre al hacer merge a main. CloudFormation lo usaría si el cliente es 100% AWS, y Serverless Framework para APIs basadas en Lambda."*

---

## Módulo 4 — Identidad y acceso (45 min) ⭐ 2 de las 5 responsabilidades

🎯 El cargo dice *"gestionar autorización y autenticación de repositorios git"* y *"de nubes públicas"*.

🛠️ **Paso 1 — Entiende OIDC** (la respuesta estrella). Lee `terraform/aws-oidc/main.tf` y `.github/workflows/terraform-aws-oidc.yml`:

```
GitHub Actions ──(1) pide token OIDC firmado──▶ GitHub
      │                                     (dice: "soy repo X, rama main")
      └──(2) presenta ese token──▶ AWS STS ──(3) valida firma + condiciones del rol
                                              └──(4) entrega credenciales temporales (1 h)
```
Resultado: **cero access keys guardadas en el repo**. Si se filtra algo, expira sola.

🛠️ **Paso 2 (opcional, si tienes cuenta AWS)** — con tus credenciales locales configuradas (`aws configure`):
```bash
cd terraform/aws-oidc
terraform init
terraform apply -var="github_repo=TU_USUARIO/devops-lab"
```
Copia el output `role_arn` a GitHub → Settings → Secrets and variables → Actions → **Variables** → `AWS_ROLE_ARN`. Ve a Actions → `terraform-aws-plan` → Run workflow. Verás `aws sts get-caller-identity` mostrando el rol asumido. Al terminar: `terraform destroy`.

🧠 **Identidad por nube (apréndete esta tabla)**
| | AWS | Azure | GCP |
|---|---|---|---|
| Directorio / identidades | IAM (+ IAM Identity Center para SSO) | Microsoft Entra ID | Cloud Identity / Google Workspace |
| Identidad para máquinas | IAM Role | Service Principal / **Managed Identity** | Service Account |
| Permisos | Policies (JSON) sobre roles/usuarios | RBAC: rol + scope (mgmt group, subscription, RG, recurso) | IAM roles sobre org / folder / project |
| Pipeline sin secretos | OIDC → `AssumeRoleWithWebIdentity` | OIDC → **Workload Identity Federation** en el App Registration | **Workload Identity Federation** |
| Organización | AWS Organizations + SCPs | Management Groups + Azure Policy | Organization + Org Policies |

🧠 **Repositorios Git**
- **Autenticación**: SSO de la organización (SAML/OIDC con Entra ID, Okta), MFA obligatorio.
- **Máquinas**: GitHub Apps o deploy keys (acceso a un solo repo) mejor que PATs personales; si hay PAT, fine-grained y con expiración.
- **Autorización**: equipos con roles (read/triage/write/maintain/admin), branch protection / rulesets, CODEOWNERS, commits firmados.
- **Secretos del pipeline**: secrets a nivel repo/entorno, *environments* con aprobación manual para prod, y mejor aún OIDC + gestor de secretos (Vault, AWS Secrets Manager, Azure Key Vault).
- **Principio**: mínimo privilegio, acceso por grupos (no personas), revisiones periódicas de accesos. Esto conecta con tu experiencia en **ISO 27001** y **Zero Trust** (Cato): úsalo.

🗣️ *"Para que los pipelines accedan a la nube uso federación OIDC: el pipeline asume un rol con credenciales temporales y la relación de confianza se restringe a un repo y una rama específicos. Así no hay llaves de larga duración que rotar o que se puedan filtrar. En los repos, acceso por equipos vía SSO, rulesets en main con revisión obligatoria de CODEOWNERS y status checks."*

---

## Módulo 5 — Kubernetes + GitOps (60 min)

🛠️ **Paso 1 — Cluster local y despliegue manual:**
```bash
kind create cluster --name lab
kind load docker-image devops-lab:local --name lab     # sube tu imagen local al cluster
kubectl kustomize k8s/overlays/dev                      # ver el YAML final que se aplicará
kubectl apply -k k8s/overlays/dev
kubectl get pods -n dev -w                              # Ctrl+C cuando estén Running
kubectl port-forward -n dev svc/devops-lab 9090:80      # otra terminal: curl localhost:9090
```

🛠️ **Paso 2 — Comandos para depurar (te pueden preguntar "¿un pod está en CrashLoopBackOff, qué haces?"):**
```bash
kubectl describe pod -n dev <pod>      # eventos: imagen no encontrada, probes fallando, OOMKilled
kubectl logs -n dev <pod> --previous   # logs del contenedor que se cayó
kubectl get events -n dev --sort-by=.lastTimestamp
```

🛠️ **Paso 3 — GitOps con ArgoCD:**
```bash
kubectl delete -k k8s/overlays/dev                     # limpiamos: ahora lo desplegará ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait -n argocd --for=condition=available deploy --all --timeout=300s
kubectl apply -f gitops/argocd-application.yaml        # (con tu usuario ya reemplazado)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward -n argocd svc/argocd-server 8443:443
```
Entra a https://localhost:8443 (usuario `admin`). Verás la app sincronizada.

🛠️ **Paso 4 — La magia de GitOps:**
- En `k8s/overlays/dev/kustomization.yaml` cambia `value: 2` (réplicas) por `3` → commit + push → mira cómo ArgoCD crea el tercer pod **sin que tú ejecutes kubectl**.
- **Self-heal**: `kubectl scale deploy devops-lab -n dev --replicas=1` → ArgoCD lo devuelve a 3.

🛠️ **Paso 5 — Limpia:** `kind delete cluster --name lab`

🧠 **Conceptos clave**
- **Deployment** (réplicas, rolling update) · **Service** (IP estable / balanceo) · **Ingress** (HTTP externo) · **ConfigMap/Secret** · **Namespace**.
- **Probes**: readiness (¿recibe tráfico?) vs liveness (¿reiniciar?).
- **requests/limits**: lo que se reserva vs el máximo. Sin límite de memoria → un pod puede tumbar el nodo; si excede el límite → OOMKilled.
- **securityContext**: runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities.
- **Kustomize** (base + overlays) vs **Helm** (charts con plantillas y valores): ambos son formas de "template" para K8s.
- **Secretos en K8s**: los Secret nativos solo están en base64. En serio: External Secrets Operator (lee de Vault/Key Vault/Secrets Manager) o Sealed Secrets.
- **GitOps** = Git es la única fuente de verdad del estado deseado; un agente **dentro** del cluster (ArgoCD/Flux) **jala** (pull) y reconcilia. Ventajas: auditoría (todo es un commit), rollback = `git revert`, el pipeline no necesita credenciales del cluster, corrige el drift solo.
- **Flujo completo**: CI construye la imagen → actualiza el tag en el repo de manifiestos → ArgoCD despliega.

🗣️ *"En mi experiencia con EKS…"* → prepara 2 frases **reales** sobre qué hiciste con EKS y Docker en Activeit (qué apps, cuántos nodos, cómo desplegaban). Si no usaban GitOps allí, di: *"allí desplegábamos con kubectl/pipelines; GitOps con ArgoCD lo he trabajado en laboratorio y es lo que implementaría por auditoría y self-healing"*.

---

## Módulo 6 — Mapa DevSecOps (30 min)

🎯 Saber **dónde va cada control** en el pipeline y **por qué**. Esto ya lo practicaste en el Módulo 2.

```
 código ──▶ commit ──▶ PR / CI ─────────────────────────────▶ registry ──▶ deploy ──▶ runtime
  IDE        pre-commit   SAST (Semgrep/SonarQube)             firma de     admission   monitoreo,
  plugins    gitleaks     SCA dependencias (Trivy/Dependabot)  imagen       policies    SIEM (Wazuh),
                          secretos (gitleaks)                  (cosign)     (Kyverno/   EDR, WAF
                          IaC (Checkov/tfsec)                               OPA)        DAST (ZAP)
                          imagen (Trivy)                                                en staging
```

| Tipo | Qué analiza | Herramientas | Cuándo |
|---|---|---|---|
| **SAST** | Código fuente (sin ejecutarlo) | SonarQube, Semgrep, CodeQL | En cada PR |
| **SCA** | Dependencias con CVEs conocidos, licencias | Trivy, Dependabot, Snyk | En cada PR + periódico |
| **Secretos** | Claves/tokens en el código | gitleaks, GitHub secret scanning | Pre-commit + PR |
| **IaC scan** | Configs inseguras (bucket público, SG 0.0.0.0/0) | Checkov, tfsec/Trivy config | En cada PR de infra |
| **Imagen** | CVEs del SO y librerías de la imagen | Trivy, Grype | Al construir + periódico en registry |
| **DAST** | App corriendo, ataques simulados (XSS, SQLi) | OWASP ZAP, Burp | Contra staging, después del deploy |
| **Supply chain** | Integridad de lo que despliegas | SBOM (Syft), firma (cosign), pin por SHA | Build + admission |

🧠 **Shift-left**: encontrar problemas lo más temprano posible, donde arreglarlos es más barato. **Pero** sin bloquear todo: se define qué severidad rompe el build (ej: CRITICAL/HIGH con fix disponible) y el resto se reporta.

🗣️ **Tu respuesta honesta y fuerte:** *"Mi experiencia productiva en seguridad es más del lado de operaciones: SIEM con Wazuh, EDR con SentinelOne, Zero Trust con Cato y alineamiento a ISO 27001. La parte de seguridad en el pipeline (SAST, SCA, escaneo de imágenes e IaC) la he trabajado en laboratorio; por ejemplo, tengo un pipeline con gitleaks, Semgrep, Trivy y Checkov que corta el build si encuentra secretos o vulnerabilidades críticas. Es justamente el área en la que quiero crecer."*

---

## ✅ Checklist antes de dormir
- [ ] Repo `devops-lab` en GitHub con el pipeline en verde
- [ ] Viste fallar al menos un control de seguridad y lo corregiste
- [ ] Hiciste `plan`/`apply`/`destroy` y provocaste un drift
- [ ] Sabes explicar OIDC en 30 segundos
- [ ] Viste ArgoCD sincronizar un cambio desde Git
- [ ] Leíste `PREGUNTAS.md` una vez

Mañana: lee `PREGUNTAS.md` en voz alta y ten el repo abierto por si te piden mostrar algo. 🚀
