
DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 
       ,@templatelogin nvarchar(max) =null
       ,@desiredlogin sysname = null
       ,@sourceinstance sysname = null
       ,@sourcedb nvarchar(max) = null
       ,@targetinstance sysname = null
       ,@targetdb sysname = null
       
declare @databases table (DatabaseName sysname, DatabaseSize bigint, Remarks varchar(254) null)
declare @output table (servername nvarchar(max), dbname nvarchar(max), username nvarchar(max), dbrole nvarchar(max))
declare @dbname sysname
declare @cmd nvarchar(max)
declare @tsql nvarchar(max)

-- LgName
--set @templatelogin = null
--set @desiredlogin = null
--set @sourceinstance = null
--set @sourcedb = null
--set @targetinstance = null
--set @targetdb = null

set @cmd = '
DECLARE
@sql1 VARCHAR(2048),
@sql2 VARCHAR(2048),
@sql3 VARCHAR(2048),
@sql4 VARCHAR(2048)


use [sourcedb]

DECLARE tmp CURSOR FOR

SELECT @@servername, ''sourcedb'', USER_NAME(rm.member_principal_id), USER_NAME(rm.role_principal_id)
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) IN (  
	--get user names on the database
	SELECT [name]
	FROM sys.database_principals
	WHERE [principal_id] > 4
	and [type] IN (''G'', ''S'', ''U'')
)

OPEN tmp
FETCH NEXT FROM tmp INTO @sql1, @sql2, @sql3, @sql4
WHILE @@FETCH_STATUS = 0
BEGIN
       select @sql1, @sql2, @sql3, @sql4
FETCH NEXT FROM tmp INTO @sql1, @sql2, @sql3, @sql4
END

CLOSE tmp
DEALLOCATE tmp 
'

insert into @databases exec sp_databases

declare crsr cursor local fast_forward for 
    select DatabaseName from @databases where case when @sourcedb is null then DatabaseName end in (select DatabaseName from @databases) or case when @sourcedb is not	null then DatabaseName end = @sourcedb
open crsr;
	fetch next from crsr into @dbname;
	while @@fetch_status=0 begin
		set @tsql = replace(@cmd,'sourcedb',@dbname)
        insert into @output(servername,dbname,username, dbrole) exec(@tsql)
	fetch next from crsr into @dbname;
end;
close crsr;
deallocate crsr;

select * from @output


