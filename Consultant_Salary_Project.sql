/*
Consultant Salaries Data Exploration 
Skills used: CTE's, Temporary Tables, Window Functions, Aggregate Functions, Subqueries, Converting Data Types
*/


/*   Compensation Data   */

# Average compensation for each position
	# SKILLS: Aggregate Function
SELECT job_title, ROUND(AVG(total_compensation), 2) AS avg_compensation
FROM consulting_dataset
WHERE job_title != 'Unknown'
GROUP BY job_title
ORDER BY avg_compensation desc;

# Average compensation for each company
	# SKILLS: Aggregate Window Function
SELECT firm_name, ROUND(AVG(total_compensation), 2) AS average_compensation, COUNT(firm_name) AS num_datapoints
FROM consulting_dataset
GROUP BY firm_name
ORDER BY average_compensation desc;

# Calculate average compensation for each job title at every firm
	# SKILLS: Aggregate Function
SELECT job_title, firm_name, ROUND(AVG(total_compensation), 2) AS avg_compensation
FROM consulting_dataset
WHERE firm_name NOT IN ('Not Applicable', 'No longer employed here')
GROUP BY job_title, firm_name
ORDER BY job_title, avg_compensation desc;

# Rank the current employees in each position at every company by total compensation,
# and compare to the average compensation for that position at every company
	#SKILLS: Ranking Window Function, Aggregate Window Function
SELECT RANK() OVER(PARTITION BY firm_name, job_title ORDER BY total_compensation desc) AS compensation_ranking,
		current_position,
		firm_name,
		job_title,
		base_salary_USD,
		bonus_USD,
		total_compensation,
		ROUND(AVG(total_compensation) OVER(PARTITION BY firm_name, job_title), 2) AS "AvgCompensationForPositionAtCompany"
FROM consulting_dataset
WHERE current_position = 'YES' AND firm_name NOT IN ('Not Applicable', 'No longer employed here');

# Output if employee's total compensation is >, < or = to the average for that job across all companies
	# SKILLS: Common Table Expression (CTE), CASE Statement, Aggregate Window Function, CONCAT
WITH avg_compensation AS (
	SELECT firm_name,
			job_title,
			base_salary_USD,
			bonus_USD,
			total_compensation,
			ROUND(AVG(total_compensation) OVER(PARTITION BY job_title), 2) AS AvgCompensationForPosition
	FROM consulting_dataset
	WHERE firm_name NOT IN ('Not Applicable', 'No longer employed here'))
SELECT *,
	CASE
		WHEN total_compensation < AvgCompensationForPosition THEN CONCAT("Their compensation is < than the average ", job_title)
		WHEN total_compensation > AvgCompensationForPosition THEN CONCAT("Their compensation is > than the average ", job_title)
		ELSE CONCAT("Their compensation is = to the average ", job_title)
	END AS compensation_comparison
FROM avg_compensation
ORDER BY firm_name, job_title, total_compensation;


/*   Weekly hours worked data.  */

# Weekly hours worked by all employees
	# SKILLS: Subquery, Aggregate Function, Aggregate Window Function
SELECT weekly_hours_worked,
		num_employees,
        ROUND((num_employees/(SUM(num_employees) OVER ()) * 100), 2) AS percentage_of_total_employees
FROM (SELECT weekly_hours_worked, COUNT(*) AS num_employees
		FROM consulting_dataset
		WHERE weekly_hours_worked != 'Not applicable/not currently working'
		GROUP BY weekly_hours_worked
		ORDER BY weekly_hours_worked) AS subquery;

# Weekly hours worked by position type
	# SKILLS: CTE, Aggregate Window Function, Aggregate Function
WITH hours_worked_byJob AS (		
	SELECT job_title, weekly_hours_worked, COUNT(*) AS num_employees
	FROM consulting_dataset
	WHERE job_title != 'Unknown' AND weekly_hours_worked != 'Not applicable/not currently working'
	GROUP BY job_title, weekly_hours_worked
	ORDER BY job_title)
SELECT *, ROUND((num_employees/(SUM(num_employees) OVER (PARTITION BY job_title)) * 100), 2) AS percentage_of_job_title
FROM hours_worked_byJob;

# Find weekly hours worked at each company as a count of employees and the percentage of total employees at company
	# SKILLS: Temporary Table, Aggregate Function, Aggregate Window Function    
DROP TEMPORARY TABLE IF EXISTS employee_count;
CREATE TEMPORARY TABLE employee_count AS
SELECT firm_name, weekly_hours_worked, COUNT(*) AS num_employees
FROM consulting_dataset
GROUP BY firm_name, weekly_hours_worked
ORDER BY firm_name, weekly_hours_worked;

SELECT firm_name,
		weekly_hours_worked,
        num_employees,
        ROUND((num_employees/(SUM(num_employees) OVER (PARTITION BY firm_name)) * 100), 2) AS percent_of_firm
FROM employee_count;


/*   Employee Data   */

# Number of employees from each company
	# SKILLS: CTE, Aggregate Function
WITH total AS (
	SELECT COUNT(*) AS total_employees
	FROM consulting_dataset),
	employees_per_company AS (
	SELECT firm_name, COUNT(*) AS num_employees_per_company
	FROM consulting_dataset
	GROUP BY firm_name)
SELECT firm_name,
		num_employees_per_company,
        ROUND((num_employees_per_company/total_employees) * 100, 2) AS percent_of_total_employees
FROM total, employees_per_company
ORDER BY percent_of_total_employees desc;

# Number of employees by job title
SELECT job_title, COUNT(*) AS num_employees_per_company
FROM consulting_dataset
GROUP BY job_title;


/*   Additional Queries   */
        
# Group by practice type
SELECT commercial_or_federal_practice, COUNT(*) AS num_employees 
FROM consulting_dataset
GROUP BY commercial_or_federal_practice
ORDER BY num_employees desc;

# Adding row numbers to table based on most recent survey submitted
	# SKILLS: Ranking Window Function
SELECT ROW_NUMBER() OVER(ORDER BY date_time desc) AS submission_id,
date_time,
current_position,
firm_name,
commercial_or_federal_practice,
job_title,
country,
base_salary_USD,
bonus_USD,
total_compensation,
weekly_hours_worked
FROM consulting_dataset;

# Converting date from string to standard sql datetime format
	# SKILLS: Converting Data Types
SELECT date_time, str_to_date(date_time, '%m/%d/%Y %H:%i:%s:%f') AS standard_datetime
FROM consulting_dataset;
