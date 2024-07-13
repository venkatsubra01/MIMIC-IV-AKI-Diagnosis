--Author: Venkat Subramanian
--Date: July 2022
--Distinguishes Reversible AKI with Sustained AKI after the initial diagnosis
WITH creat3dayaft AS -- Determine if patients diagnosed with AKI in the last 48 hrs have reversible AKI
-- This is the inclusion criteria, anybody not in this list has sustained AKI
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
	AND le.CHARTTIME BETWEEN ie.intime AND DATEADD(DAY, 3, ie.intime) --Adds in all serum creatinine values 3 days after admission
    AND le.VALUENUM IS NOT NULL
    AND le.VALUENUM <= 150
    GROUP BY ie.hadm_id, ie.stay_id, le.charttime, le.subject_id
), 
creat72hraft AS --From here, grab patients where creatinine reduced by 0.3 mg/dL in 72 hours 
(
    -- add in the lowest, max, and change values in the previous 48 hours
    SELECT 
		creat3dayaft.subject_id
        , creat3dayaft.stay_id
        , creat3dayaft.charttime
        , MIN(creat72hraft.creat) AS creat_low_next_72hr
		, MAX(creat72hraft.creat) AS creat_high_next_72hr
		, MAX(creat72hraft.creat) - MIN(creat72hraft.creat) AS creat_change_aft --Gets min and max values for the 3 days/72 hours after admission
    FROM creat3dayaft
    -- add in all creatinine values in the last 48 hours
    LEFT JOIN creat3dayaft creat72hraft
        ON creat3dayaft.stay_id = creat72hraft.stay_id
		AND creat72hraft.charttime >= DATEADD(hour, -72, creat3dayaft.charttime) -- Since 3 days = 72 hours, this condition is unnecessary but makes things more clear
        AND creat72hraft.charttime <  creat3dayaft.charttime
    GROUP BY creat3dayaft.stay_id, creat3dayaft.charttime, creat3dayaft.subject_id
)
SELECT *
FROM creat72hraft
JOIN [MIMIC 4].dbo.[AKI Diagnoses by Creatinine Change] -- Joins table of patients that met the AKI phenotype by their serum creatinine increasing by 0.3 within 48 hours
ON creat72hraft.stay_id = [MIMIC 4].dbo.[AKI Diagnoses by Creatinine Change].stay_id
WHERE creat_low_next_72hr <= (CAST([MIMIC 4].dbo.[AKI Diagnoses by Creatinine Change].creat_high_past_48hr AS DECIMAL(38, 30)) - 0.3); --If the serum creatinine low in the next 72 hours is 0.3 less than the serum creatinine high during diagnosis, AKI has reversed
--Definition of AKI resolved by serum creatinine from https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2764344#:~:text=Of%20the%20patients%20with%20AKI,to%20baseline%20creatinine%20concentration%20at