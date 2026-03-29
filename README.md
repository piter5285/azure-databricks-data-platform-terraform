# Azure Databricks Data Platform — Terraform

Production-ready Terraform repository implementing the full Data Lakehouse architecture on Azure Databricks with Unity Catalog, ADLS Gen2, private networking, and multi-environment support.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  DATA LAKEHOUSE                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  DATABRICKS  (No-Public-IP, VNet injection)         │   │
│  │  Notebook │ SQL Warehouse │ Delta Sharing │ ML      │   │
│  │  Structured Streaming │ dbt via JDBC/Warehouse      │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  UNITY CATALOG  (one metastore, all envs)                   │
│  source_{env} │ bronze_{env} │ silver_{env} │ gold_{env}    │
├─────────────────────────────────────────────────────────────┤
│  CLOUD STORAGE  (ADLS Gen2 — private endpoints)             │
│  Source Landing  │  Bronze  │  Silver  │  Gold              │
│  Raw files       │  Δ valid │  Δ clean │  Analytics         │
├─────────────────────────────────────────────────────────────┤
│  METADATA  —  Unity Catalog Metastore container             │
└─────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
├── global/                    # Unity Catalog Metastore (deployed once)
├── environments/
│   ├── dev/                   # Development environment
│   ├── prep/                  # Pre-production / staging
│   └── prod/                  # Production
└── modules/
    ├── networking/            # VNet, subnets, NSG, NAT Gateway, private DNS
    ├── storage/               # ADLS Gen2 + private endpoints
    ├── keyvault/              # Key Vault + private endpoint
    ├── databricks_workspace/  # Workspace + Access Connector + private endpoints
    ├── monitoring/            # Log Analytics + diagnostic settings
    ├── unity_catalog/         # Catalogs, schemas, grants, storage credentials
    ├── databricks_config/     # SQL Warehouse, clusters, policies, secret scopes
    ├── governance/            # Azure Policy tags, cost budgets, cluster tag enforcement
    └── data_classification/   # PII masking functions, ABAC policies, Confidential policy
```

## Key Production Features

| Feature | Implementation |
|---------|---------------|
| No Public IPs on clusters | `no_public_ip = true` (Secure Cluster Connectivity) |
| Private networking | VNet injection + private endpoints for all services |
| Outbound internet | NAT Gateway (static egress IP for allowlisting) |
| Secrets management | Azure Key Vault + Databricks secret scope |
| Data governance | Unity Catalog with environment-isolated catalogs, ABAC masking policies |
| Storage auth | Managed Identity via Access Connector (no keys) |
| Audit logging | Azure Monitor diagnostic settings → Log Analytics |
| IP restriction | Databricks IP Access Lists (optional) |
| Storage redundancy | LRS (dev) → ZRS (prep) → GZRS (prod) |

## Network Design

Each environment gets a fully isolated VNet:

| Subnet | CIDR (dev) | Purpose |
|--------|-----------|---------|
| `snet-databricks-public-*` | `10.1.1.0/24` | Databricks host subnet |
| `snet-databricks-private-*` | `10.1.2.0/24` | Databricks container subnet |
| `snet-private-endpoints-*` | `10.1.3.0/24` | Private endpoints |

| Environment | VNet CIDR |
|-------------|-----------|
| dev | `10.1.0.0/16` |
| prep | `10.2.0.0/16` |
| prod | `10.3.0.0/16` |

## Unity Catalog Layout

```
Metastore (global — shared across all workspaces)
├── source_dev     ← source_prep / source_prod
│   └── raw
├── bronze_dev     ← bronze_prep / bronze_prod
│   └── validated
├── silver_dev     ← silver_prep / silver_prod
│   └── cleansed
└── gold_dev       ← gold_prep / gold_prod
    ├── analytics
    └── reporting
