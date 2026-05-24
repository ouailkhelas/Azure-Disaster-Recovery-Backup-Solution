# Azure Site Recovery Configuration Guide

## Overview
Azure Site Recovery provides disaster recovery capabilities by replicating VMs to a secondary region and enabling failover during outages.

## Key Differences: Backup vs Site Recovery

| Aspect | Azure Backup | Azure Site Recovery |
|--------|--------------|-------------------|
| **Purpose** | Data protection | Disaster recovery |
| **Recovery Time** | Hours/Days (RTO) | Minutes/Seconds (RTO) |
| **Data Loss** | Minutes (RPO) | Seconds (RPO) |
| **Target** | Same or different region | Different region only |
| **Continuous Replication** | No (scheduled) | Yes (real-time) |
| **Cost** | Lower | Higher |

---

## Section 1: Understanding Site Recovery

### RTO & RPO Explained

**RTO (Recovery Time Objective):** How long until system is back online
- Backup-only: 4-24 hours (restore from snapshot)
- Site Recovery: 15-30 minutes (instant failover)

**RPO (Recovery Point Objective):** How much data can be lost
- Backup-only: 1 day (daily backup)
- Site Recovery: 5-15 minutes (continuous replication)

### Replication Architecture
```
Primary Region (East US)
    ↓ (Continuous Replication)
┌─────────────────┐
│   VM Replica    │
│   Snapshots     │
│   Disk Replicas │
└─────────────────┘
    ↓ (On Failover)
Secondary Region (West US)
┌─────────────────┐
│   Active VM     │
│   (In Recovery) │
└─────────────────┘
```

---

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
3. Click **Next**

### Step 3: Configure Target
1. **Target location:** Secondary region (e.g., West US)
2. **Target subscription:** Same as source
3. **Target resource group:** Create new or select existing
4. **Target network:** Create or use existing VNet
5. Click **Next**

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
3. Click **Next**

### Step 2: Configure Replication Settings
1. **Source VM:** Select your VM (dr-vm-primary-xxxxx)
2. **Target location:** Secondary region
3. **Target subscription:** Same subscription
4. **Target resource group:** Create new
5. **Failover resource group:** Where VM will launch on failover
6. Click **Next**

### Step 3: Compute & Network
1. **VM Size:**
   - Recommended: Same as source
   - Can downsize to reduce cost
2. **Network Interface:**
   - Assign target NIC
   - Select private/public IP assignment
3. **Target Network:** Select secondary region VNet
4. **Subnet:** Choose subnet in target VNet
5. Click **Next**

### Step 4: Enable Replication
1. Review settings
2. Click **Enable Replication**
3. Monitor job in **Site Recovery jobs**

### Monitor Replication Progress
1. **Site Recovery** → **Replicated items**
2. View replication health:
   - Healthy (green): Replicating normally
   - Warning (yellow): Minor issues
   - Critical (red): Replication failed
3. Check:
   - **Status:** Health of replication
   - **RPO:** Current recovery point age
   - **Replicated disks:** Completion percentage

---

## Section 4: Configure Failover Settings

### Test Failover (Non-Destructive)
Test recovery without affecting production:

1. **Replicated items** → Select VM
2. Click **Test failover**
3. Configure:
   - **Recovery point:** Latest or specific point
   - **Azure virtual network:** Test network
4. Click **OK**
5. VM launches in test network
6. Validate applications work
7. Click **Clean up test failover** when done

### Planned Failover (Scheduled)
For maintenance windows or expected downtime:

1. **Replicated items** → Select VM
2. Click **Planned failover**
3. **Shutdown machine:** Yes (recommended)
4. Click **OK**
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

---

## Section 5: Post-Failover Actions

### Update DNS
After failover, point traffic to new region:
1. Update DNS records to recovery VM IP
2. Allow 5-10 minutes for propagation
3. Test connectivity from clients

### Validate Failover VM
1. Connect to failover VM (RDP/SSH)
2. Verify:
   - OS starts normally
   - Applications launch
   - Database/services running
   - Disk space available
   - Network connectivity
3. Review event logs for errors
4. Test business-critical functions

### Commit Failover
Make failover permanent:
1. **Replicated items** → Select failover VM
2. Click **Commit**
3. This finalizes failover
4. Original VM is deprotected

### Failback (Return to Primary)
Return to original region after recovery:
1. Requires replication in reverse direction
2. Original region comes online
3. Fail back from recovery region
4. Reconfigure applications to use primary

---

## Section 6: Failover Scenarios

### Scenario 1: Test Failover
**Goal:** Verify recovery readiness without impact

```
Day 1:
├── 10:00 AM: Initiate test failover
├── 10:10 AM: Test VM launches in recovery region
├── 10:15 AM: Validate applications running
├── 10:30 AM: Perform business testing
└── 11:00 AM: Clean up test VM

Outcome: Zero downtime, zero data loss
```

**CLI Command:**
```bash
az site-recovery protected-item test-failover \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --fabric-name "primary-fabric" \
  --container-name "primary-container" \
  --protected-item-name "vm-to-protect"
```

### Scenario 2: Regional Outage
**Goal:** Failover critical VMs to secondary region

