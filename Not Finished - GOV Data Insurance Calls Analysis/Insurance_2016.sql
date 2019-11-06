IF object_id('Review_Of_Insurance_Calls_2016', 'U') IS NOT NULL DROP TABLE Review_Of_Insurance_Calls_2016

Go

CREATE TABLE Review_Of_Insurance_Calls_2016
	(
	Date_Time datetime,	
	Call_Subject varchar(10),	
	Day_In_Week int,	
	During_Hours varchar(24),
	Call_Started_Time time,
	time_For_Wating_After_Voice_Mail time,
	Answer_Time_From_ time,
	Representative_response_time_in_secounds int,
	total_Time_Till_Response int,
	Summery_Of_Call varchar(64),
	Is_Was_a_Long_Wating_Time_Message varchar(3),
	Other_Languages varchar(64)
	)

BULK INSERT Review_Of_Insurance_Calls_2016
FROM
'D:\Gov Data\Insurance\Insurance_calls_2016.txt'
WITH
(
FIRSTROW=2,
rowterminator = '\n',
fieldterminator = ','
)

-- Total numeber of reviews in 2016 by subject:

SELECT * FROM Review_Of_Insurance_Calls_2016

SELECT 
	Call_Subject,
	Count(*) as Number_Of_Calls
FROM Review_Of_Insurance_Calls_2016
GROUP BY Call_Subject
ORDER BY Count(*) DESC

-- Average time till response where there isn't foreign languages and the call was recived or transferred to leave a message while there was a long waiting time message by subject.

SELECT 
	Call_Subject,
	Avg(total_Time_Till_Response) as average_Time_Till_Response_in_Sec
FROM Review_Of_Insurance_Calls_2016
WHERE Other_Languages Like 'No Foreign languages'
	AND Is_Was_a_Long_Wating_Time_Message = 'Yes'
	AND Summery_Of_Call IN ('Full reply received', 'I was obliged to leave a message', 'Transferred to leave a message' )
GROUP BY Call_Subject
ORDER BY Avg(total_Time_Till_Response) DESC

-- which day and hour would you recommend to call to wait the least time till response after the voice mail in a general issue?

SELECT 
	Day_In_Week, 
	During_Hours,
	(Sum(Representative_response_time_in_secounds) - 
	Sum(total_Time_Till_Response)) / Count(*)
FROM Review_Of_Insurance_Calls_2016
WHERE Call_Subject = 'General'
GROUP BY Day_In_Week, During_Hours
ORDER BY  
	(Sum(Representative_response_time_in_secounds) - 
	Sum(total_Time_Till_Response)) / Count(*) 

-- is the total average time till response of non foren language is bigger than of foren language by each subject?
SELECT 
	CASE WHEN Other_Languages LIKE 'No Foreign languages' THEN 'No Foreign languages'
	ELSE 'Foreign languages' END as Languages,
--General
	CASE WHEN Sum(CASE WHEN Call_Subject = 'General' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE 
	Sum(CASE WHEN Call_Subject = 'General' THEN Representative_response_time_in_secounds - total_Time_Till_Response ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'General' THEN 1 ELSE 0 END) END AS general_avg_Diffrance,
--Heath
	CASE WHEN Sum(CASE WHEN Call_Subject = 'Health' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE
	Sum(CASE WHEN Call_Subject = 'Health' THEN Representative_response_time_in_secounds - total_Time_Till_Response ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'Health' THEN 1 ELSE 0 END) END AS health_avg_Diffrance,
--Life
	CASE WHEN Sum(CASE WHEN Call_Subject = 'Life' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE
	Sum(CASE WHEN Call_Subject = 'Life' THEN Representative_response_time_in_secounds - total_Time_Till_Response ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'Life' THEN 1 ELSE 0 END) END AS life_Diffrance
FROM Review_Of_Insurance_Calls_2016
GROUP BY CASE WHEN Other_Languages LIKE 'No Foreign languages' THEN 'No Foreign languages'
	ELSE 'Foreign languages' END
/*
	There isn't much diffrance however, the total time of foreign lanuages speakers are longer for the reason of 
	time wasted on the voice mail:
*/

SELECT 
	CASE WHEN Other_Languages LIKE 'No Foreign languages' THEN 'No Foreign languages'
	ELSE 'Foreign languages' END as Languages,
--General
	CASE WHEN Sum(CASE WHEN Call_Subject = 'General' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE 
	Sum(CASE WHEN Call_Subject = 'General' THEN Representative_response_time_in_secounds ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'General' THEN 1 ELSE 0 END) END AS general_avg_Diffrance,
--Heath
	CASE WHEN Sum(CASE WHEN Call_Subject = 'Health' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE
	Sum(CASE WHEN Call_Subject = 'Health' THEN Representative_response_time_in_secounds ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'Health' THEN 1 ELSE 0 END) END AS health_avg_Diffrance,
--Life
	CASE WHEN Sum(CASE WHEN Call_Subject = 'Life' THEN 1 ELSE 0 END) = 0 THEN NULL ELSE
	Sum(CASE WHEN Call_Subject = 'Life' THEN Representative_response_time_in_secounds ELSE 0 END) /
	Sum(CASE WHEN Call_Subject = 'Life' THEN 1 ELSE 0 END) END AS life_Diffrance
FROM Review_Of_Insurance_Calls_2016
GROUP BY CASE WHEN Other_Languages LIKE 'No Foreign languages' THEN 'No Foreign languages'
	ELSE 'Foreign languages' END

	select distinct Summery_Of_Call from Review_Of_Insurance_Calls_2016
