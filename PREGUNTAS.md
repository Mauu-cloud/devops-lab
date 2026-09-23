# Preguntas probables y cómo responderlas

> Regla de oro: respuesta corta (30–60 s) + un ejemplo **real** tuyo o del lab. Si no sabes algo: *"No lo he usado en producción, pero lo abordaría así…"*. Nunca inventes.

## Tu presentación (1 minuto — practícala en voz alta)
*"Soy Ingeniero en Conectividad y Redes, con 4 años en infraestructura on-premise y cloud. En Activeit lideré la migración de ~150 servidores de VMware a Proxmox, la migración a Microsoft 365 de 150 usuarios, y administré Kubernetes (EKS) y Docker para aplicaciones internas. Tengo un fuerte foco en automatización con Python y Bash, observabilidad con Prometheus, Grafana y Dynatrace, y seguridad operativa con Wazuh, SentinelOne y Zero Trust. Ahora quiero enfocarme de lleno en DevOps y plataforma: pipelines, IaC y automatización a escala, y por eso me interesa este cargo."*

---

## CI/CD y templates
**1. ¿Cómo diseñarías templates de pipeline para 20 equipos?**
Repo central de templates versionado (tags `v1`, `v2`). Templates con inputs para lo que varía (imagen, carpeta, lenguaje) y con seguridad por defecto (tests, SAST, escaneo de secretos e imagen). Cada equipo escribe un pipeline corto que llama al template. Cambios en los templates vía PR con revisión, y los equipos adoptan versiones nuevas cuando quieren (no rompes a todos a la vez). Y se documenta cada template: inputs, outputs, ejemplo de uso.

**2. Diferencia entre reusable workflow y composite action (GitHub)?**
Reusable workflow = un pipeline completo con jobs (`workflow_call`). Composite action = un conjunto de steps que se usa dentro de un job. En GitLab el equivalente es `include` + `extends`; en Azure DevOps, `template` con `parameters`.

**3. CI vs CD (entrega vs despliegue continuo)?**
CI: integrar y validar cada cambio. Continuous Delivery: siempre listo para producción, con aprobación manual. Continuous Deployment: a producción automáticamente si todo pasa.

**4. ¿Cómo manejas secretos en un pipeline?**
Primero evitarlos: OIDC hacia la nube. Si hacen falta: secrets del repo/entorno o un gestor (Vault, Key Vault, Secrets Manager), nunca en el código, enmascarados en logs y con mínimo privilegio. Más gitleaks para detectar fugas.

**5. ¿Cómo haces rollback?**
Imágenes inmutables etiquetadas por SHA → redesplegar la versión anterior. Con GitOps: `git revert` y ArgoCD reconcilia. En K8s también `kubectl rollout undo`.

**6. Estrategias de despliegue.**
Rolling update (default en K8s), blue/green (dos entornos, cambias el tráfico), canary (un % del tráfico a la versión nueva y se va ampliando).

## IaC / Terraform
**7. ¿Qué es el state y dónde lo guardas?**
El mapeo entre el código y los recursos reales. Remoto (S3, Azure Storage, GCS), cifrado, con versionado y locking. Nunca en Git.

**8. ¿Qué pasa si dos personas hacen apply a la vez?**
Por eso existe el state locking: el segundo espera o falla. Además, en un equipo el apply lo hace solo el pipeline, no las personas.

**9. ¿Qué es el drift y cómo lo detectas?**
Diferencia entre el código y la realidad (alguien cambió algo a mano). `terraform plan` lo muestra; se puede programar un plan periódico en el pipeline que alerte.

**10. Terraform vs CloudFormation vs Serverless Framework.** → Ver tabla en GUIA.md, Módulo 3.

**11. ¿Cómo organizas dev/qa/prod?**
Mismos módulos, una carpeta (o un state) por entorno, variables distintas, y promoción de cambios dev → qa → prod por pipeline con aprobación en prod.

**12. ¿Qué es un módulo y cómo lo versionas?**
Un bloque reutilizable de infraestructura (como una función). Se versiona con tags de Git o en un registry privado y se referencia con `?ref=v1.2.0`.

**13. ¿Qué es aprovisionamiento declarativo?**
Describes el estado final deseado, no los pasos. La herramienta calcula el diff y converge (Terraform, K8s, ArgoCD). Imperativo = scripts paso a paso.

## Identidad y acceso
**14. ¿Cómo autenticas un pipeline en AWS/Azure/GCP sin llaves?**
OIDC / Workload Identity Federation: el pipeline presenta un token firmado por GitHub/GitLab/Azure DevOps, la nube lo valida contra una relación de confianza restringida (repo + rama/entorno) y entrega credenciales temporales.

