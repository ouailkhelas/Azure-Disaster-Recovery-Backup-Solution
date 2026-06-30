# Azure Backup Configuration Guide

## Overview
This guide walks through configuring and managing Azure Backup for your VMs.

---

## Section 1: Viewing and Managing Backup Jobs

### View Backup Jobs in Portal
1. Go to **Azure Portal** → **Recovery Services Vault**
2. Click on vault created by deployment
3. Under **Monitoring**, click **Backup Jobs**
4. View all recent backup operations:
   - Job name
   - Status (Running, Succeeded, Failed)
   - Duration
   - Type (Backup, Restore, etc.)

---

## Section 2: Backup Policies

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
3. Adjust:
   - Schedule frequency
   - Retention duration
   - Recovery point retention
     
### Create Custom Policy
1. **Backup Policies** → **Create Policy**
2. Set schedule (frequency, time)
3. Configure retention:
   - Daily retention: 1-180 days
4. Save policy
5. Assign to VM

---

## Section 3: Recovery Points

### View Recovery Points
1. Go to **Recovery Services Vault**
2. Click **Backup Items** → **Azure Virtual Machine**
3. Select your VM
4. Click **View all recovery points**
5. 
---

## Section 4: Triggering Backups

### Manual/On-Demand Backup
1. **Recovery Services Vault** → **Backup Items**
2. Select VM
3. Click **Backup Now**
4. Select recovery point retention date
---

## Section 5: Restoring VMs

### Full VM Restore
1. **Recovery Services Vault** → **Backup Items**
2. Select your VM
3. Click **Restore VM**
4. Select recovery point
5. Choose restore options:
   - **Create New VM:** Restore to new VM
6. Configure:
   - VM 
7. Review and restore
8. Monitor job in **Backup Jobs**