```

## Governance Module

The `modules/governance/` module enforces cost and operational governance at both the Azure and Databricks layers.

### Azure-level controls

| Resource | Purpose |
|----------|---------|
| `azurerm_policy_assignment` | Enforces mandatory tags (`environment`, `project`, `cost_center`, `managed_by`, `owner`) on all resources |
| Tag inheritance policy | Propagates resource-group tags down to child resources automatically |
| `azurerm_consumption_budget_resource_group` | Monthly cost budget with configurable threshold alerts (e.g. 80 %, 100 %, 120 %) sent to budget alert emails |

### Databricks-level controls

| Resource | Purpose |
|----------|---------|
| `databricks_cluster_policy` | Fixes `environment` and `project` tags on all clusters; allowlists `cost_center`, `team`, `owner` tags |
| `databricks_workspace_conf` | Enforces token lifetimes and optional IP Access Lists |

### Variables

```hcl
module "governance" {
  source = "../../modules/governance"

  environment             = "dev"
  project_name            = "dataplatform"
  resource_group_id       = module.networking.resource_group_id
  databricks_workspace_id = module.databricks_workspace.workspace_id

  mandatory_tags          = ["environment", "project", "cost_center", "managed_by", "owner"]
  tag_policy_effect       = "Audit"       # or "Deny" for strict enforcement
  monthly_budget_amount   = 500
  budget_alert_thresholds = [80, 100, 120]
  budget_alert_emails     = ["platform-alerts@example.com"]
  allowed_cost_centers    = ["data-engineering", "data-science", "analytics", "platform"]
}
```

---

## Data Classification Module

The `modules/data_classification/` module deploys a full PII masking and data classification framework on top of Unity Catalog.

### How it works

1. A dedicated **governance catalog** (`governance_<env>`) with a `security` schema is created to host all masking functions.
2. Ten **SQL masking functions** are registered. Each function checks group membership via `is_member()` — privileged users (admin group, pii-access group) always see real values; everyone else sees the masked form.
3. A `pii-access` group is created. Add users who need unmasked access directly in the Databricks account console or Azure AD.
4. Functions are granted `EXECUTE` to all workspace users — the functions themselves enforce access control internally.

### Masking functions

| Function | Tag | Masked example |
|----------|-----|---------------|
| `mask_email` | `class.email_address` | `j***@***.com` |
| `mask_phone` | `class.phone_number` | `+** **** ***456` |
| `mask_name` | `class.name` | `J*** S***` |
| `mask_ssn` | `class.ssn` | `***-**-6789` |
| `mask_credit_card` | `class.credit_card` | `************1111` |
| `mask_date_of_birth` | `class.date_of_birth` | `1985-**-**` |
| `mask_ip_address` | `class.ip_address` | `192.168.*.*` |
| `hash_pii` | any `class.*` | SHA-256 hash (preserves joins) |
| `nullify_pii` | any `class.*` | `NULL` |
| `mask_sensitive` | `class.sensitive`, `class.confidential` | `[REDACTED]` |

### Confidential policy

`policy_confidential` is a **tag-driven unified masking policy**. Instead of assigning a specific function per column, you apply this single function to any confidential column and it automatically selects the correct masking based on the column's tag:

```sql
-- Meets condition (apply this function to columns where):
has_tag("class.name") OR has_tag("class.email_address") OR has_tag("class.phone_number")
```

| Column tag | Masking applied |
|------------|----------------|
| `class.name` | Initials only — `J*** S***` |
| `class.email_address` | Partial reveal — `j***@***.com` |
| `class.phone_number` | Last 3 digits — `+** **** ***456` |
| _(other)_ | Fallback — `[CONFIDENTIAL]` |

**Applying the policy to a table column:**

```sql
ALTER TABLE silver_dev.cleansed.customers
  ALTER COLUMN full_name
  SET MASK governance_dev.security.policy_confidential;

ALTER TABLE silver_dev.cleansed.customers
  ALTER COLUMN email
  SET MASK governance_dev.security.policy_confidential;