```
17:45: Primary region (East US) goes down
  └── VM stops responding
  └── All services offline

17:50: Operations team initiates unplanned failover
  ├── Launch replica VM in recovery region
  ├── Boot time: ~5 minutes
  └── RTO: 5-10 minutes total

18:00: Applications online in recovery region
  ├── Update DNS to recovery region
  ├── Redirect traffic
  └── RPO: 5-minute data loss (acceptable)

Data Loss: Last 5-15 minutes (acceptable for most)
Downtime: 10-15 minutes
```

### Scenario 3: Ransomware Attack
**Goal:** Restore from clean backup/snapshot

```
Monday 14:00: Ransomware detected
  └── Immediately isolate VM from network

Monday 15:00: Recover from backup
  ├── Access recovery point from 6 hours prior
  ├── Create new VM from clean snapshot
  ├── Verify no malware present
  └── Deploy restored VM

Tuesday 09:00: Business operations restored
  └── Clean system, zero compromise

Data Loss: ~6 hours (pre-incident)
```

---

## Section 7: Monitoring Site Recovery

### Health Status
1. **Site Recovery** → **Replicated items**
2. Check each VM:
   - **Status:** Protected, Warning, Critical
   - **Replication health:** OK, At risk
   - **RPO:** Age of latest replica
   - **Last sync:** When replica last updated

### Key Metrics to Monitor
- **Replication Latency:** <5 minutes (optimal)
- **Churn Rate:** Amount of data changing (affects RPO)
- **Recovery Points:** Should have 24+ points available
- **Job Status:** No failed replication jobs

### Alerts to Configure
1. **Site Recovery alerts** → **Configure notifications**
2. Enable alerts for:
   - Replication health degradation
   - RPO exceeded (>1 hour)
   - Job failures
3. Set notification email

---

## Section 8: Cost Considerations

### Site Recovery Pricing
- **Per protected instance:** $0.15 USD/day per VM
- **Outbound data transfer:** $0.02-0.05 USD/GB
- **Recovery test:** Included in protection cost

### Cost Optimization
1. **Bandwidth management:**
   - Throttle replication during business hours
   - Full replication after hours
2. **VM sizing:**
   - Downsize recovery VMs to reduce cost
   - Scale up on failover
3. **Storage:**
   - Use managed disks (cheaper)
   - Enable disk exclusion (skip large non-critical disks)

### Budget Estimate
For 10 VMs in Site Recovery:
- Daily cost: 10 × $0.15 = **$1.50/day**
- Monthly cost: **~$45/month**
- Yearly cost: **~$547/year**

---

## Section 9: Best Practices

✅ **DO:**
- Test failover quarterly
- Monitor RPO and RTO
- Document runbooks for each failover scenario
- Maintain network diagrams of both regions
- Keep secondary region resources updated
- Test failback procedures
- Monitor replication lag continuously
- Document recovery procedures

❌ **DON'T:**
- Forget to test failover before needed
- Keep outdated DNS/IPs in failover plans
- Disable monitoring in recovery region
- Store sensitive credentials in recovery plan
- Assume failover will work without testing
- Ignore replication health warnings
- Fail back without validation
- Skip documentation updates

---

## Section 10: Troubleshooting

### Replication Fails
**Error:** "Replication agent is not responsive"

**Solution:**
1. Check VM agent on source:
   ```bash
   # In source VM
   Get-Service waagent | fl  # Windows
   systemctl status walinuxagent  # Linux
   ```
2. Restart agent if stopped
3. Check network connectivity to Azure

### RPO Too High
**Issue:** Recovery point older than target

**Causes:**
- Network bandwidth limited
- High churn rate (lots of changes)
- Storage bottleneck

**Solution:**
1. Increase replication bandwidth
2. Exclude non-critical disks
3. Reduce retention period
4. Upgrade storage account tier

### Failover Takes Too Long
**Issue:** Recovery VM slow to start

**Solution:**
1. Pre-warm VM in recovery region
2. Maintain fully configured networks
3. Use larger VM size for faster boot
4. Test regularly to identify bottlenecks

---

## Section 11: Integration with Backup

### Layered Protection Strategy
```
Azure Backup (Daily snapshots)
    ↓ (30-day retention)
    
Azure Site Recovery (Continuous replication)
    ↓ (Real-time, to secondary region)
    
Geo-redundant Storage (Cross-region copies)
    ↓ (Automatic, 3 replicas minimum)
    
Local Snapshots (VM-level, hourly)
    └─ Complete protection against:
       - Data center failure
       - Regional outage
       - Ransomware
       - Application failure
```

### Recommended Approach
1. **For critical VMs:**
   - Enable both Backup AND Site Recovery
   - Backup: Point-in-time recovery (ransomware defense)
   - Site Recovery: Continuous recovery (outage response)

2. **For non-critical VMs:**
   - Backup only (cost-effective)
   - RPO: 1 day, RTO: 4-24 hours

---

## Section 12: Quick Commands

```bash
# List replicated items
az site-recovery fabric list \
  --resource-group "rg-dr-solution"

# Test failover
az site-recovery job create \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --properties "{...}"

# Monitor replication status
az monitor metrics list \
  --resource "/subscriptions/xxx/resourceGroups/rg-dr-solution/providers/Microsoft.RecoveryServices/vaults/recovery-vault-xxxxx"
```

---

## Summary
- Site Recovery enables instant failover to secondary region
- Continuous replication maintains 5-15 minute RPO
- Test failover quarterly without affecting production
- Combine with Backup for comprehensive protection
- Monitor RPO and replication health continuously
