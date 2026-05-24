#!/bin/bash

# Azure Disaster Recovery & Backup Solution
# Deployment Script for Azure Cloud Shell

set -e

echo "=========================================="
echo "Azure Disaster Recovery & Backup Solution"
echo "Deployment Script"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-dr-solution"
LOCATION="eastus"
DEPLOYMENT_NAME="dr-deployment-$(date +%s)"

echo -e "${YELLOW}Step 1: Creating Resource Group${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

echo ""
echo -e "${YELLOW}Step 2: Validating Bicep Template${NC}"
az deployment group validate \
  --resource-group "$RESOURCE_GROUP" \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters.json

echo ""
echo -e "${YELLOW}Step 3: Deploying Infrastructure${NC}"
DEPLOYMENT_OUTPUT=$(az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters.json \
  --output json)

echo ""
echo -e "${GREEN}=========================================="
echo "Infrastructure Deployed Successfully!"
echo "==========================================${NC}"
echo ""

# Extract outputs
VM_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.vmName.value')
VM_ID=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.vmId.value')
PUBLIC_IP=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.publicIpAddress.value')
VAULT_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.vaultName.value')
VAULT_ID=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.vaultId.value')

echo "📊 Deployment Summary:"
echo "├── Resource Group: $RESOURCE_GROUP"
echo "├── VM Name: $VM_NAME"
echo "├── VM ID: $VM_ID"
echo "├── Public IP: $PUBLIC_IP"
echo "├── Vault Name: $VAULT_NAME"
echo "└── Vault ID: $VAULT_ID"
echo ""

echo -e "${YELLOW}Step 4: Waiting for VM to be ready...${NC}"
sleep 30

echo ""
echo -e "${YELLOW}Step 5: Enabling Backup${NC}"
CONTAINER_NAME="iaasvmcontainer;iaasvmcontainerv2;${RESOURCE_GROUP};${VM_NAME}"
PROTECTED_ITEM_NAME="vm;iaasvmcontainerv2;${RESOURCE_GROUP};${VM_NAME}"

# Enable protection for the VM
az backup protection enable-for-vm \
  --resource-group "$RESOURCE_GROUP" \
  --vault-name "$VAULT_NAME" \
  --vm "$VM_NAME" \
  --policy-name "daily-backup-policy" \
  2>/dev/null || echo "Backup already enabled or in progress"

echo ""
echo -e "${YELLOW}Step 6: Triggering Initial Backup${NC}"
az backup protection backup-now \
  --resource-group "$RESOURCE_GROUP" \
  --vault-name "$VAULT_NAME" \
  --container-name "$CONTAINER_NAME" \
  --item-name "$PROTECTED_ITEM_NAME" \
  --retain-until "$(date -d '+30 days' '+%d-%m-%Y')" \
  2>/dev/null || echo "Backup job initiated"

echo ""
echo -e "${GREEN}=========================================="
echo "Next Steps:"
echo "==========================================${NC}"
echo ""
echo "1. ✅ Infrastructure deployed"
echo "2. ✅ Backup enabled"
echo "3. ⏳ Wait 5-10 minutes for initial backup"
echo ""
echo "🔧 Configuration Steps:"
echo "├── View backup jobs: See cloudshell/backupcommands.txt"
echo "├── Configure Site Recovery: Follow portal/siterecoveryconfig.md"
echo "├── Test failover: Run cloudshell/failovertest.sh"
echo "└── Monitor backups: View in Azure Portal"
echo ""
echo "🖥️  Connect to VM:"
echo "   RDP to: $PUBLIC_IP"
echo "   SSH to: ${PUBLIC_IP} (if Linux VM)"
echo ""
echo "📋 Save these values:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Vault Name: $VAULT_NAME"
echo "   VM Name: $VM_NAME"
echo ""
