USE msdb;
GO

;WITH LastBackups AS (
    SELECT 
        b.database_name,
        b.backup_finish_date,
        b.type,
        b.backup_size,
        b.is_copy_only,
        b.first_lsn,
        b.last_lsn,
        bf.physical_device_name AS backup_file_path,
        ROW_NUMBER() OVER(PARTITION BY b.database_name, b.type ORDER BY b.backup_finish_date DESC) AS rn
    FROM 
        dbo.backupset b
    INNER JOIN 
        dbo.backupmediafamily bf ON b.media_set_id = bf.media_set_id
    WHERE 
        b.type IN ('L') -- D = Database, I = Differential, L = Log
)
SELECT 
    database_name,
    backup_finish_date,
    type,
    backup_size,
    is_copy_only,
    first_lsn,
    last_lsn,
    backup_file_path
FROM 
    LastBackups
WHERE 
    rn = 1
ORDER BY 
    database_name, type;
