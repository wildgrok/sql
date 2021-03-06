--First run this script to see if there are any logins that are out of sync.

DECLARE @Collation varchar(100)
DECLARE @SQL VARCHAR(2000)

CREATE TABLE ##TempSync
(
DB_NME Varchar(50),
DBUserName varchar(50),
SysLoginName varchar(50)
)

SELECT @Collation = CONVERT(SYSNAME,DatabasePropertyEx('master','Collation'))

SET @SQL = 'USE [?]
SELECT ''?'' DB_NME,
       A.name DBUserName,
       B.loginname SysLoginName
 FROM sysusers A
      JOIN master.dbo.syslogins B
      ON A.name Collate ' + @Collation + ' = B.Name 
      JOIN master.dbo.sysdatabases C
      ON C.Name = ''?''
 WHERE issqluser = 1
       AND (A.sid IS NOT NULL
       AND A.sid <> 0x0)
       AND suser_sname(A.sid) IS NULL
       AND (C.status & 32) =0 --loading
       AND (C.status & 64) =0 --pre recovery
       AND (C.status & 128) =0 --recovering
       AND (C.status & 256) =0 --not recovered
       AND (C.status & 512) =0 --offline
       AND (C.status & 1024) =0 --read only
 ORDER BY A.name'

INSERT into ##TempSync
EXEC sp_msforeachdb @SQL

SELECT * FROM ##TempSync

DROP TABLE ##TempSync

--I have added some extra checks to only include databases that are online. There is no need to try and sync logins on a database that is in the middle of a restore. I am also getting the collation from the master database to make sure there are no conflicts with the other databases.

--If the first script returns data, run this script to sync the logins.

DECLARE @Collation VARCHAR (100)
DECLARE @SQL VARCHAR(2000)

SELECT @Collation =CONVERT(SYSNAME,DatabasePropertyEx('master','Collation'))

SET @SQL = 'USE [?]
DECLARE @DBUserName varchar(50)
DECLARE @SysLoginName varchar(50)
DECLARE SyncDBLogins CURSOR FOR
 SELECT A.name DBUserName,
        B.loginname SysLoginName
 FROM sysusers A
      JOIN master.dbo.syslogins B
      ON A.name Collate ' + @Collation + ' = B.Name 
      JOIN master.dbo.sysdatabases C
      ON C.Name = ''?''
 WHERE issqluser = 1
       AND (A.sid IS NOT NULL
       AND A.sid <> 0x0)
       AND suser_sname(A.sid) IS NULL
       AND (C.status & 32) =0 --Loading
       AND (C.status & 64) =0 --pre recovery
       AND (C.status & 128) =0 --recovering
       AND (C.status & 256) =0 --not recovered
       AND (C.status & 512) =0 --offline
       AND (C.status & 1024) =0 --read only
 ORDER BY A.name

OPEN SyncDBLogins
FETCH NEXT FROM SyncDBLogins
 INTO @DBUserName, @SysLoginName

WHILE @@FETCH_STATUS = 0
 BEGIN
    EXEC sp_change_users_login ''update_one'', @DBUserName, @SysLoginName
    
    FETCH NEXT FROM SyncDBLogins
    INTO @DBUserName, @SysLoginName
 END
CLOSE SyncDBLogins
DEALLOCATE SyncDBLogins
'
EXEC sp_msforeachdb @SQL


--It is always a good idea to run the first script again to make sure everything worked as planned. 
--Also, this will only sync logins that already exist in the master database and the user database.