**15. ¿Cómo gestionas el acceso a los repos?**
SSO con el IdP corporativo + MFA, equipos con roles (no individuos), rulesets en main (PR, aprobaciones, CODEOWNERS, status checks, sin force push), GitHub Apps o deploy keys para máquinas, y revisión periódica de accesos.

**16. RBAC en Azure?**
Rol (Reader, Contributor, Owner o custom) + principal (usuario, grupo, service principal, managed identity) + scope (management group > subscription > resource group > recurso). Se hereda hacia abajo.

**17. ¿Qué es mínimo privilegio en la práctica?**
Cada identidad tiene solo los permisos que necesita, en el scope más chico y el menor tiempo posible (credenciales temporales, acceso just-in-time).

## Kubernetes / Docker / GitOps
**18. Un pod está en CrashLoopBackOff, ¿qué haces?**
`kubectl describe pod` (eventos, exit code, OOMKilled, probes), `kubectl logs --previous`, revisar config/secretos/variables, recursos y probes mal configuradas.

**19. ¿Qué es GitOps y por qué usarlo?**
Git como fuente de verdad del estado deseado + un agente en el cluster (ArgoCD/Flux) que jala y reconcilia. Auditoría, rollback con revert, self-healing, y el CI no necesita credenciales del cluster.

**20. ¿Cómo haces una imagen Docker segura y liviana?**
Imagen base mínima (slim/distroless), multi-stage, usuario no root, sin secretos en capas, `.dockerignore`, escaneo con Trivy y tags inmutables.

**21. Helm vs Kustomize.**
Helm: charts con plantillas y values, versionables y con dependencias; bueno para distribuir software. Kustomize: base + overlays sin plantillas, parches sobre YAML plano; integrado en kubectl.

## Arquitectura y deseables
**22. Microservicios / DDD / Hexagonal (breve).**
Microservicios: servicios pequeños, desplegables de forma independiente, cada uno con sus datos. DDD: modelar el software según el dominio del negocio (bounded contexts, que suelen ser buenos límites entre microservicios). Hexagonal / Clean: el núcleo de negocio no depende de la infraestructura; se conecta por puertos y adaptadores, lo que facilita tests y cambiar de base de datos o proveedor.

**23. Agentes, LLMs, spec-driven.**
Spec-driven development: primero se escribe una especificación clara (requisitos, contratos, criterios de aceptación) y a partir de ella se genera o valida el código, cada vez más con asistentes de IA. Un agente es un LLM que usa herramientas en ciclos para cumplir una tarea. Menciona si usas asistentes de IA para escribir scripts, Terraform o pipelines, y que siempre revisas lo que generan.

## DevSecOps (tu punto sensible)
**24. ¿Qué experiencia tienes en DevSecOps?**
→ Usa la respuesta honesta de GUIA.md, Módulo 6. Resalta lo real (Wazuh + Python, SentinelOne, Cato ZTNA, ISO 27001) y lo que hiciste en el lab.

---

## Historias STAR (Situación, Tarea, Acción, Resultado) — con tu experiencia real
Completa los números que recuerdes; los números concretos convencen.

**A. Migración VMware → Proxmox (~150 servidores)**
S: licenciamiento VMware caro · T: migrar sin cortar servicios · A: ¿cómo planificaste? ¿por olas? ¿cómo probaste? ¿rollback? · R: ahorro de licencias, ¿% o monto?, ¿downtime?

**B. Automatización con Python + Wazuh**
S: alertas del SIEM lentas o sin contexto · T: reducir el tiempo de respuesta · A: script que enriquece y enruta notificaciones · R: ¿de cuánto a cuánto bajó el tiempo de detección/respuesta?

**C. Dashboard unificado (Dynatrace + Prometheus + Grafana)**
S: visibilidad fragmentada · A: qué métricas, qué alertas · R: menos tiempo de respuesta ante caídas, cumplimiento de SLAs.

**D. (del lab) "El pipeline detectó un problema"**
Semgrep o Trivy encontraron X → lo corregí así → el pipeline quedó en verde.

---

## Preguntas para hacerles tú (elige 2–3)
1. ¿Qué plataforma de CI usan más hoy: GitHub, GitLab o Azure DevOps? ¿Los templates ya existen o hay que construirlos desde cero?
2. ¿Despliegan con GitOps (ArgoCD/Flux) o por push desde el pipeline?
3. ¿Cómo gestionan hoy el acceso de los pipelines a las nubes? ¿Ya usan OIDC?
4. ¿Cómo es el equipo de plataforma y con cuántos equipos de desarrollo trabajan?
5. ¿Qué haría exitoso a quien tome este rol en los primeros 3 meses? (Útil porque el contrato es a plazo fijo por 3 meses.)
