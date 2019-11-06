/* 
	All the data from excel inserted into drivers table.

	To make an analysis of 2 time frames, I have created 2 CTE's, each for the relevant time period:
	1. drivers_grouped_22_30 (For all active drivers in the period of 29-30/12/2015 where full-week = TRUE and without NULL)
	2. drivers_grouped_29_30 (For all period between 29-30/12/2015 where full-week = TRUE and without NULL)


--- The second table is after the analysis of the first one! ---

*/

--Creating the main table:

use master
go

if object_id('drivers','U') is not null drop table drivers
go


create table drivers
(
StartDate date,
recordType varchar(24),
ProviderID varchar(64),
OnboardingDate datetime,
DaysActive decimal(5,2),
BusyDuration decimal(5,2),
BusyDistance float,
BusyUpdates int,
OnlineDuration decimal(5,2),
OnlineDistance float,
OnlineUpdates int,
NumMoves int,
FullWeek varchar(6)
)
go

--Insert data into the table:

bulk insert drivers
from 
'C:\temp\drivers.txt'
with
(
FIRSTROW=2,
rowterminator = '\n',
fieldterminator = ','
)



--Make a test: 
--SELECT * FROM drivers


/*
The Calculation below is to show how much drivers there are before and after cleaning and seperating the data by period:
 
Counting number of drivers that are in both period times (29-30/12/2015 and 22-30/12/2015)

---------------------------Total Number of Drivers-------------------------------------
SELECT ProviderID FROM drivers GROUP BY ProviderID -- 260

--------------------------------- 22-30/12/2015-----------------------------------------
SELECT ProviderID 
FROM drivers 
WHERE ProviderID NOT IN (SELECT ProviderID FROM drivers WHERE Fullweek='FALSE')   //Filter full week
	AND BusyDuration + onlineDuration  != 0 //Filter N/A or non active drivers
	GROUP BY ProviderID --Total Drivers 146


--------------------------------- 29-30/12/2015-----------------------------------------
SELECT ProviderID 
FROM drivers 
WHERE recordtype = 'Day' 
	AND ProviderID NOT IN (SELECT ProviderID FROM drivers WHERE recordtype ='Day' And Fullweek='FALSE')  
	AND BusyDuration + onlineDuration  != 0 
	GROUP BY ProviderID --Total Drivers 185


*/

--Create table for the first table for period - 22-30/12
go
if object_id('drivers_grouped_22_30','U') is not null drop table drivers_grouped_22_30
go

SELECT ProviderID, 
		Min(OnboardingDate) AS Onboarding_Date,
		Min(DaysActive) AS Days_Active,
		Sum(BusyDuration) AS Busy_Duration,
		Sum(BusyDistance) AS Busy_Distance,
		Sum(BusyUpdates) AS Busy_Updates,
		Sum(OnlineDuration) AS Online_Duration,
		Sum(OnlineDistance) AS Online_Distance,
		Sum(OnlineUpdates) AS Online_Updates,
		Sum(BusyDistance+OnlineDistance) / Cast((Sum(OnlineUpdates)+Sum(BusyUpdates)) AS Float) AS Average_Distance,
		Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100 AS Utilization_Perc,
		Sum(NumMoves) AS Num_Moves,
			PERCENT_RANK () Over( ORDER BY Sum(busydistance) + Sum(OnlineDistance)) AS  Distance_Rank,
		(CASE WHEN (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) < 25 THEN 1 ELSE 0 END) AS High_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) Between 25 and 49.99999 THEN 1 ELSE 0 END) AS Mid_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) Between 50 and 75 THEN 1 ELSE 0 END) AS Low_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) > 75 THEN 1 ELSE 0 END) AS Very_Low_Engagement,
		(112685/365) * 1000 * 0.72 / 2 AS Holidays_Avg_Daily_Miles_of_Texi_Driver
INTO drivers_grouped_22_30
FROM drivers 
WHERE ProviderID NOT IN (SELECT ProviderID FROM drivers WHERE FullWeek = 'FALSE')
	AND BusyDuration + onlineDuration  != 0
GROUP BY ProviderID
ORDER BY Utilization_Perc DESC

--Checking the table:
--SELECT * FROM drivers_grouped_22_30

--Data of Utilization Distribution by Drivers

SELECT 	(CASE WHEN Distance_Rank BETWEEN 0.00000 AND 0.2499999 THEN 'High_Distance'
		WHEN Distance_Rank BETWEEN 0.25 AND 0.499999 THEN 'High_Mid_Distance'
		WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance'
		WHEN Distance_Rank > 0.75 THEN 'Low_Distance' END) AS Distance_Levels,
		Sum(High_Engagement) AS High_Engagement,
		Sum(Mid_Engagement) AS Mid_Engagement,
		Sum(Low_Engagement) AS Low_Engagement,
		Sum(Very_Low_Engagement) AS Very_Low_Engagement
FROM drivers_grouped_22_30
GROUP BY 
	(CASE WHEN Distance_Rank BETWEEN 0.00000 AND 0.2499999 THEN 'High_Distance'
		WHEN Distance_Rank BETWEEN 0.25 AND 0.499999 THEN 'High_Mid_Distance'
		WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance'
		WHEN Distance_Rank > 0.75 THEN 'Low_Distance' END)

--(scatter plot data) Data of Comparison Between Time and Distance

SELECT Busy_Duration + Online_Duration AS Total_Time, Online_Distance + Busy_Distance AS Total_Distance
FROM drivers_grouped_22_30

SELECT Online_Duration ,Online_Distance
FROM drivers_grouped_22_30

SELECT Busy_Duration, Busy_Distance
FROM drivers_grouped_22_30

--Data of Mean and Average of distance of drivers with  Top total distance (continued in excel)

