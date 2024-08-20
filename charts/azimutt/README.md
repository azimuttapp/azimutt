# azimutt

Explore and optimize any database

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

This chart is used to deploy Azimutt on Kubernetes.

## Requirements

- helm-docs:

    ```shell
    brew install norwoodj/tap/helm-docs
    ```

## How to use

Before using the Helm chart, please run the following commands:

```bash
# Create a namespace named azimutt
kubectl create ns azimutt

# Create a key that will be used for encryption
# Learn more here: https://github.com/azimuttapp/azimutt/blob/main/INSTALL.md#environment-variables
kubectl create secret generic azimutt-secret-key-base --from-literal=key=$(openssl rand -base64 48) -n azimutt
```

Once done, you will need to clone the repository and run the following command from the `charts/azimutt` folder:

```bash
helm install azimutt . --namespace azimutt
```

You should see two new pods appear:

1. The Azimutt server
2. A PostgreSQL database

If you want to use an external PostgreSQL database, you simply need to modify the `values.yaml` by disabling `postgresql.enabled` and updating the connection string.

**Note**: This Helm chart is not versioned and does not include an ingress configuration. You will need to add one yourself.

## Roadmap

- Version and publish the Helm chart
- Enhance environment variable configuration
- Add support for multiple ingress configurations

## Update documentation

To update documentation, please run the following command :

```bash
helm-docs --chart-search-root=. --template-files=README.md.gotmpl
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql(postgresql) | 15.5.23 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| azimutt.affinity | object | `{}` | Affinity rules for pod scheduling. |
| azimutt.autoscaling.enabled | bool | `false` | Enables horizontal pod autoscaling. |
| azimutt.autoscaling.maxReplicas | int | `5` | Maximum number of replicas for autoscaling. |
| azimutt.autoscaling.minReplicas | int | `1` | Minimum number of replicas for autoscaling. |
| azimutt.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage for autoscaling. |
| azimutt.configuration.auth.github.enabled | bool | `false` | Enables GitHub authentication. |
| azimutt.configuration.auth.github.sso_secret_name | string | `"azimutt-auth-secret"` | Name of the Kubernetes secret containing GitHub SSO credentials. |
| azimutt.configuration.auth.password.enabled | bool | `true` | Enables password-based authentication. |
| azimutt.configuration.database.enable_ssl | string | `"false"` | Whether to enable SSL for the database connection. |
| azimutt.configuration.database.pool_size | int | `10` | The size of the database connection pool. |
| azimutt.configuration.database.url | string | `"postgresql://postgres:MY_SUPER_PASSWORD@azimutt-postgresql:5432/postgres"` | The database connection URL. |
| azimutt.configuration.database.use_ipv6 | string | `"false"` | Whether to use IPv6 for the database connection. |
| azimutt.configuration.email.contact_email | string | `"contact@azimutt.app"` | Contact email address. |
| azimutt.configuration.email.enabled | bool | `false` | Enables email notifications. |
| azimutt.configuration.email.enterprise_support_email | string | `"contact@azimutt.app"` | Enterprise support email address. |
| azimutt.configuration.email.gmail.access_token_secret_name | string | `"azimutt-email-secret"` | The name of the Kubernetes secret containing the Gmail access token. |
| azimutt.configuration.email.gmail.enabled | bool | `false` | Enables Gmail for sending emails. |
| azimutt.configuration.email.mailgun.api_key_secret_name | string | `"azimutt-email-secret"` | The name of the Kubernetes secret containing the Mailgun API key. |
| azimutt.configuration.email.mailgun.base_url | string | `""` | The base URL for the Mailgun API. |
| azimutt.configuration.email.mailgun.domain | string | `""` | The Mailgun domain to use. |
| azimutt.configuration.email.mailgun.enabled | bool | `false` | Enables Mailgun for sending emails. |
| azimutt.configuration.email.sender_email | string | `"contact@azimutt.app"` | Email address used as the sender. |
| azimutt.configuration.email.smtp.credentials_secret_name | string | `"azimutt-email-secret"` | The name of the Kubernetes secret containing SMTP credentials. |
| azimutt.configuration.email.smtp.enabled | bool | `false` | Enables SMTP for sending emails. |
| azimutt.configuration.email.smtp.port | string | `""` | The SMTP relay port. |
| azimutt.configuration.email.smtp.relay | string | `""` | The SMTP relay host. |
| azimutt.configuration.email.support_email | string | `"contact@azimutt.app"` | Support email address. |
| azimutt.configuration.extraEnv | list | `[]` | Add extra environment variables for the container. |
| azimutt.configuration.license.enabled | bool | `false` | Enables license management. |
| azimutt.configuration.server.host | string | `"localhost"` | The host on which the server will run. |
| azimutt.configuration.storage | object | `{"s3":{"bucket":"","enabled":false,"folder":"","host":"","region":"eu-west1","use_key":false}}` | More info at https://github.com/azimuttapp/azimutt/blob/main/INSTALL.md |
| azimutt.configuration.storage.s3.bucket | string | `""` | The S3 bucket name. |
| azimutt.configuration.storage.s3.enabled | bool | `false` | Enables S3 storage. |
| azimutt.configuration.storage.s3.folder | string | `""` | The folder in the S3 bucket. |
| azimutt.configuration.storage.s3.host | string | `""` | The S3 host endpoint. |
| azimutt.configuration.storage.s3.region | string | `"eu-west1"` | The S3 region. |
| azimutt.configuration.storage.s3.use_key | bool | `false` | Whether to use a key for S3 access. |
| azimutt.fullnameOverride | string | `""` | Override the full name of the deployment. |
| azimutt.image.pullPolicy | string | `"Always"` | The policy for pulling the Docker image. "Always" means always pull the latest version. |
| azimutt.image.repository | string | `"ghcr.io/azimuttapp/azimutt"` | The Docker image repository to use. |
| azimutt.image.tag | string | `"main"` | The tag of the Docker image. Defaults to Chart.appVersion if not specified. |
| azimutt.imagePullSecrets | list | `[]` | Specify an array of image pull secrets to be used for private Docker registries. |
| azimutt.nameOverride | string | `""` | Override the name of the deployment. |
| azimutt.nodeSelector | object | `{}` | Node selector for pod assignment. |
| azimutt.podAnnotations | object | `{}` | Annotations to add to the pods. |
| azimutt.podSecurityContext | object | `{}` | Security context for the pod. |
| azimutt.replicaCount | int | `1` | Number of replicas for the application. |
| azimutt.resources.limits | object | `{"cpu":"1","memory":"512Mi"}` | Resource limits for the container. |
| azimutt.resources.requests | object | `{"cpu":"0.2","memory":"156Mi"}` | Resource requests for the container. |
| azimutt.securityContext | object | `{}` | Security context for the container. |
| azimutt.service.port | int | `4000` | The port the service will expose. |
| azimutt.service.type | string | `"ClusterIP"` | The type of Kubernetes service to create. |
| azimutt.serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| azimutt.serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| azimutt.serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template. |
| azimutt.tolerations | list | `[]` | Tolerations for pod scheduling. |
| postgresql.enabled | bool | `true` | Enables the deployment of a PostgreSQL database. |
| postgresql.global.postgresql.auth.password | string | `"MY_SUPER_PASSWORD"` | The password for the PostgreSQL superuser. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)