# SQL Server Log Shipping DR Drill

This repository contains a script to perform a Disaster Recovery (DR) drill for SQL Server log shipping. The script allows you to switch the roles of the primary and secondary databases without data loss.

## Prerequisites

- SQL Server Management Studio (SSMS)
- SQL Server Agent Jobs set up for Log Shipping
- A working Log Shipping configuration

## Steps for DR Drill

1. **Verify Log Shipping Status**: Ensure that log shipping is running smoothly by checking the status of the log shipping monitor.

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
    WHERE secondary_database = 'FinanceDB';

    ```

2. **Run Backup Job on Primary**: Trigger the backup job on the primary server to take the latest transaction log backup.

    ```sql
    EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Backup Job';
    ```

3. **Run Copy Job on Secondary**: Copy the transaction log backup file from the primary server to the secondary.

    ```sql
    EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Copy Job';
    ```

4. **Run Restore Job on Secondary**: Apply the copied log backup file to the secondary database.

    ```sql
    EXEC msdb.dbo.sp_start_job @job_name = 'Log Shipping Restore Job';
    ```

5. **Tail-Log Backup on Primary**: Take a final transaction log backup on the primary server to capture any remaining unbacked-up transactions.

    ```sql
    BACKUP LOG [YourPrimaryDatabase]
    TO DISK = 'C:\Backups\YourPrimaryDatabase_TailLog.trn'
    WITH NORECOVERY;
    ```

6. **Restore Tail-Log on Secondary**: Restore the tail-log backup on the secondary database to bring it up-to-date.

    ```sql
    RESTORE LOG [YourSecondaryDatabase]
    FROM DISK = 'C:\Backups\YourPrimaryDatabase_TailLog.trn'
    WITH RECOVERY;
    ```

7. **Reconfigure Log Shipping Roles**: Switch the primary and secondary roles by reconfiguring the log shipping settings.

    - **On the new Primary (formerly Secondary)**: Configure it to start taking backups and sending logs to the original primary server (now secondary).

        ```sql
        EXEC master.dbo.sp_add_log_shipping_primary_database
            @database = 'YourSecondaryDatabase',
            @backup_directory = 'C:\LogShippingBackup',
            @backup_retention_period = 4320,
            @backup_threshold = 60,
            @threshold_alert_enabled = 1,
            @history_retention_period = 1440;
        ```

    - **On the new Secondary (formerly Primary)**: Set it up to receive and restore logs from the new primary.

        ```sql
        EXEC master.dbo.sp_add_log_shipping_secondary_database
            @secondary_database = 'YourPrimaryDatabase',
            @restore_delay = 0,
            @restore_all = 1,
            @restore_mode = 1,
            @disconnect_users = 1,
            @threshold_alert_enabled = 1,
            @threshold_alert = 60,
            @history_retention_period = 1440;
        ```

## How to Use

1. Copy the T-SQL script to SSMS.
2. Follow the steps sequentially to complete the DR drill process.
3. Monitor the jobs in SQL Server Agent to ensure everything completes successfully.

## Contribution

Feel free to submit pull requests or report issues. All contributions are welcome!
