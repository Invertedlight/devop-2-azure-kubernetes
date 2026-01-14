# Mercury Workflows Course Repo Changelog

## 2026-01-14

Based on the feedback in these threads:

<https://www.skool.com/kubecraft/cloud-course-phase-6?p=9dc9983d>

<https://www.skool.com/kubecraft/devops-os-part-2-question?p=0bfeb95b>

I have made the following modifications:

```git

diff --git a/phase-5-gitops/mercury-gitops/apps/base/customer1/ingress.yaml b/phase-5-gitops/mercury-gitops/apps/base/customer1/ingress.yaml
index 45c8817..d8f27d0 100644
--- a/phase-5-gitops/mercury-gitops/apps/base/customer1/ingress.yaml
+++ b/phase-5-gitops/mercury-gitops/apps/base/customer1/ingress.yaml
@@ -5,7 +5,7 @@ metadata:
   annotations:
     cert-manager.io/cluster-issuer: letsencrypt-prod
 spec:
-  ingressClassName: traefik
+  ingressClassName: traefik-traefik
   tls:
     - hosts:
         - customer1.mercury.mischavandenburg.net
diff --git a/phase-6-cnpg/gitops/apps/base/customer1/configmap.yaml b/phase-6-cnpg/gitops/apps/base/customer1/configmap.yaml
index 91c7930..a995313 100644
--- a/phase-6-cnpg/gitops/apps/base/customer1/configmap.yaml
+++ b/phase-6-cnpg/gitops/apps/base/customer1/configmap.yaml
@@ -7,6 +7,6 @@ data:
   N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS: "true"
   N8N_SECURE_COOKIE: "true"
   DB_TYPE: "postgresdb"
-  DB_POSTGRESDB_HOST: "customer1-db2-rw.customer1.svc.cluster.local"
+  DB_POSTGRESDB_HOST: "customer1-db1-rw.customer1.svc.cluster.local"
   DB_POSTGRESDB_PORT: "5432"
   DB_POSTGRESDB_DATABASE: "app"
```
