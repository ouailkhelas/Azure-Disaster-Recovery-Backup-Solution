# Azure Site Recovery Configuration Guide

## Overview
Azure Site Recovery provides disaster recovery capabilities by replicating VMs to a secondary region and enabling failover during outages.


## Section 1: Understanding Site Recovery
**RTO :** How long until system is back online
- Backup-only: 4-24 hours (restore from snapshot)
- Site Recovery: 15-30 minutes (instant failover)

**RPO :** How much data can be lost
- Backup-only: 1 day (daily backup)
- Site Recovery: 5-15 minutes (continuous replication)

## Section 2: Enable Site Recovery
### Step 1: Access Site Recovery in Portal
1. Go to **Azure Portal**
2. Search for **Recovery Services Vault**
3. Select vault created by Bicep
4. In left menu, click **Site Recovery**

### Step 2: Set Up Protection Source
1. Click **Prepare Infrastructure**
2. Select:
   - **Source location:** Primary region (e.g., East US)
   - **Where are your machines located?** Azure

### Step 3: Configure Target
1. **Target location:** Secondary region (e.g., West US)
2. **Target subscription:** Same as source
3. **Target resource group:** Create new or select existing
4. **Target network:** Create or use existing VNet

### Step 4: Select Replication Policy
1. Choose **Replication Policy:**
   - **Default:** 4-hour recovery points
   - **Custom:** Configure your own
2. Define:
   - **RPO (minutes):** 5, 15, or 30 minutes
   - **Crash-consistent:** App-consistent snapshots
3. Create policy

---

## Section 3: Enable Replication for VM

### Step 1: Select VM to Protect
1. **Site Recovery** → **Replicated items** → **+ Replicate**
2. **Source:**
   - Machine type: Azure Virtual Machine
   - Source location: Primary region

### Step 2: Configure Replication Settings
1. **Source VM:** Select your VM (dr-vm-primary-xxxxx)
2. **Target location:** Secondary region
3. **Target subscription:** Same subscription
4. **Target resource group:** Create new
5. **Failover resource group:** Where VM will launch on failover

### Step 3: Compute & Network
1. **VM Size:**
   - Recommended: Same as source
   - Can downsize to reduce cost
2. **Network Interface:**
   - Assign target NIC
   - Select private/public IP assignment
3. **Target Network:** Select secondary region VNet
4. **Subnet:** Choose subnet in target VNet

### Step 4: Enable Replication
1. Review settings
2. Click **Enable Replication**
3. Monitor job in **Site Recovery jobs**

### Monitor Replication Progress
1. **Site Recovery** → **Replicated items**
2. View replication health
3. Check:
   - **Status:** Health of replication
   - **RPO:** Current recovery point age
   - **Replicated disks:** Completion percentage
---

## Section 4: Configure Failover Settings
### Test Failover
1. **Replicated items** → Select VM
2. Click **Test failover**
3. Configure:
   - **Recovery point:** Latest or specific point
   - **Azure virtual network:** Test network
5. VM launches in test network
6. Validate applications work
7. Click **Clean up test failover** when done

### Planned Failover (Scheduled)
For maintenance windows or expected downtime:

1. **Replicated items** → Select VM
2. Click **Planned failover**
3. **Shutdown machine:** Yes 
5. VM gracefully shuts down, then starts in recovery region
6. Data loss: ZERO
7. Downtime: 5-15 minutes

### Unplanned Failover (Emergency)
For unexpected outages:

1. **Replicated items** → Select VM
2. Click **Failover**
3. Choose recovery point:
   - **Latest:** Most recent replica
   - **Latest processed:** Last known good
4. Click **OK**
5. VM starts in recovery region
6. May lose some data (minutes of transactions)
