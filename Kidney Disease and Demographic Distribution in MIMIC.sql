--Query to get number of people with kidney disease distribution in MIMIC
SELECT [MIMIC 4].dbo.d_icd_diagnoses.icd_code,
COUNT(DISTINCT [MIMIC 4].dbo.diagnoses_icd.subject_id) AS diag_counts,
[MIMIC 4].dbo.d_icd_diagnoses.long_title,
[MIMIC 4].dbo.d_icd_diagnoses.icd_version
FROM [MIMIC 4].dbo.d_icd_diagnoses
JOIN [MIMIC 4].dbo.diagnoses_icd
ON [MIMIC 4].dbo.diagnoses_icd.icd_code = [MIMIC 4].dbo.d_icd_diagnoses.icd_code
WHERE [MIMIC 4].dbo.d_icd_diagnoses.long_title LIKE '%kidney%'
GROUP BY [MIMIC 4].dbo.d_icd_diagnoses.icd_code, [MIMIC 4].dbo.d_icd_diagnoses.long_title, [MIMIC 4].dbo.d_icd_diagnoses.icd_version
ORDER BY diag_counts DESC;

SELECT subject_id, admission_location AS hosp_location, insurance, language, ethnicity
FROM [MIMIC 4].dbo.admissions;

--Query to get hospital admission location distribution (emergency room, physician referral, hospital transfer, walk-in, etc.)
SELECT admission_location,
COUNT(DISTINCT [MIMIC 4].dbo.admissions.subject_id) AS location_count
FROM [MIMIC 4].dbo.admissions
GROUP BY [MIMIC 4].dbo.admissions.admission_location
ORDER BY location_count DESC;

--Query to get insurance distribution
SELECT insurance,
COUNT(DISTINCT [MIMIC 4].dbo.admissions.subject_id) AS insurance_count
FROM [MIMIC 4].dbo.admissions
GROUP BY [MIMIC 4].dbo.admissions.insurance
ORDER BY insurance_count DESC;

--Query to get language distribution
SELECT language,
COUNT(DISTINCT [MIMIC 4].dbo.admissions.subject_id) AS language_count
FROM [MIMIC 4].dbo.admissions
GROUP BY [MIMIC 4].dbo.admissions.language
ORDER BY language_count DESC;

--Query to get ethnicity distribution
SELECT [MIMIC 4].dbo.admissions.ethnicity,
COUNT(DISTINCT [MIMIC 4].dbo.admissions.subject_id) AS ethnicity_count
FROM [MIMIC 4].dbo.admissions
GROUP BY [MIMIC 4].dbo.admissions.ethnicity
ORDER BY ethnicity_count DESC;