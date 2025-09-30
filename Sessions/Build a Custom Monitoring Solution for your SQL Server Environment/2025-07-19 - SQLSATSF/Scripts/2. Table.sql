
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