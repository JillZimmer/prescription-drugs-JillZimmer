/*1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.*/

SELECT npi, 
	SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;


/*1. b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.*/

SELECT npi,
	p1.nppes_provider_first_name AS first_name,
	p1.nppes_provider_last_org_name AS last_name,
	p1.specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescriber AS p1
	INNER JOIN prescription AS p2
	USING (npi)
GROUP BY npi, p1.nppes_provider_first_name, p1.nppes_provider_last_org_name, p1.specialty_description
ORDER BY total_claims DESC;


/*2. a. Which specialty had the most total number of claims (totaled over all drugs)?*/

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;


/*2. b. Which specialty had the most total number of claims for opioids?*/

--this is my filter that will got in my WHERE clause
SELECT drug_name
FROM prescription
	WHERE drug_name IN
	(SELECT drug_name
	FROM drug
	WHERE opioid_drug_flag = 'Y');

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
	WHERE drug_name IN
	(SELECT drug_name
	FROM drug
	WHERE opioid_drug_flag = 'Y')
GROUP BY specialty_description
ORDER BY total_claims DESC;

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
	INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

/*2. c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?*/

SELECT specialty_description AS specialty, 
	COUNT(DISTINCT drug_name) AS drug_count
FROM prescriber
	FULL JOIN prescription
	USING (npi)
GROUP BY specialty_description
ORDER BY drug_count;


/*2. d. **Difficult Bonus:***Do not attempt until you have solved all other problems!* 
For each specialty, report the percentage of total claims by that specialty which are for opioids. 
Which specialties have a high percentage of opioids?*/

/*3. a. Which drug (generic_name) had the highest total drug cost?*/

SELECT generic_name,
	SUM(total_drug_cost) AS cost
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
GROUP BY generic_name
ORDER BY cost DESC;


/*3. b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. 
Google ROUND to see how this works.***/

SELECT generic_name,
	   ROUND (SUM(total_drug_cost) / SUM(total_day_supply),2) AS cost_per_day
FROM prescription
	 LEFT JOIN drug
	 USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;


/*4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
and says 'neither' for all other drugs.*/

SELECT drug_name,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   ELSE 'neither' END AS drug_type
FROM drug;


/*4. b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
Hint: Format the total costs as MONEY for easier comparision.*/

SELECT SUM(total_drug_cost)::money,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   		ELSE 'neither' END AS drug_type
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type;


/*5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.*/

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';


/*5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.*/

--largest
WITH total_cbsa_pop AS (SELECT cbsa, SUM(population) AS cbsa_pop
						FROM cbsa
							LEFT JOIN population
							USING (fipscounty)
						WHERE population IS NOT NULL
						GROUP BY cbsa)
SELECT cbsa, MAX(cbsa_pop) AS largest_pop
FROM total_cbsa_pop
GROUP BY cbsa
ORDER BY largest_pop DESC
LIMIT 1;

--smallest
WITH total_cbsa_pop AS (SELECT cbsa, SUM(population) AS cbsa_pop
						FROM cbsa
							LEFT JOIN population
							USING (fipscounty)
						WHERE population IS NOT NULL
						GROUP BY cbsa)
SELECT cbsa, MIN(cbsa_pop) AS smallest_pop
FROM total_cbsa_pop
GROUP BY cbsa
ORDER BY smallest_pop
LIMIT 1;


/*5. c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.*/

SELECT county,
	   SUM(population) AS population
FROM population
	FULL JOIN cbsa
	USING (fipscounty)
	LEFT JOIN fips_county
	USING (fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY population DESC;


/*6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.*/

SELECT drug_name,
	   total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;


/*6. b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.*/

SELECT drug_name,
	   total_claim_count,
	   opioid_drug_flag
FROM prescription
	 LEFT JOIN drug
	 USING (drug_name)
WHERE total_claim_count >= 3000 AND opioid_drug_flag = 'Y';


/*6. c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.*/

SELECT drug_name,
	   total_claim_count,
	   opioid_drug_flag,
	   nppes_provider_first_name,
	   nppes_provider_last_org_name
FROM prescription
	 LEFT JOIN drug
	 USING (drug_name)
	 LEFT JOIN prescriber
	 ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000 AND opioid_drug_flag = 'Y';


/*7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
**Hint:** The results from all 3 parts will have 637 rows. 
a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') 
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
**Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.*/

SELECT npi,
	   drug_name
FROM prescriber
	 CROSS JOIN drug
WHERE opioid_drug_flag = 'Y' AND specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE';


/*7. b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
You should report the npi, the drug name, and the number of claims (total_claim_count).*/

WITH table1 AS (SELECT npi,
	   				 drug_name
					 FROM prescriber
	 				 CROSS JOIN drug
					 WHERE opioid_drug_flag = 'Y' 
			  		 AND specialty_description = 'Pain Management' 
			  		 AND nppes_provider_city = 'NASHVILLE')
SELECT table1.npi,
	   table1.drug_name,
	   COALESCE(COUNT(total_claim_count),0) AS claim_count
FROM table1
	 LEFT JOIN prescription
	 USING (npi)
GROUP BY table1.npi, table1.drug_name
ORDER BY claim_count DESC;


/*7. c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.*/
--Added this to 7b	 
	 
	 
	 
	 
	 
	 
	 
	 
	 