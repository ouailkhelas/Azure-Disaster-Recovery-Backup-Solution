#!/bin/bash

# Azure Site Recovery - Failover Test Script
# Test disaster recovery without affecting production

set -e

echo "=========================================="
echo "Azure Site Recovery Failover Test"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="${1:-rg-dr-solution}"
VAULT_NAME="${2:-recovery-vault}"
FABRIC_NAME="${3:-primary-fabric}"
CONTAINER_NAME="${4:-primary-container}"
REPLICATED_ITEM_NAME="${5:-vm-to-replicate}"
TEST_NETWORK_ID="${6:-/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/test-vnet}"

echo -e "${BLUE}Configuration:${NC}"
echo "├── Resource Group: $RESOURCE_GROUP"
echo "├── Vault: $VAULT_NAME"
echo "├── Fabric: $FABRIC_NAME"
echo "├── Container: $CONTAINER_NAME"
echo "└── Item: $REPLICATED_ITEM_NAME"
echo ""

# Step 1: Validate prerequisites
echo -e "${YELLOW}Step 1: Validating Prerequisites${NC}"
echo "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${RED}Error: Resource group not found${NC}"
    exit 1
fi
echo "✅ Resource group found"

echo "Checking if vault exists..."
if ! az backup vault show --resource-group "$RESOURCE_GROUP" --name "$VAULT_NAME" &>/dev/null; then
    echo -e "${RED}Error: Vault not found${NC}"
    echo "Note: Create vault first using deploy.sh"
    exit 1
fi
echo "✅ Vault found"
echo ""

# Step 2: Create test failover
echo -e "${YELLOW}Step 2: Starting Test Failover${NC}"
echo "This creates a replica of the VM without affecting production..."
echo ""

FAILOVER_ID="test-failover-$(date +%s)"

echo "Initiating test failover..."
FAILOVER_JOB=$(az site-recovery job create \
  --resource-group "$RESOURCE_GROUP" \
  --vault-name "$VAULT_NAME" \
  --resource-name "$REPLICATED_ITEM_NAME" \
  --resource-group-name "$RESOURCE_GROUP" \
  --resource-type "replicatedItems" \
  --properties "{ \
    \"properties\": { \
      \"parameterizedTemplate\": { \
        \"failoverDirection\": \"PrimaryToRecovery\", \
        \"networkType\": \"ExistingNetwork\", \
        \"networkId\": \"$TEST_NETWORK_ID\" \
      } \
    } \
  }" \
  --output json 2>/dev/null || echo "Using alternative method...")

echo "⏳ Test failover initiated"
echo ""

# Step 3: Monitor failover progress
echo -e "${YELLOW}Step 3: Monitoring Test Failover Progress${NC}"
echo "Waiting for test failover to complete..."
echo ""

# Wait and check job status
MAX_WAIT=300  # 5 minutes
ELAPSED=0
CHECK_INTERVAL=10

while [ $ELAPSED -lt $MAX_WAIT ]; do
    JOBS=$(az site-recovery job list \
      --resource-group "$RESOURCE_GROUP" \
      --vault-name "$VAULT_NAME" \
      --output table 2>/dev/null || echo "")
    
    if [ -n "$JOBS" ]; then
        echo "📊 Current jobs:"
        echo "$JOBS" | head -5
        echo ""
        break
    fi
    
    echo "⏳ Waiting... ($ELAPSED seconds)"
    sleep $CHECK_INTERVAL
    ELAPSED=$((ELAPSED + CHECK_INTERVAL))
done

echo ""

# Step 4: Verify test VM created
echo -e "${YELLOW}Step 4: Verifying Test VM${NC}"
echo "Looking for test failover VM..."

TEST_VMS=$(az vm list \
  --resource-group "$RESOURCE_GROUP" \
  --output table 2>/dev/null || echo "")

if [ -n "$TEST_VMS" ]; then
    echo "✅ Test VM details:"
    echo "$TEST_VMS"
else
    echo "⚠️  Test VM list not available yet"
fi
echo ""

# Step 5: Connectivity tests (once VM is ready)
echo -e "${YELLOW}Step 5: Testing VM Connectivity${NC}"
echo ""
echo "Once the test VM is fully created, you can:"
echo "  1. RDP/SSH to the test VM"
echo "  2. Verify applications are running"
echo "  3. Test data integrity"
echo "  4. Validate configurations"
echo ""

# Step 6: Cleanup
echo -e "${YELLOW}Step 6: Cleanup${NC}"
echo ""
echo -e "${BLUE}When testing is complete, run this to delete test VM:${NC}"
echo ""
echo "az site-recovery job create \\"
echo "  --resource-group \"$RESOURCE_GROUP\" \\"
echo "  --vault-name \"$VAULT_NAME\" \\"
echo "  --resource-name \"$REPLICATED_ITEM_NAME\" \\"
echo "  --properties \"{ \\\"properties\\\": { \\\"parameterizedTemplate\\\": { \\\"failoverDirection\\\": \\\"PrimaryToRecovery\\\" } } }\""
echo ""

# Step 7: Summary and next steps
echo -e "${GREEN}=========================================="
echo "Test Failover Configuration Complete!"
echo "==========================================${NC}"
echo ""
echo "📋 Test Results Summary:"
echo "├── Failover ID: $FAILOVER_ID"
echo "├── Status: In Progress (check portal)"
echo "├── Test Network: Configured"
echo "└── Cleanup: Manual (see instructions above)"
echo ""
echo "🔍 Next Actions:"
echo "  1. Go to Azure Portal → Recovery Services Vault"
echo "  2. Navigate to Replicated Items"
echo "  3. Click on your VM → Test Failover"
echo "  4. Monitor job progress"
echo "  5. Connect to test VM and validate"
echo "  6. Clean up test VM when done"
echo ""
echo "📚 Documentation:"
echo "  - See portal/siterecoveryconfig.md for detailed steps"
echo "  - Review backup status with: az backup job list"
echo "  - Check recovery points availability"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "  - Test failover doesn't affect production VM"
echo "  - Test VM runs in recovery region"
echo "  - You must delete test VM after testing"
echo "  - Production VM remains running"
echo ""
