
# SQL Server Log Shipping DR Drill

This repository contains a comprehensive guide to performing a Disaster Recovery (DR) drill for SQL Server log shipping. It includes both script-based and SSMS GUI-based methods to switch roles between the primary and secondary databases without data loss.

---

## Prerequisites
- SQL Server Management Studio (SSMS)
- SQL Server Agent Jobs set up for Log Shipping
- A working Log Shipping configuration

---

## Steps for DR Drill

### 1. Verify Log Shipping Status

#### Script Method
Run the following query to check the status of log shipping:

```sql
SELECT 
    secondary_server,
    secondary_database,
    primary_server,
    primary_database,
    last_copied_file,
    last_copied_date,
    last_restored_file,
    last_restored_date
FROM msdb.dbo.log_shipping_monitor_secondary
WHERE secondary_database = 'YourSecondaryDatabase';
```

#### GUI Method
1. Open **SSMS**.
2. Navigate to **Management** → **Log Shipping Status**.
3. Verify the status of all primary and secondary databases.

---

### 2. Trigger Backup Job on Primary

#### Script Method
Execute the following command to start the backup job:

```sql
EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Backup Job';
```

#### GUI Method
1. In **SSMS**, connect to the **Primary Server**.
2. Go to **SQL Server Agent** → **Jobs**.
3. Right-click on the **Log Shipping Backup Job** and select **Start Job at Step**.
4. Monitor its progress in the **Job Activity Monitor**.

---

### 3. Trigger Copy Job on Secondary

#### Script Method
Execute the following command:

```sql
EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Copy Job';
```

#### GUI Method
1. Connect to the **Secondary Server** in SSMS.
2. Navigate to **SQL Server Agent** → **Jobs**.
3. Right-click on the **Log Shipping Copy Job** and select **Start Job at Step**.

---

### 4. Trigger Restore Job on Secondary

#### Script Method
Run this command to start the restore job:

```sql
EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Restore Job';
```

#### GUI Method
1. On the **Secondary Server**, go to **SQL Server Agent** → **Jobs**.
2. Right-click on the **Log Shipping Restore Job** and select **Start Job at Step**.

---

### 5. Perform Tail-Log Backup on Primary

#### Script Method
Run the following T-SQL command to take the tail-log backup:

```sql
BACKUP LOG [YourPrimaryDatabase]
TO DISK = 'C:\Backups\YourPrimaryDatabase_TailLog.trn'
WITH NORECOVERY;
```

#### GUI Method
1. On the **Primary Server**, right-click the database and select **Tasks** → **Back Up**.
2. In the **Backup Database** dialog:
   - Select **Transaction Log** as the backup type.
   - Choose a destination (e.g., `YourPrimaryDatabase_TailLog.trn`).
   - Under **Options**, select **WITH NORECOVERY**.
3. Click **OK** to start the backup.

---

### 6. Restore Tail-Log on Secondary

#### Script Method
Run the following command:

```sql
RESTORE LOG [YourSecondaryDatabase]
FROM DISK = 'C:\Backups\YourPrimaryDatabase_TailLog.trn'
WITH RECOVERY;
```

#### GUI Method
1. On the **Secondary Server**, right-click the secondary database and select **Tasks** → **Restore** → **Transaction Log**.
2. In the **Restore Database** dialog:
   - Select the tail-log backup file (e.g., `YourPrimaryDatabase_TailLog.trn`).
   - Check the option **WITH RECOVERY** under the **Options** tab.
3. Click **OK** to restore the transaction log.

---

### 7. Reconfigure Log Shipping Roles

#### New Primary (formerly Secondary)
1. On the new **Primary Server**, right-click the database and select **Properties**.
2. Go to the **Transaction Log Shipping** page.
3. Check **Enable this as a primary database in a log shipping configuration**.
4. Specify the backup folder path, backup job settings, and retention period.
5. Click **OK** to save and enable log shipping.

#### New Secondary (formerly Primary)
1. On the new **Secondary Server**, right-click the database and select **Properties**.
2. Navigate to the **Transaction Log Shipping** page.
3. Check **Enable this as a secondary database**.
4. Configure the restore settings, including:
   - The shared folder for receiving log backups.
   - Restore schedule and mode (standby or no recovery).
5. Click **OK** to save the configuration.

---

## Contribution
Feel free to submit pull requests or report issues. All contributions are welcome!
