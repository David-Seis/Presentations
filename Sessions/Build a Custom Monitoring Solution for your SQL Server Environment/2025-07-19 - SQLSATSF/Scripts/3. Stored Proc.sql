
USE [servermetrics]
GO

/****** Object:  StoredProcedure [dbo].[sp_CustomPerf]    Script Date: 7/18/2025 11:07:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_CustomPerf]
AS
BEGIN
	INSERT INTO dbo.Perf
	SELECT	CAST(SERVERPROPERTY('ServerName') as NVARCHAR(256)) AS Instance_Name
		,	getdate() as timestamp
		,	CAST(counter_name as NVARCHAR(100))
		,	cntr_value
	FROM sys.dm_os_performance_counters
	WHERE counter_name in ('Processes blocked','Batch Requests/sec')
	UNION
	SELECT	CAST(SERVERPROPERTY('ServerName') as NVARCHAR(256)) AS Instance_Name
		,	getdate() as timestamp
		,	CAST(counter_name as NVARCHAR(100))
		,	SUM(cntr_value) as cntr_value
	FROM sys.dm_os_performance_counters 
	WHERE counter_name in ('Data File(s) Size (KB)','Log File(s) Size (KB)','Average Wait Time (ms)')
	and instance_name = '_Total'
	GROUP BY counter_name
	UNION
	SELECT	CAST(SERVERPROPERTY('ServerName') as NVARCHAR(256)) AS Instance_Name
		,	getdate() as timestamp
		,	CAST(counter_name as NVARCHAR(100))
		,	SUM(cntr_value) as cntr_value
	FROM sys.dm_os_performance_counters 
	WHERE counter_name in ('CPU usage %', 'Errors/sec')
	GROUP BY counter_name
	UNION
	SELECT	CAST(SERVERPROPERTY('ServerName') as NVARCHAR(256)) AS Instance_Name
		,	getdate() as timestamp
		,	CAST(REPLACE(counter_name, 'KB','GB') as NVARCHAR(100))
		,	SUM(cntr_value/1024/1024) as cntr_value 
	FROM sys.dm_os_performance_counters 
	WHERE counter_name in ('Max memory (KB)','Used memory (KB)')
	GROUP BY REPLACE(counter_name, 'KB','GB')
END
GO