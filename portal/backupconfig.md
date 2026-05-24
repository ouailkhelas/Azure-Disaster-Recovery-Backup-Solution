# Azure Backup Configuration Guide

## Overview
This guide walks through configuring and managing Azure Backup for your VMs.

## Section 1: Understanding Backup Jobs

### What is a Backup Job?
A backup job is an automated or manual process that:
- Creates point-in-time copies of your VM disk
- Stores snapshots in the Recovery Services Vault
- Maintains retention policies
- Runs on a schedule or on-demand

### Backup Job Lifecycle
```
Scheduled → Running → Checking Consistency → Succeeded
                   ↓
            Failed (with error details)
```

---

## Section 2: Viewing and Managing Backup Jobs

### View Backup Jobs in Portal
1. Go to **Azure Portal** → **Recovery Services Vault**
2. Click on vault created by deployment
3. Under **Monitoring**, click **Backup Jobs**
4. View all recent backup operations:
   - Job name
   - Status (Running, Succeeded, Failed)
   - Duration
   - Type (Backup, Restore, etc.)

### View Backup Jobs via CLI
```bash
# List all backup jobs
az backup job list \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --output table

# View running jobs only
az backup job list \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --status Running \
  --output table

# View specific job details
az backup job show \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --name "job-id-here"
```

---

## Section 3: Backup Policies

### Default Policy: Daily Backup
Created by Bicep deployment:
- **Name:** daily-backup-policy
- **Schedule:** Daily at 2 AM UTC
- **Retention:**
  - Daily: 30 days
  - Weekly: 4 weeks (Sundays)
  - Monthly: 12 months (1st Sunday)
  - Yearly: 5 years (January 1st)

### Modify Backup Policy
1. Go to **Recovery Services Vault** → **Backup Policies**
2. Select **daily-backup-policy**
3. Click **Edit**
4. Adjust:
   - Schedule frequency
   - Retention duration
   - Recovery point retention
5. Click **Save**

### Create Custom Policy
1. **Backup Policies** → **Create Policy**
2. Set schedule (frequency, time)
3. Configure retention:
   - Daily retention: 1-180 days
   - Weekly retention: 1-520 weeks
   - Monthly retention: 1-120 months
   - Yearly retention: 1-10 years
4. Save policy
5. Assign to VM

---

## Section 4: Recovery Points

### What is a Recovery Point?
A recovery point is a point-in-time snapshot of your VM that you can restore from.

### View Recovery Points
1. Go to **Recovery Services Vault**
2. Click **Backup Items** → **Azure Virtual Machine**
3. Select your VM
4. Click **View all recovery points**
5. See list with:
   - Recovery point time
   - Type (crash-consistent, app-consistent)
   - Retention expiry date

### Recovery Point Types
- **Crash-Consistent:** Captures data in memory during snapshot (faster)
- **App-Consistent:** Application data consistency (slower, more reliable)

---

## Section 5: Triggering Backups

### Automatic Backup
Runs on schedule defined in policy (daily at 2 AM UTC by default)

### Manual/On-Demand Backup
1. **Recovery Services Vault** → **Backup Items**
2. Select VM
3. Click **Backup Now**
4. Select recovery point retention date
5. Click **OK**

**Via CLI:**
```bash
az backup protection backup-now \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --container-name "iaasvmcontainer;iaasvmcontainerv2;rg-dr-solution;dr-vm-primary-xxxxx" \
  --item-name "vm;iaasvmcontainerv2;rg-dr-solution;dr-vm-primary-xxxxx" \
  --retain-until "31-12-2024"
```

---

## Section 6: Restoring VMs

### Full VM Restore
1. **Recovery Services Vault** → **Backup Items**
2. Select your VM
3. Click **Restore VM**
4. Select recovery point
5. Choose restore options:
   - **Create New VM:** Restore to new VM
   - **Replace existing:** Overwrite original (risky)
6. Configure:
   - VM name
   - Resource group
   - Virtual network
   - Subnet
   - Public IP
7. Review and restore
8. Monitor job in **Backup Jobs**

### Restore from CLI
```bash
# Get recovery point name first
RECOVERY_POINT=$(az backup recoverypoint list \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --container-name "iaasvmcontainer;..." \
  --item-name "vm;..." \
  --output table | head -2 | tail -1 | awk '{print $1}')

# Restore VM
az backup restore restore-azure-vm \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --container-name "iaasvmcontainer;..." \
  --item-name "vm;..." \
  --recovery-point "$RECOVERY_POINT"
```

### File Recovery (Without Full Restore)
1. **Backup Items** → Select VM
2. **File Recovery** → Download ISO
3. Mount ISO on another VM
4. Browse and copy individual files
5. Restore specific data only

---