```

The function output is exposed via `module.data_classification.fn_policy_confidential`.

### Classification tags

| Tag | Meaning |
|-----|---------|
| `class.pii` | Personally Identifiable Information |
| `class.name` | Personal name |
| `class.email_address` | Email address |
| `class.phone_number` | Phone / mobile number |
| `class.ssn` | Social Security / national ID |
| `class.credit_card` | Payment card number (PAN) |
| `class.ip_address` | IP address |
| `class.date_of_birth` | Date of birth |
| `class.sensitive` | Sensitive business data (not PII) |
| `class.confidential` | Internal only — confidential |
| `class.public` | No masking required |

### Module instantiation

```hcl
module "data_classification" {
  source = "../../modules/data_classification"

  environment                      = "dev"
  project_name                     = "dataplatform"
  governance_catalog_storage_root  = "abfss://governance@<storage>.dfs.core.windows.net/"
  storage_credential_name          = module.unity_catalog.storage_credential_name

  admin_group_name                 = "databricks-admins"
  data_engineer_group_name         = "data-engineers"
  pii_access_group_name            = "pii-access"

  catalog_names = [
    module.unity_catalog.silver_catalog_name,
    module.unity_catalog.gold_catalog_name,
  ]
}
```

---

## Pre-requisites

1. Azure subscription with Owner/Contributor + User Access Administrator
2. [Terraform](https://www.terraform.io/downloads) >= 1.5
3. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
4. Databricks Premium plan (required for Unity Catalog)
5. Databricks account-level admin access

## Quick Start

### 1. Bootstrap Terraform state storage

```bash
# Run once — creates the storage account for tfstate
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
PROJECT="dataplatform"

az group create -n rg-tfstate-${PROJECT} -l westeurope
az storage account create \
  -n sttfstate${PROJECT} \
  -g rg-tfstate-${PROJECT} \
  --sku Standard_ZRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false
az storage container create -n tfstate --account-name sttfstate${PROJECT}
```

### 2. Deploy the global metastore (once per region)

```bash
cd global
cp backend.tf.example backend.tf       # edit with your storage account name
cp terraform.tfvars.example terraform.tfvars  # fill in your values

terraform init
terraform plan -out=global.tfplan
terraform apply global.tfplan

# Note the metastore_id output — you'll need it for each environment
terraform output metastore_id
```

### 3. Deploy an environment

```bash
cd environments/dev
cp backend.tf.example backend.tf
cp terraform.tfvars.example terraform.tfvars  # fill in metastore_id + storage names

terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

Or using Make:

```bash
make global-apply
make init ENV=dev && make plan ENV=dev && make apply ENV=dev
make init ENV=prep && make plan ENV=prep && make apply ENV=prep
make init ENV=prod && make plan ENV=prod && make apply ENV=prod
```

## Authentication

The Terraform run must authenticate to Azure. Options:

**Service Principal (CI/CD recommended):**
```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
```

**Azure CLI (local development):**
```bash
az login
az account set --subscription "<subscription-id>"
```

## dbt Connection

After deploying, configure your dbt profile using the SQL Warehouse JDBC output:

```yaml
# ~/.dbt/profiles.yml
dataplatform:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <workspace-url>.azuredatabricks.net
      http_path: /sql/1.0/warehouses/<warehouse-id>
      token: "{{ env_var('DBT_TOKEN') }}"
      catalog: gold_dev
      schema: analytics
```

## Adding a New Environment

1. Copy `environments/dev/` to `environments/<new-env>/`
2. Change `environment = "dev"` → `"<new-env>"` in `main.tf` locals
3. Update CIDR ranges in `variables.tf` (avoid overlaps with existing envs)
4. Create `backend.tf` from example with a unique state key
5. Create `terraform.tfvars` with environment-specific values
6. Run `terraform init && terraform apply`

## Providers

| Provider | Version |
|----------|---------|
| hashicorp/azurerm | ~> 3.110 |
| hashicorp/azuread | ~> 2.53 |
| databricks/databricks | ~> 1.52 |
