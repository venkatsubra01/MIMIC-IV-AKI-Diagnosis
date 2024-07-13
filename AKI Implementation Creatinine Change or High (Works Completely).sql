--Author: Venkat Subramanian
--Date: July 2022
--Identifies whether patients meet the criteria for an initial diagnosis of AKI
WITH creat7day AS --this calculates baseline creat
(
    SELECT
		le.subject_id
        , ie.hadm_id
        , ie.stay_id
        , le.charttime
		, AVG(le.valuenum) AS creat
		, MIN(le.valuenum) AS baseline_creat
    FROM [MIMIC 4].dbo.icustays ie
    LEFT JOIN [MIMIC 4].dbo.labevents le
    ON ie.subject_id = le.subject_id
    AND le.ITEMID = 50912
	AND le.CHARTTIME BETWEEN DATEADD(DAY, -7, ie.intime) AND ie.intime
    AND le.VALUENUM IS NOT NULL
    AND le.VALUENUM <= 150
    GROUP BY ie.hadm_id, ie.stay_id, le.charttime, le.subject_id
), 
creat48hr AS --From here, grab patients where creat_change >0.3 mg/dl (0.3 mg/dl increase in SCr within 48 hrs)
(
    -- add in the lowest, max, and change values in the previous 48 hours
    SELECT 
		creat7day.subject_id
        , creat7day.stay_id
        , creat7day.charttime
        , MIN(creat48hr.creat) AS creat_low_past_48hr
		, MAX(creat48hr.creat) AS creat_high_past_48hr
		, MAX(creat48hr.creat) - MIN(creat48hr.creat) AS creat_change
    FROM creat7day
    -- add in all creatinine values in the last 48 hours
    LEFT JOIN creat7day creat48hr
        ON creat7day.stay_id = creat48hr.stay_id
		AND creat48hr.charttime >= DATEADD(hour, -48, creat7day.charttime)
        AND creat48hr.charttime <  creat7day.charttime --I think I added this in, but I don't remember what this does exactly
    GROUP BY creat7day.stay_id, creat7day.charttime, creat7day.subject_id
)
SELECT *
FROM creat48hr
WHERE creat48hr.creat_change > 0.3;

WITH creat7day AS 
(
    SELECT
		le.subject_id
        , ie.hadm_id
        , ie.stay_id
        , le.charttime
		, MIN(le.valuenum) AS baseline_creat
    FROM [MIMIC 4].dbo.icustays ie
    LEFT JOIN [MIMIC 4].dbo.labevents le
    ON ie.subject_id = le.subject_id
    AND le.ITEMID = 50912
    AND le.VALUENUM IS NOT NULL
    AND le.VALUENUM <= 150
    AND le.CHARTTIME BETWEEN DATEADD(DAY, -7, ie.intime) AND ie.intime
    GROUP BY ie.hadm_id, ie.stay_id, le.charttime, le.subject_id
)
SELECT * --this grabs patients who had 1.5 x baseline creatinine
FROM [MIMIC 4].dbo.labevents
JOIN creat7day
ON creat7day.hadm_id = labevents.hadm_id
WHERE labevents.valuenum >= 1.5 * creat7day.baseline_creat
AND labevents.itemid = 50912;