## Section 7: Monitoring Backup Health

### Check Backup Status
1. **Backup Items** → Select VM
2. View:
   - Last backup status (Success/Failed)
   - Last backup time
   - Number of recovery points
   - Storage used
   - Protection status

### View Backup Alerts
1. **Vault Dashboard**
2. Check **Health Status**
3. Address any warnings:
   - Backup failures
   - Disk space issues
   - Agent connectivity problems

### Enable Notifications
1. **Vault** → **Alerts & Events**
2. Click **Configure Notifications**
3. Select alert types:
   - Critical failures
   - Backup job failures
   - Missing backups
4. Provide email address
5. Save

---

## Section 8: Backup Best Practices

✅ **DO:**
- **Schedule backups** during off-peak hours
- **Test recoveries** regularly (monthly)
- **Monitor backup jobs** for failures
- **Retain multiple points** (daily, weekly, monthly)
- **Encrypt backups** (at-rest encryption enabled by default)
- **Use app-consistent snapshots** for databases
- **Document recovery procedures**
- **Test RPO/RTO** requirements

❌ **DON'T:**
- Delete recovery points without confirming data safety
- Run large backups during peak business hours
- Trust backup without testing restoration
- Ignore backup failures for days
- Store credentials in Recovery Services Vault
- Backup to single region only

---

## Section 9: Backup Troubleshooting

### Backup Job Failed
1. Go to **Backup Jobs**
2. Click failed job
3. Check error message:
   - **Timeout:** VM disk issues, network problems
   - **Snapshot failed:** VM resource constraints
   - **Agent error:** Update Microsoft Monitoring Agent

### No Backups Executing
1. Verify **Backup Policy** is assigned to VM
2. Check **VM Agent Status:**
   - Portal → VM → **Extensions**
   - Look for "Azure Backup" extension
   - Status should be "Provisioning succeeded"
3. If failed, reinstall agent:
   ```bash
   # PowerShell on VM
   Set-AzVMExtension -ResourceGroupName "rg-dr-solution" \
     -VMName "vm-name" \
     -Name "IaaSBackup" \
     -Publisher "Microsoft.RecoveryServices" \
     -Type "VMSnapshot" \
     -TypeHandlerVersion "1.0"
   ```

### Storage Issues
1. Check **Vault Backup Properties:**
   - **Storage redundancy:** LRS, GRS, RAGRS
   - **Storage used:** Increasing? Retention too high?
2. Reduce retention if storage exceeds budget
3. Archive old recovery points

### Agent Connectivity
1. On VM:
   ```bash
   # Windows
   Get-Service waagent | fl
   
   # Linux
   systemctl status walinuxagent
   ```
2. If down, restart agent
3. Check network security group allows outbound HTTPS

---

## Section 10: Compliance & Security

### Encryption at Rest
- Default: **Azure-managed keys**
- Advanced: **Customer-managed keys** in Key Vault
  1. Go to **Backup Properties**
  2. Select **Encryption key**
  3. Choose Key Vault and key
  4. Apply

### Soft Delete
- Backup data retained 14 days after deletion
- Allows accidental recovery
- Configure in **Backup Properties**

### Role-Based Access Control (RBAC)
1. **Vault** → **Access Control (IAM)**
2. Add roles:
   - Backup Operator: Manage backups/restores
   - Backup Reader: View only
   - Contributor: Full management

---

## Section 11: Cost Optimization

### Storage Costs Breakdown
- Per VM backup: $0.05 USD/day (example rates)
- Per GB stored: $0.05 USD/month
- Restore operations: $0.10 USD/restore

### Cost Reduction Strategies
1. **Adjust retention:**
   - Daily: 7-14 days (not 30)
   - Weekly: 4-8 weeks (not 12)
   - Monthly: 3-6 months (not 12)
2. **Backup frequency:**
   - Non-critical VMs: Weekly instead of Daily
3. **Archive recovery points:**
   - Move monthly points to Archive tier
4. **Use incremental backups:**
   - Only changed blocks are backed up

---

## Section 12: Quick Reference Commands

```bash
# Get vault credentials
az backup vault backup-properties show \
  --resource-group "rg-dr-solution" \
  --name "recovery-vault-xxxxx"

# List protected items
az backup item list \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --backup-management-type AzureIaasVM

# Trigger backup
az backup protection backup-now \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --vm "dr-vm-primary-xxxxx"

# Monitor job
az backup job show \
  --resource-group "rg-dr-solution" \
  --vault-name "recovery-vault-xxxxx" \
  --name "<job-id>"
```

---

## Summary
- Azure Backup automates VM protection
- Recovery points enable instant restoration
- Policies define schedule and retention
- Monitor jobs regularly for failures
- Test restoration procedures quarterly
