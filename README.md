# Azure Disaster Recovery & Backup Solution

A comprehensive infrastructure-as-code project for implementing disaster recovery and backup protection for Azure VMs using Bicep, Azure Backup, and Azure Site Recovery.

## 🛡️Architecture Overview

```
┌──────────────────────────┐
│   PRIMARY REGION         │
│     (East US)            │
│                          │
│  ┌────────────────────┐  │
│  │   Production VM    │  │
│  └────────┬───────────┘  │
└───────────┼───────────────┘
            │
    ┌───────┴────────┐
    │                │
    ▼                ▼
DAILY SNAPSHOTS   CONTINUOUS REPLICATION
(Azure Backup)    (Site Recovery)
    │                │
    ▼                ▼
RECOVERY VAULT    REPLICA VM (Secondary)
    │                │
    │                ▼
    │        ┌──────────────────────────┐
    │        │   SECONDARY REGION       │
    │        │     (West US)            │
    │        │                          │
    │        │  ┌────────────────────┐  │
    │        │  │   Standby VM       │  │
    │        │  └────────────────────┘  │
    │        └──────────────────────────┘
    │                │
    └────────────┬───┘
                 │
                 ▼
           [FAILOVER]
         On Demand or
          Automatic
```

## 🚀 Data Flow

**Backup Flow:**
1. VM generates data changes throughout the day
2. Azure Backup agent captures snapshots
3. Snapshots stored in Recovery Services Vault
4. Daily backup runs at configured time (2 AM UTC)
5. Recovery points maintained per retention policy
6. 30 days of recovery points available

**Replication Flow:**
1. VM runs in primary region (East US)
2. Azure Site Recovery continuously replicates disks
3. Replica VMs maintained in secondary region (West US)
4. Every 5-15 minutes, replication syncs
5. On failover, replica VM is activated
6. Traffic redirects to recovery region

**Recovery Flow:**
 RTO: 10-15 minutes, RPO: 5-15 minutes


## Quick Start (4 Steps)

### ✅ Step 1: Deploy Infrastructure
```bash
cd cloudshell/
bash deploy.sh
```

**Creates:**
- Resource Group
- Virtual Network (10.0.0.0/16)
- Subnet (10.0.1.0/24)
- Windows Server 2019 VM
- Public IP & Network Interface
- Network Security Group (RDP/SSH enabled)
- Recovery Services Vault
- Daily Backup Policy
- Log Analytics workspace (optional)
- Key Vault for encryption

### ✅ Step 2: Configure Backups
Follow `portal/backupconfig.md`:
- Understand backup jobs
- View recovery points
- Trigger on-demand backup
- Monitor backup health
- Configure retention policies

### ✅ Step 3: Configure Site Recovery
Follow `portal/siterecoveryconfig.md`:
- Enable Site Recovery on vault
- Select VM for protection
- Configure secondary region
- Set up replication policy
- Enable continuous replication

### ✅ Step 4: Test Failover
```bash
bash cloudshell/failovertest.sh
```

**Performs:**
- Creates test failover VM
- Launches in recovery region
- Validates connectivity
- Tests application functionality
- Cleans up test VM

## Technologies Used

| Technology | Purpose |
|-----------|---------|
| **Bicep** | Infrastructure as Code |
| **Azure CLI** | Deployment & management |
| **Azure Backup** | Snapshots & point-in-time recovery |
| **Azure Site Recovery** | Continuous replication & failover |
| **Recovery Services Vault** | Centralized management |
| **Azure Key Vault** | Encryption key management |


### Recovery Scenarios

1. **Single File Loss:**
   - Use Backup → File Recovery
   - No need to failover entire VM

2. **VM Corrupted:**
   - Use Backup → Restore to new VM
   - Creates clean copy from snapshot

3. **Regional Outage:**
   - Use Site Recovery → Failover
   - VM activates in secondary region

4. **Ransomware Attack:**
   - Use Backup → Restore from clean point
   - Or failover to pre-infection state
