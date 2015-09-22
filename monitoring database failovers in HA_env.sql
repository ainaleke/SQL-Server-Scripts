Creating the Temp Table
create table current_replica_state_temp_table
(
ID int,
replica_status varchar(20)
)
Insert Current Replica Status Value into the Temp Table
e,g insert current_replica_state_temp_table
SELECT 1, 'SECONDARY'
--DB Failover script Used.
USE MASTER 
GO
DECLARE
@body1 as nvarchar(300),
@subject as varchar (300),
@instanceName AS varchar(10),
@subjectMail as varchar(35),
@dagName AS varchar(12),
@current_failover_status varchar(20),
@replica_status_temp_table varchar(35)
--failover status from the master table --this changes on failover
select @current_failover_status=role_desc from sys.dm_hadr_availability_replica_states where is_local=1; 
--failover status from temp table --this will be updated on failover
select @replica_status_temp_table=replica_status from current_replica_state_temp_table --update 
select @dagName=name from master.sys.availability_groups
set @body1 = 'A Failover just occurred on ' + @@SERVERNAME +'.'+' It is now the ' +@current_failover_status +' Replica' 
set @subjectMail='SQL Server Failover ' +@dagName;
--compare the replica status currently with that in the temp table to see if a failover has occured
IF (@replica_status_temp_table!=@current_failover_status) --if both are same, then no Failover has occured, send MAIL 
BEGIN
UPDATE current_replica_state_temp_table set replica_status=@current_failover_status 
--(if its a secondary replica, update will not work)...
EXEC msdb.dbo.sp_send_dbmail
@subject=@subjectMail,
@profile_name='TempDB Monitor',
@recipients='xyz@gmail.com',
@body=@body1,
@importance='High';
END