SELECT TOP 35
	ProviderID, Busy_Distance, Online_Distance, Busy_Distance + Online_Distance AS Total_Distance, Distance_Rank, Average_Distance
FROM drivers_grouped_22_30
ORDER BY Distance_Rank DESC

---------------------------------------------------------------------------------------------------------------------------------------------

--Second table - active drivers between dates 29-30/12/2015

go
if object_id('drivers_grouped_29_30','U') is not null drop table drivers_grouped_29_30
go

SELECT ProviderID, 
		Min(OnboardingDate) AS Onboarding_Date,
		Min(DaysActive) AS Days_Active,
		Sum(BusyDuration) AS Busy_Duration,
		Sum(BusyDistance) AS Busy_Distance,
		Sum(BusyUpdates) AS Busy_Updates,
		Sum(OnlineDuration) AS Online_Duration,
		Sum(OnlineDistance) AS Online_Distance,
		Sum(OnlineUpdates) AS Online_Updates,
		Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100 AS Utilization_Perc,
		Sum(NumMoves) AS Num_Moves,
		PERCENT_RANK () Over( ORDER BY Sum(busydistance) + Sum(OnlineDistance)) AS  Distance_Rank,	
		(CASE WHEN (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) < 25 THEN 1 ELSE 0 END) AS High_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) Between 25 and 49.99999 THEN 1 ELSE 0 END) AS Mid_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) Between 50 and 75 THEN 1 ELSE 0 END) AS Low_Engagement,
		(CASE WHEN  (Sum(BusyDuration) / (Sum(BusyDuration)+ Sum(onlineDuration)) * 100) > 75 THEN 1 ELSE 0 END) AS Very_Low_Engagement,
		(112685/365) * 1000 / 2 AS Holidays_Avg_Daily_Miles_of_Texi_Driver
INTO drivers_grouped_29_30
FROM drivers 
WHERE recordType = 'Day' 
	AND ProviderID NOT IN (SELECT ProviderID FROM drivers WHERE recordType = 'Day' AND FullWeek = 'FALSE')
	AND BusyDuration + onlineDuration  != 0
GROUP BY ProviderID

--SELECT * FROM drivers_grouped_29_30

--Data of Utilization Distribution by Drivers

SELECT 	(CASE WHEN Distance_Rank BETWEEN 0.00000 AND 0.2499999 THEN 'High_Distance'
		WHEN Distance_Rank BETWEEN 0.25 AND 0.499999 THEN 'High_Mid_Distance'
		WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance'
		WHEN Distance_Rank > 0.75 THEN 'Low_Distance' END) AS Distance_Levels,
		Sum(High_Engagement) AS High_Engagement,
		Sum(Mid_Engagement) AS Mid_Engagement,
		Sum(Low_Engagement) AS Low_Engagement,
		Sum(Very_Low_Engagement) AS Very_Low_Engagement
FROM drivers_grouped_29_30
GROUP BY 
	(CASE WHEN Distance_Rank BETWEEN 0.00000 AND 0.2499999 THEN 'High_Distance'
		WHEN Distance_Rank BETWEEN 0.25 AND 0.499999 THEN 'High_Mid_Distance'
		WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance'
		WHEN Distance_Rank > 0.75 THEN 'Low_Distance' END)

--(scatter plot data)  Data of Comparison Between Time and Distance

SELECT Busy_Duration + Online_Duration AS Total_Time, Online_Distance + Busy_Distance AS Total_Distance
FROM drivers_grouped_29_30
ORDER BY Online_Distance + Busy_Distance DESC

SELECT Online_Duration ,Online_Distance
FROM drivers_grouped_29_30

SELECT Busy_Duration, Busy_Distance
FROM drivers_grouped_29_30


--Data of Beyond and below industry average driving kilometers by Utilization

SELECT 	(CASE WHEN Online_Distance+Busy_Distance >= Holidays_Avg_Daily_Miles_of_Texi_Driver THEN 'Beyond_Avg'
			WHEN Online_Distance+Busy_Distance < Holidays_Avg_Daily_Miles_of_Texi_Driver THEN 'Lower Then Avg'
			WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance' END) AS Distance_Levels,
		Sum(High_Engagement) AS High_Engagement,
		Sum(Mid_Engagement) AS Mid_Engagement,
		Sum(Low_Engagement) AS Low_Engagement,
		Sum(Very_Low_Engagement) AS Very_Low_Engagement,
		Avg(Online_Distance+Busy_Distance) AS Avg_Distance,
		Min(Holidays_Avg_Daily_Miles_of_Texi_Driver) AS Avg_Meters_Of_a_Taxi_Driver,
		Avg(Online_Distance+Busy_Distance) - Min(Holidays_Avg_Daily_Miles_of_Texi_Driver) AS Diffrance
FROM drivers_grouped_29_30
GROUP BY 
	(CASE WHEN Online_Distance+Busy_Distance >= Holidays_Avg_Daily_Miles_of_Texi_Driver THEN 'Beyond_Avg'
		WHEN Online_Distance+Busy_Distance < Holidays_Avg_Daily_Miles_of_Texi_Driver THEN 'Lower Then Avg'
		WHEN Distance_Rank BETWEEN 0.5 AND 0.75 THEN 'Mid_Low_Distance' END)

-----------------------------------------------------------------------------------------------------------------
--(scatter plot data) Total Distance By Total Hours - 22-29/12/2015 (chart in "Drivers that needs special attention")

SELECT ProviderID, Sum(BusyDuration) + Sum(OnlineDuration) AS Total_Duration, Sum(OnlineDistance) + Sum(BusyDistance) AS Total_Distance 
FROM drivers
WHERE StartDate != '2015-12-30'
	AND FullWeek = 'TRUE'
GROUP BY ProviderID