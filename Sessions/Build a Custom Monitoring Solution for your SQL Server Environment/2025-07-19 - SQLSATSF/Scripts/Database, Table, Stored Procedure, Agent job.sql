USE [master]
GO

/****** Object:  Database [servermetrics]    Script Date: 7/18/2025 11:06:50 PM ******/
CREATE DATABASE [servermetrics]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'servermetrics', FILENAME = N'/var/opt/mssql/data/servermetrics.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'servermetrics_log', FILENAME = N'/var/opt/mssql/data/servermetrics_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [servermetrics].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [servermetrics] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [servermetrics] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [servermetrics] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [servermetrics] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [servermetrics] SET ARITHABORT OFF 
GO

ALTER DATABASE [servermetrics] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [servermetrics] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [servermetrics] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [servermetrics] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [servermetrics] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [servermetrics] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [servermetrics] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [servermetrics] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [servermetrics] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [servermetrics] SET  ENABLE_BROKER 
GO

ALTER DATABASE [servermetrics] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [servermetrics] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [servermetrics] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [servermetrics] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [servermetrics] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [servermetrics] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [servermetrics] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [servermetrics] SET RECOVERY FULL 
GO

ALTER DATABASE [servermetrics] SET  MULTI_USER 
GO

ALTER DATABASE [servermetrics] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [servermetrics] SET DB_CHAINING OFF 
GO

ALTER DATABASE [servermetrics] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [servermetrics] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO

ALTER DATABASE [servermetrics] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [servermetrics] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO

ALTER DATABASE [servermetrics] SET QUERY_STORE = ON
GO

ALTER DATABASE [servermetrics] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO

ALTER DATABASE [servermetrics] SET  READ_WRITE 
GO


USE [servermetrics]
GO

/****** Object:  Table [dbo].[perf]    Script Date: 7/18/2025 11:07:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[perf](
	[Instance_Name] [nvarchar](256) NULL,
	[timestamp] [datetime] NULL,
	[counter_name] [nvarchar](100) NULL,
	[cntr_value] [bigint] NULL
) ON [PRIMARY]
GO

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

USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'perfmonitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'perfmonitoring', @server_name = N'SQL2-25-2'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'perfmonitoring', @step_name=N'sp_perfcollect', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sp_customperf', 
		@database_name=N'servermetrics', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'perfmonitoring', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'perfmonitoring', @name=N'every 10 seconds', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20250718, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO


