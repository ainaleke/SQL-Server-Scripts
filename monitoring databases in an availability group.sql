Monitoring Databases in an Availability Group-SQL Server

USE MASTER
GO
DECLARE
@database_av_group as varchar(135),
@current_failover_status varchar(40),
@body1 as nvarchar(MAX),
@subject as varchar (100),
@subjectMail as varchar(140),
@dagName AS varchar(12),
@dbname as varchar(25),
@listStr VARCHAR(MAX),
@flag int,
@server_time datetime,
@row_counter int
 
set @flag=1;
set @row_counter=1;
set @server_time= convert(varchar(19),getdate());
IF EXISTS (select 1 from availability_group_table)
BEGIN
DECLARE cursor_table CURSOR
FOR
select name from master.sys.databases where name not in ('master','tempdb','msdb','model')
except
select database_name from master.sys.availability_databases_cluster
--Open the Cursor
 
open cursor_table
fetch next from cursor_table  into  @database_av_group
--while there is still data in the table
while @@FETCH_STATUS=0

BEGIN
  insert into availability_group_table(Id,dbName) values(@flag,@database_av_group)
  set @flag = @flag +1
  fetch next from cursor_table  into  @database_av_group
END
CLOSE cursor_table
DEALLOCATE cursor_table
 
--once donce then read the values from the temporary table
select @row_counter= count(*) from availability_group_table
WHILE (@row_counter > 0)
BEGIN
--iterate through the table and print each of the DB Names
--select @dbname= dbName from availability_group_table where id = @row_counter
SELECT @listStr = COALESCE(@listStr+',' ,'') + dbName from availability_group_table where id = @row_counter
--PRINT @output_dbName
SET @row_counter= @row_counter - 1
END
 
--if data exists in the table then send a mail, if not then don;t send, this will prevent it from sending a mail each time the script runs
SELECT @current_failover_status=role_desc from sys.dm_hadr_availability_replica_states where is_local=1;
SELECT @dagName=name from master.sys.availability_groups;
SET @subjectMail= 'Databases not in Availability Group on ' +@dagName;
SET @body1='Database(s): ' +@listStr +' is(are) not in the Av Grp '+@dagName +' at ' +CAST(@server_time as varchar(35));
 
--If data exists in the table then send the mail, else don't send.
IF EXISTS (select 1 from availability_group_table)
BEGIN
EXEC msdb.dbo.sp_send_dbmail
@subject=@subjectMail,
@profile_name='TempDB Monitor',
@recipients='applicationdelivery@abcng.com',
@copy_recipients='ppm@abcng.com',
@body=@body1,
@importance='High';
END
