# t2sworkshop

Participants learned how to set up a fully automated, secure CI/CD pipeline for deploying a Flask web application to Azure using **GitHub Actions** and **passwordless authentication via Federated Identity**.

## Key Topics Covered
- Creating and configuring a GitHub repository
- Setting up Azure resources:
  - User Assigned Managed Identity
  - Azure Blob Storage for Terraform state
  - Azure Container Registry (ACR)
  - App Service and Service Plan (from terraform)
- Configuring GitHub Secrets for secure integration
- Writing and deploying:
  - `Dockerfile`
  - `app.py` (Flask application)
  - `main.tf` (Terraform configuration)
  - GitHub Actions workflow (`deploy.yml`)
- **Passwordless authentication using OIDC federation** between GitHub and Azure
- Secure infrastructure and app deployment using Infrastructure as Code (IaC)

This workshop showcased best practices for modern DevOps workflows with **Terraform**, **containerization**, and **secure CI/CD pipelines** on Azure.

# Instruction
## 1. Create Free GitHub Account
    - Write down your user name
    - Create empty repo with README.md file
    - write down repo name

## 2. Log into Azure Account
    - Find your Resource Group



## 3. Managed Identity
    - Create User Assigned Managed Identity (in your Resource Group)
    - <your-managed-Identity> -> Settings -> Federated credentials -> Add Credential:
        - Federated credential scenario = GitHub Actions deploying...
        - Organization = YOUR GH USERNAME
        - Repository = YOUR GH REPO NAME
        - Entity = Branch
        - Branch = main
        - Name credentials-name
        
    - Go to your Resource Group -> Access control (IAM) -> Add role assignment -> Privileged administrator roles -> Contributor -> Managed identity -> Your MI.

## 4. Create Blob
    - Create Azure Storage Account (for tfstate)
    - In Azure Storage Account create blob named tfstate
    - In Your Storage Account -> Access Control (IAM) -> Add+ -> Add role assignment -> Storage Blob Data Contributor -> Managed Idenity (+Select Member) -> your managed idenity

## 5. ACR
    - in your RG create "Container registries"
    - provide name, rest default -> create
    - In ACR check in Admin User
    - In Your ACR -> Access Control (IAM) -> Add+ -> Add role assignment -> AcrPush -> Managed Idenity (+Select Member) -> your managed idenity

## 6. GH Secrets
    - go to your GH Repo
    - Settings
    - Security / secrets and variables / actions
    - new repository Secret (and create with name:value)
        - ACR_LOGIN_SERVER (from your ACR overview)
        - AZURE_CLIENT_ID (from your MI overview)
        - AZURE_SUBSCRIPTION_ID (from your MI overview)
        - AZURE_TENANT_ID (from your MI Settings -> Properties)
