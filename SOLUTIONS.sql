

-- # FILE 1 Problem statement
-- Problem Statement 1:  Jimmy, from the healthcare department, has requested a report that shows how the number of treatments each age category of patients has gone through in the year 2022. 
-- The age category is as follows, Children (00-14 years), Youth (15-24 years), Adults (25-64 years), and Seniors (65 years and over).
-- Assist Jimmy in generating the report. 

with cte as(select floor(datediff(treatment.date,patient.dob)/365) as age from treatment
join patient
on treatment.patientID=patient.patientID
where year(treatment.date)=2022)
select case 
when cte.age <= 14 then "Children"
when cte.age between 15 and 24 then "Youth"
when cte.age between 25 and 64 then "Adult"
when cte.age>=65 then "Seniors"
end as category,count(*) as treatment_number
from cte
group by category; 
 

-- Problem Statement 2:  Jimmy, from the healthcare department, wants to know which disease is infecting people of which gender more often.
-- Assist Jimmy with this purpose by generating a report that shows for each disease the male-to-female ratio. Sort the data in a way that is helpful for Jimmy.

with cte as (select treatment.diseaseID as disease_id,person.gender,count(gender) as gen_count from person
join treatment on treatment.patientID=person.personID
group by person.gender,treatment.diseaseID),

cte1 as
(select disease_id,case
when gender = "female" then gen_count
end as female from cte ) ,

cte2 as
(select disease_id,case
when gender ="male" then gen_count
end as male from cte)

select cte1.disease_id,cte1.female,cte2.male/cte1.female from cte1  join cte2 using(disease_id)
where cte1.female is not null and cte2.male is not null order by cte1.disease_id
;
#--------------------------------------------------------------------------------------------------------
#file 2.2
SELECT 
    t.diseaseID,
    SUM(IF(p.gender = 'male', 1, 0)) AS male,
    SUM(IF(p.gender = 'female', 1, 0)) AS female,
    SUM(IF(p.gender = 'male', 1, 0)) / SUM(IF(p.gender = 'female', 1, 0)) AS ratio
FROM
    treatment t
        JOIN
    person p ON t.patientID = p.personID
GROUP BY diseaseID
ORDER BY diseaseID;


-- Problem Statement 3: Jacob, from insurance management, has noticed that insurance claims are not made for all the treatments. He also wants to figure out if the gender of the patient has any impact on the insurance claim. Assist Jacob in this situation by generating a report that finds for each gender the number of treatments, number of claims, and treatment-to-claim ratio. And notice if there is a significant difference between the treatment-to-claim ratio of male and female patients.

SELECT 
    person.gender,
    COUNT(treatment.treatmentID) AS Treatment_Count,
    COUNT(claim.claimID) Claim_Count,
    COUNT(treatment.treatmentID) / COUNT(claim.claimID) ratio
FROM
    person
        LEFT JOIN treatment ON person.personID = treatment.patientID
        LEFT JOIN  claim ON claim.claimID = treatment.claimID
GROUP BY person.gender;


-- Problem Statement 4: The Healthcare department wants a report about the inventory of pharmacies. Generate a report on their behalf that shows how many units of medicine each pharmacy has in their inventory, the total maximum retail price of those medicines, and the total price of all the medicines after discount. 
-- Note: discount field in keep signifies the percentage of discount on the maximum price.

SELECT 
    op.pharma,
    SUM(op.mprice),
    SUM(op.kquality),
    SUM(op.max_price),
    SUM(sales_after_disc)
FROM
    (SELECT 
        p.pharmacyID as pharma,
            m.maxPrice as mprice,
            k.quantity as kquality,
            k.quantity * m.maxPrice AS max_price,
            CASE
                WHEN k.discount != 0 THEN (k.quantity * m.maxPrice) - ((k.quantity * m.maxPrice) / k.discount)
                WHEN k.discount = 0 THEN k.quantity * m.maxPrice
            END AS sales_after_disc
    FROM pharmacy p
    JOIN keep k USING (pharmacyID)
    JOIN medicine m USING (medicineID)) as op
GROUP BY op.pharma;
#--------------------------------------------------------------------------------------------------------------------

SELECT 
    p.pharmacyID as pharma,
    SUM(k.quantity * m.maxPrice) AS total_max_price,
    SUM(k.quantity) AS total_quantity,
    SUM(k.quantity * m.maxPrice) AS total_sales,
    SUM(CASE WHEN k.discount != 0 THEN k.quantity * m.maxPrice - (k.quantity * m.maxPrice) / k.discount
             ELSE k.quantity * m.maxPrice END) AS total_sales_after_disc
FROM pharmacy p
JOIN keep k ON p.pharmacyID = k.pharmacyID
JOIN medicine m ON k.medicineID = m.medicineID
GROUP BY p.pharmacyID;


-- Problem Statement 5:  The healthcare department suspects that some pharmacies prescribe more medicines than others in a single prescription, for them, generate a report that finds for each pharmacy the maximum, minimum and average number of medicines prescribed in their prescriptions. 
SELECT 
    prescription.pharmacyID,
    MAX(contain.quantity) AS max_no_of_med,
    MIN(contain.quantity) AS min_no_of_med,
    ROUND(AVG(contain.quantity)) AS avg_no_of_med
FROM pharmacy
LEFT JOIN prescription ON pharmacy.pharmacyID = prescription.pharmacyID
LEFT JOIN contain ON contain.prescriptionID = prescription.prescriptionID
GROUP BY prescription.pharmacyID
ORDER BY prescription.pharmacyID
;

-- #FILE 2 Problem statement
-- Problem Statement 1: A company needs to set up 3 new pharmacies, they have come up with an idea that the pharmacy can be set up in cities where the pharmacy-to-prescription ratio is the lowest and the number of prescriptions should exceed 100. Assist the company to identify those cities where the pharmacy can be set up.

with cte as(select address.city,count(distinct pharmacy.pharmacyID) as count_pharmacy,count(prescription.prescriptionID) as count_prescription
from address
left join pharmacy on address.addressID=pharmacy.addressID
left join prescription on pharmacy.pharmacyID=prescription.pharmacyID
group by address.city,pharmacy.pharmacyID)

select city,sum(count_pharmacy) as pharmacy_count,sum(count_prescription) as prescription_count,
sum(count_pharmacy)/sum(count_prescription)as ratio
from cte
group by city
having  prescription_count>100
order by ratio limit 3;

-- Problem Statement 2: The State of Alabama (AL) is trying to manage its healthcare resources more
--  efficiently. For each city in their state, 
-- they need to identify the disease for which the maximum number of patients have gone for treatment. 
-- Assist the state for this purpose.
-- Note: The state of Alabama is represented as AL in Address Table.

with cte as(SELECT city, diseaseID, count_treat,
           MAX(count_treat) OVER(PARTITION BY city) AS max_treatment_count
    FROM (
        SELECT address.city, treatment.diseaseID, COUNT(treatment.treatmentID) AS count_treat
        FROM address
        JOIN person ON address.addressID = person.addressID
        JOIN patient ON patient.patientID = person.personID
        JOIN treatment ON patient.patientID = treatment.patientID
        WHERE address.state = "AL"
        GROUP BY address.city, treatment.diseaseID
    ) as cte)
SELECT cte.city, cte.diseaseID,disease.diseaseName, cte.count_treat
FROM cte
join disease on disease.diseaseID =cte.diseaseID
WHERE cte.count_treat = cte.max_treatment_count
order by cte.count_treat;

WITH cte AS (
   SELECT address.city,
      treatment.diseaseID,
      COUNT(treatment.treatmentID) AS count_treat,
      MAX(COUNT(treatment.treatmentID)) OVER (PARTITION BY address.city) AS max_treatment_count
   FROM address
   JOIN person ON address.addressID = person.addressID
   JOIN patient ON patient.patientID = person.personID
   JOIN treatment ON patient.patientID = treatment.patientID
   WHERE address.state = 'AL'
   GROUP BY address.city, treatment.diseaseID
)
SELECT
   cte.city,cte.diseaseID,disease.diseaseName,cte.count_treat
FROM cte
JOIN disease ON disease.diseaseID = cte.diseaseID
WHERE cte.count_treat = cte.max_treatment_count
ORDER BY cte.count_treat;


-- Problem Statement 3: The healthcare department needs a report about insurance plans. The report is required to include the insurance plan, which was claimed the most and least for each disease.Assist to create such a report.


WITH PlanCountRank AS (
    SELECT
        ip.diseaseID,
        ip.planName,
        COUNT(*) AS planCount,
        ROW_NUMBER() OVER (PARTITION BY ip.diseaseID ORDER BY COUNT(*) ASC) AS LowestRank,
        ROW_NUMBER() OVER (PARTITION BY ip.diseaseID ORDER BY COUNT(*) DESC) AS HighestRank
    FROM insuranceplan ip
    JOIN claim c ON c.uin = ip.uin
    JOIN treatment t ON t.claimID = c.claimID
    GROUP BY
        ip.diseaseID,
        ip.planName
)
SELECT
    pcr.diseaseID,
    pcr.planName AS LowestCountPlan,
    pch.planName AS HighestCountPlan,
    pcr.planCount AS LowestCount,
    pch.planCount AS HighestCount
FROM PlanCountRank pcr
JOIN PlanCountRank pch ON pcr.diseaseID = pch.diseaseID
WHERE pcr.LowestRank = 1 AND pch.HighestRank = 1
ORDER BY pcr.diseaseID;

                

-- Problem Statement 4: The Healthcare department wants to know which disease is most likely to infect multiple people in the same household. For each disease find the number of households that has more than one patient with the same disease. 
-- Note: 2 people are considered to be in the same household if they have the same address. 

with cte (numberOfPerson_sameHouse, addressID, diseaseID) as
(select count(person.personID) no_person_sameHouse,person.addressID, treatment.diseaseID
from person join patient on person.personID=patient.patientID
join treatment using(patientID)
group by treatment.diseaseID,person.addressID
having no_person_sameHouse>1
order by treatment.diseaseID)
    
select d.diseaseName ,count(cte.numberOfPerson_sameHouse) as `number of houses`
from cte join disease d on cte.diseaseID=d.diseaseID
group by cte.diseaseID;

#-----------------------------------------------------------------------------------------
SELECT 
    d.diseaseName,
    COUNT(cte.numberOfPerson_sameHouse) AS `number of houses`
FROM (
    SELECT 
        COUNT(p.personID) AS numberOfPerson_sameHouse,p.addressID,t.diseaseID
    FROM person p
    JOIN patient pt ON p.personID = pt.patientID
    JOIN treatment t ON pt.patientID = t.patientID
    GROUP BY t.diseaseID, p.addressID
    HAVING numberOfPerson_sameHouse > 1
) AS cte
JOIN disease d ON cte.diseaseID = d.diseaseID
GROUP BY cte.diseaseID
order by cte.diseaseID;
#------------------------------------------------------------------------------------
WITH cte AS (
    SELECT COUNT(p.personID) AS no_person_sameHouse, p.addressID,t.diseaseID
    FROM person p
    JOIN patient pt ON p.personID = pt.patientID
    JOIN treatment t ON pt.patientID = t.patientID
    GROUP BY t.diseaseID, p.addressID
    HAVING no_person_sameHouse > 1
    ORDER BY t.diseaseID
)
SELECT
    d.diseaseName,
    COUNT(cte.no_person_sameHouse) AS number_of_houses
FROM cte
JOIN disease d ON cte.diseaseID = d.diseaseID
GROUP BY cte.diseaseID;

#-----------------------------------------------------------------------------------------

-- Problem Statement 5:  An Insurance company wants a state wise report of the treatments to claim ratio between 1st April 2021 and 31st March 2022 (days both included). Assist them to create such a report.
select a.state, count(t.treatmentID)/count(t.claimID) `ratio_of_treatment_to_count`
from address a join person p using(addressID)
join patient pa on p.personID = pa.patientID
join treatment t  using(patientID)
where t.date between "2021-04-01" and "2022-03-31"
group by a.state
;


-- #FILE 3 Problem statement
-- Problem Statement 1:  Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine that they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, wants to get a report of which pharmacies have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. Assist Joshua to generate the report so that the pharmacies who prescribe hospital-exclusive medicine more often are advised to avoid such practice if possible.   

SELECT pharmacyName, pharmacyID, COUNT(pharmacyID) 
FROM pharmacy
JOIN prescription USING (pharmacyID)
JOIN treatment USING (treatmentID)
WHERE prescriptionID IN (SELECT DISTINCT(prescriptionID)
FROM contain
JOIN medicine USING (medicineID)
WHERE hospitalExclusive = 'S')
AND YEAR(treatment.date) IN ('2021' , '2022')
GROUP BY pharmacyID
ORDER BY COUNT(pharmacyID) DESC;


-- Problem Statement 2: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.
SELECT 
    insurancecompany.companyName,
    insuranceplan.planName,
    COUNT(treatmentID)
FROM insurancecompany
JOIN insuranceplan ON insuranceplan.companyID = insurancecompany.companyID
JOIN claim ON claim.uin = insuranceplan.uin
JOIN treatment ON treatment.claimID = claim.claimID
GROUP BY insurancecompany.companyName , insuranceplan.planName;


-- Problem Statement 3: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance companys name with their most and least claimed insurance plans.

with cte as (select planName,companyName,companyID
from insurancecompany join
insuranceplan using (companyID) join claim using(uin)
join treatment using (claimID)
group by planName,companyID)

select companyName,max(planName) as mostclaimed, min(planName) as minclaimed
from cte group by companyID;
#---------------------------------------------------------------------------------------
SELECT
    ic.companyName,
    MAX(ip.planName) AS mostclaimed,
    MIN(ip.planName) AS minclaimed
FROM insurancecompany ic
JOIN insuranceplan ip ON ic.companyID = ip.companyID
JOIN claim c ON ip.uin = c.uin
JOIN treatment t ON c.claimID = t.claimID
GROUP BY ic.companyID, ic.companyName;


-- Problem Statement 4:  The healthcare department wants a state-wise health report to assess which state requires more attention in the healthcare sector. Generate a report for them that shows the state name, number of registered people in the state, number of registered patients in the state, and the people-to-patient ratio. sort the data by people-to-patient ratio. 


SELECT 
    state,
    COUNT(DISTINCT (personID)) AS persons,COUNT(DISTINCT (patientID)) AS patients,
    COUNT(DISTINCT (personID)) / COUNT(DISTINCT (patientID)) AS person_to_patient_ratio
FROM
    address
        LEFT JOIN
    person USING (addressID)
        LEFT JOIN
    patient ON person.personID = patient.patientID
GROUP BY state;


-- Problem Statement 5:  Jhonny, from the finance department of Arizona(AZ), has requested a report that lists the total quantity of medicine each pharmacy in his state has prescribed that falls under Tax criteria I for treatments that took place in 2021. Assist Jhonny in generating the report. 

with t as (select prescriptionID,sum(quantity) as quantity
from  contain
join medicine using (medicineID) 
where taxCriteria='I'
group by prescriptionID),
d as(select pharmacyID,prescriptionID
from treatment
join prescription
using (treatmentID)
where year(date)=2021),
s as (select distinct(pharmacyID) , pharmacyName
from address join pharmacy
using (addressID) where state='AZ')
select pharmacyID,pharmacyName, sum(quantity) from t join d 
using(prescriptionID) join
s using (pharmacyID)
group by pharmacyID;



-- # FILE 4 sql case

-- Problem Statement 1: 
-- “HealthDirect” pharmacy finds it difficult to deal with the product type of medicine being displayed in numerical form, they want the product type in words. Also, they want to filter the medicines based on tax criteria. 

-- Display only the medicines of product categories 1, 2, and 3 for medicines that come under tax category I and medicines of product categories 4, 5, and 6 for medicines that come under tax category II

-- Write a SQL query to solve this problem.
-- ProductType numerical form and ProductType in words are given by
-- 1 - Generic, 
-- 2 - Patent, 
-- 3 - Reference, 
-- 4 - Similar,
-- 5 - New, 
-- 6 - Specific,
-- 7 - Biological, 
-- 8 – Dinamized
-- 3 random rows and the column names of the Medicine table are given for reference.
-- Medicine (medicineID, companyName, productName, description, substanceName, productType, taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice)
-- 12	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	OXALIPLATINA	100 MG PO LIOFILIZADO FR/AMP X 1000 MG	NC/NI	1	I	N	N	N	2373.63
-- 13	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	SULBACTAM SODICO + AMPICILINA SODICA	1 G + 2 G CT FR AMP VD INC	NC/NI	4	II	N	N	N	29.59
-- 14	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	PACLITAXEL	6 MG/ML SOL INJ CT FR/AMP X 50 ML	NC/NI	1	I	N	N	N	4122.12


select medicineID,productName,productType,taxCriteria,
case
when productType=1 then "Generic"
when productType=2 then "Patent"
when productType=3 then "Reference"
when productType=4 then "Similar"
when productType=5 then "New"
when productType=6 then "Specific"
when productType=7 then "Biological"
when productType=8 then "Dinamized"
end as producttype_word
from medicine
where productType in (1,2,3) and taxCriteria in("I") or  productType in (4,5,6) and taxCriteria in("II");



-- Problem Statement 2:  
-- 'Ally Scripts' pharmacy company wants to find out the quantity of medicine prescribed in each of its prescriptions.
-- Write a query that finds the sum of the quantity of all the medicines in a prescription and if the total quantity of medicine is less than 20 tag it as “low quantity”. 
-- If the quantity of medicine is from 20 to 49 (both numbers including) tag it as “medium quantity“ and if the quantity is more than equal to 50 then tag it as “high quantity”.
-- Show the prescription Id, the Total Quantity of all the medicines in that prescription, and the Quantity tag for all the prescriptions issued by 'Ally Scripts'.

-- 3 rows from the resultant table may be as follows:
-- prescriptionID	totalQuantity	Tag
-- 1147561399		43				Medium Quantity
-- 1222719376		71				High Quantity
-- 1408276190		48				Medium Quantity

with cte as(select prescription.prescriptionID,sum(contain.quantity) as totalQuantity 
from prescription
join contain 
on prescription.prescriptionID=contain.prescriptionID
group by prescription.prescriptionID)

select cte.*,
case 
when cte.totalQuantity < 20 then "Low Quantity"
when cte.totalQuantity between 20 and 49 then "Medium Quantity"
when cte.totalQuantity >= 50 then "High Quantity"
end as Tag
from cte;

#---------------------------------------------------------------------------------
SELECT
    cte.*,
    CASE
        WHEN cte.totalQuantity < 20 THEN 'Low Quantity'
        WHEN cte.totalQuantity BETWEEN 20 AND 49 THEN 'Medium Quantity'
        WHEN cte.totalQuantity >= 50 THEN 'High Quantity'
    END AS Tag
FROM (
    SELECT
        p.prescriptionID,
        SUM(c.quantity) AS totalQuantity
    FROM prescription p
    JOIN contain c ON p.prescriptionID = c.prescriptionID
    GROUP BY p.prescriptionID
) AS cte;

-- Problem Statement 3: 
-- In the Inventory of a pharmacy 'Spot Rx' the quantity of medicine is considered ‘HIGH QUANTITY’ when the quantity exceeds 7500 and ‘LOW QUANTITY’ when the quantity falls short of 1000. The discount is considered “HIGH” if the discount rate on a product is 30% or higher, and the discount is considered “NONE” when the discount rate on a product is 0%.
--  'Spot Rx' needs to find all the Low quantity products with high discounts and all the high-quantity products with no discount so they can adjust the discount rate according to the demand. 
-- Write a query for the pharmacy listing all the necessary details relevant to the given requirement.
-- Hint: Inventory is reflected in the Keep table.

select pharmacy.pharmacyName,keep.medicineID,keep.quantity,keep.discount,
case when keep.quantity> 7500 then "HIGH QUANTITY"
when keep.quantity< 1000 then "LESS QUANTITY"
else "MEDIUM QUANTITY"
end as quantity_category,
case when keep.discount>= 30 then "HIGH "
when keep.discount= 0 then "None"
ELSE "LOW"
end as discount_category
from pharmacy
join keep
on pharmacy.pharmacyID=keep.pharmacyID
where pharmacy.pharmacyName='Spot Rx';

-- Problem Statement 4: 
-- Mack, From HealthDirect Pharmacy, wants to get a list of all the affordable and costly, hospital-exclusive medicines in the database. Where affordable medicines are the medicines that have a maximum price of less than 50% of the avg maximum price of all the medicines in the database, and costly medicines are the medicines that have a maximum price of more than double the avg maximum price of all the medicines in the database.  Mack wants clear text next to each medicine name to be displayed that identifies the medicine as affordable or costly. The medicines that do not fall under either of the two categories need not be displayed.
-- Write a SQL query for Mack for this requirement.

select * from(select medicine.medicineID,medicine.maxPrice,round((select avg(medicine.maxPrice) from medicine),2) as avg_price,
case when medicine.maxPrice > (round((select avg
(medicine.maxPrice) from medicine),2) *2)then "Costly"
when medicine.maxPrice < (round((select avg(medicine.maxPrice) from medicine),2)/2) then "Affordable"
end as category_med
from medicine
) as pd
where pd.category_med is not null
;

-- Problem Statement 5:  

-- The healthcare department wants to categorize the patients into the following category.
-- YoungMale: Born on or after 1st Jan  2005  and gender male.
-- YoungFemale: Born on or after 1st Jan  2005  and gender female.
-- AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
-- AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
-- MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
-- MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
-- ElderMale: Born before 1st Jan 1970, and gender male.
-- ElderFemale: Born before 1st Jan 1970, and gender female.

-- Write a SQL query to list all the patient name, gender, dob, and their category.

select patient.patientID,person.personName,person.gender,patient.dob,
case
when dob >="2005-01-01" and gender="male" then "YoungMale"
when dob < "2005-01-01" and gender="female" then "YoungFemale"
when dob <"2005-01-01" and dob >="1985-01-01" and gender="male" then "AdultMale"
when dob <"2005-01-01" and dob >="1985-01-01" and gender="female" then "AdultFemale"
when dob <"1985-01-01" and dob >="1970-01-01" and gender="male" then "MidAgeMale"
when dob <"1985-01-01" and dob >="1970-01-01" and gender="female" then "MidAgeFemale"
when dob <"1970-01-01" and gender="male" then "ElderMale"
when dob <"1970-01-01" and gender="female" then "ElderFemale"
end as categorize
from person 
join patient
on person.personID=patient.patientID;

-- #FILE 5 grouping 2

-- Problem Statement 1: 
-- Johansson is trying to prepare a report on patients who have gone through treatments more than once. Help Johansson prepare a report that shows the patients name, the number of treatments they have undergone, and their age, Sort the data in a way that the patients who have undergone more treatments appear on top.
select p.personName,count(t.treatmentID) as treatment_count,
    (select timestampdiff(year,dob,now()) 
    from patient 
	where p.personID = patientID
	) as age
from person p 
join patient pa on pa.patientID=p.personID
join treatment t using(patientID)
group by  p.personID
having  count(t.treatmentID)>1
order by count(t.treatmentID) desc
;
#--------------------------------------------------------
SELECT
    p.personName,
    COUNT(t.treatmentID) AS treatment_count,
    TIMESTAMPDIFF(YEAR, pa.dob, NOW()) AS age
FROM person p
JOIN patient pa ON pa.patientID = p.personID
JOIN treatment t ON pa.patientID = t.patientID
GROUP BY p.personID
HAVING treatment_count > 1
ORDER BY treatment_count DESC;

-- Problem Statement 2:  
-- Bharat is researching the impact of gender on different diseases, He wants to analyze if a certain disease is more likely to infect a certain gender or not.
-- Help Bharat analyze this by creating a report showing for every disease how many males and females underwent treatment for each in the year 2021. It would also be helpful for Bharat if the male-to-female ratio is also shown.
SELECT 
    treatment.diseaseID AS disease_id,
    SUM(IF(gender = 'female', 1, 0)) AS female,
    SUM(IF(gender = 'male', 1, 0)) AS male,
    SUM(IF(gender = 'male', 1, 0)) / SUM(IF(gender = 'female', 1, 0)) AS ratio_male_To_female
FROM person
JOIN treatment ON treatment.patientID = person.personID
GROUP BY disease_id
ORDER BY treatment.diseaseID;

-- Problem Statement 3:  
-- Kelly, from the Fortis Hospital management, has requested a report that shows for each disease, the top 3 cities that had the most number treatment for that disease.
-- Generate a report for Kelly’s requirement.

select * from (
select a.city, d.diseaseName, count(t.patientID) as count_p, 
dense_rank() over (partition by a.city order by count(t.patientID) desc) as rankk
from treatment t
join disease d on d.diseaseID = t.diseaseID
join person p on p.personID = t.patientID
join address a on a.addressID = p.addressID
group by a.city, d.diseaseName) d
where d.rankk in (1,2,3);





-- Problem Statement 4: 
-- Brooke is trying to figure out if patients with a particular disease are preferring some pharmacies over others or not, For this purpose, she has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for each disease in 2021 and 2022, She expects the number of prescriptions prescribed in 2021 and 2022 be displayed in two separate columns.
-- Write a query for Brooke’s requirement.

select 
	ph.pharmacyName,
    count(pr.prescriptionID) ``,
    d.diseaseName,
    sum(if(year(t.date)=2022,1,0)) as `2022`,
    sum(if(year(t.date)=2021,1,0)) as `2021`
from pharmacy ph 
join prescription pr using(pharmacyID)
join treatment t using(treatmentID)
join disease d using(diseaseID)
where year(t.date) = 2022 or year(t.date)=2021
group by ph.pharmacyName,d.diseaseName
order by d.diseaseName,ph.pharmacyName
;


-- Problem Statement 5:  
-- Walde, from Rock tower insurance, has sent a requirement for a report that presents which insurance company is targeting the patients of which state the most. 
-- Write a query for Walde that fulfills the requirement of Walde.
-- Note: We can assume that the insurance company is targeting a region more if the patients of that region are claiming more insurance of that company.

SELECT 
    subquery.state,
    subquery.companyName,
    subquery.max_count,
    MAX(subquery.max_count) AS targeting_count
FROM (
    SELECT 
        a.state,
        ic.companyName,
        COUNT(t.claimID) AS max_count
    FROM 
        insurancecompany ic
    JOIN address a USING (addressID)
    JOIN insuranceplan ip USING (companyID)
    JOIN person p USING (addressID)
    JOIN patient pa ON pa.patientID = p.personID
    JOIN treatment t USING (patientID)
    GROUP BY
        a.state,
        ic.companyName
) subquery
GROUP BY
    subquery.state,
    subquery.companyName
HAVING max_count = MAX(subquery.max_count);

-- # FILE 6 grouping


-- Problem Statement 1: 
-- The healthcare department wants a pharmacy report on the percentage of hospital-exclusive medicine prescribed in the year 2022.
-- Assist the healthcare department to view for each pharmacy, the pharmacy id, pharmacy name, total quantity of medicine prescribed in 2022, total quantity of hospital-exclusive medicine prescribed by the pharmacy in 2022, and the percentage of hospital-exclusive medicine to the total medicine prescribed in 2022.
-- Order the result in descending order of the percentage found. 

SELECT 
    pharmacy.pharmacyID,
    pharmacy.pharmacyName,
    SUM(contain.quantity) AS total_quantity_medicine
FROM pharmacy
JOIN prescription ON pharmacy.pharmacyID = prescription.pharmacyID
JOIN contain ON contain.prescriptionID = prescription.prescriptionID
JOIN treatment ON prescription.treatmentID = treatment.treatmentID
WHERE YEAR(treatment.date) = 2022
GROUP BY pharmacy.pharmacyID
;

-- Problem Statement 2:  
-- Sarah, from the healthcare department, has noticed many people do not claim insurance for their treatment. She has requested a state-wise report of the percentage of treatments that took place without claiming insurance. Assist Sarah by creating a report as per her requirement.

SELECT 
    address.state,
    COUNT(treatment.treatmentID) AS total_treatments,
    SUM(CASE
        WHEN treatment.claimID IS NULL THEN 1
        ELSE 0
    END) AS treatments_without_claim,
    (SUM(CASE
        WHEN treatment.claimID IS NULL THEN 1
        ELSE 0
    END) / COUNT(treatment.treatmentID)) * 100 AS percentage_without_claim
FROM address
LEFT JOIN person ON address.addressID = person.addressID
LEFT JOIN patient ON patient.patientID = person.personID
LEFT JOIN treatment ON treatment.patientID = patient.patientID
LEFT JOIN claim ON claim.claimID = treatment.claimID
GROUP BY address.state;
#======================================================================

SELECT 
    a.state,
    COUNT(t.treatmentID) AS total_treatments,
    SUM(CASE WHEN t.claimID IS NULL THEN 1 ELSE 0 END) AS treatments_without_claim,
    (SUM(CASE WHEN t.claimID IS NULL THEN 1 ELSE 0 END) / COUNT(t.treatmentID)) * 100 AS percentage_without_claim
FROM address a
LEFT JOIN person p ON a.addressID = p.addressID
LEFT JOIN patient pt ON pt.patientID = p.personID
LEFT JOIN treatment t ON pt.patientID = t.patientID
LEFT JOIN claim c ON c.claimID = t.claimID
GROUP BY a.state;

-- file 6  Problem Statement 3:  
-- Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. Assist Sarah by creating a report which shows for each state, the number of the most and least treated diseases by the patients of that state in the year 2022. 

with cte as(select state,diseaseID as max_disease_id from(select state,diseaseID,cc,max(cc) over(partition by state) as maxii from (select 
address.state,
	treatment.diseaseID,
    count(treatment.treatmentID) as cc
 FROM address
LEFT JOIN person ON address.addressID = person.addressID
LEFT JOIN patient ON patient.patientID = person.personID
LEFT JOIN treatment ON treatment.patientID = patient.patientID
where treatment.diseaseID is not null 
group by address.state,treatment.diseaseID
) op)opp
where maxii=cc),

cte1 as(select state,diseaseID as min_disease_id from(select state,diseaseID,cc,min(cc) over(partition by state) as mini 
from (select 
address.state,treatment.diseaseID,count(treatment.treatmentID) as cc
FROM address
LEFT JOIN   person ON address.addressID = person.addressID
LEFT JOIN patient ON patient.patientID = person.personID
LEFT JOIN treatment ON treatment.patientID = patient.patientID
where treatment.diseaseID is not null 
group by address.state,treatment.diseaseID
) op)opp
where mini=cc)

select cte.state,max_disease_id,min_disease_id from cte
left join cte1
on cte.state=cte1.state
;
#---------------------------------------------------------------------------------------------------------
WITH StateDiseaseCounts AS (
    SELECT 
        a.state,
        t.diseaseID,
        COUNT(t.treatmentID) AS treatment_count,
        RANK() OVER (PARTITION BY a.state ORDER BY COUNT(t.treatmentID) DESC) AS max_rank,
        RANK() OVER (PARTITION BY a.state ORDER BY COUNT(t.treatmentID) ASC) AS min_rank
    FROM address a
     JOIN person p ON a.addressID = p.addressID
     JOIN patient pt ON pt.patientID = p.personID
     JOIN treatment t ON pt.patientID = t.patientID
    WHERE t.diseaseID IS NOT NULL
    GROUP BY a.state, t.diseaseID
)
SELECT 
    sdc.state,
    sdc.diseaseID AS max_disease_id,
    sdc_min.diseaseID AS min_disease_id
FROM StateDiseaseCounts sdc
 JOIN StateDiseaseCounts sdc_min ON sdc.state = sdc_min.state AND sdc_min.min_rank = 1
WHERE sdc.max_rank = 1;



-- Problem Statement 4: 
-- Manish, from the healthcare department, wants to know how many registered people are registered as patients as well, in each city. Generate a report that shows each city that has 10 or more registered people belonging to it and the number of patients from that city as well as the percentage of the patient with respect to the registered people.



SELECT 
    city,
    registered_people,
    registered_patient,
    (registered_patient / registered_people) * 100
FROM
    (SELECT 
        address.city,
            COUNT(person.personID) AS registered_people,
            COUNT(patient.patientID) AS registered_patient
    FROM
        person
    LEFT JOIN patient ON patient.patientID = person.personID
    JOIN address ON person.addressID = address.addressID
    GROUP BY address.city
    HAVING registered_people >= 10
        AND registered_patient >= 10) op;


-- Problem Statement 5:  
-- It is suspected by healthcare research department that the substance “ranitidine” might be causing some side effects. Find the top 3 companies using the substance in their medicine so that they can be informed about it.


select  companyName, count(productName) as cc_substance
from medicine
where substanceName like "%ranitidina%"
group by companyName 
order by count(productName) desc
limit 3
;

-- #FILE 7 if then else
-- Problem Statement 1:
-- Insurance companies want to know if a disease is claimed higher or lower than average.  Write a stored procedure that returns 
-- “claimed higher than average” or “claimed lower than average” when the diseaseID is passed to it. 
-- Hint: Find average number of insurance claims for all the diseases.  If the number of claims for the passed disease is higher 
-- than the average return “claimed higher than average” otherwise “claimed lower than average”.
delimiter $$

create procedure rate_of_claim (in diseaseId int, out rate varchar(150))
begin
declare avg_claim, claimed int default 0;

start transaction;
SELECT 
    COUNT(DISTINCT c.claimID) / COUNT(DISTINCT d.diseaseID)
INTO avg_claim FROM
    treatment t
        JOIN
    claim c ON t.claimID = c.claimID
        JOIN
    disease d ON t.diseaseID = d.diseaseID;

SELECT 
    COUNT(d.diseaseID)
INTO claimed FROM
    treatment t
        JOIN
    claim c ON t.claimID = c.claimID
        JOIN
    disease d ON t.diseaseID = d.diseaseID
WHERE
    d.diseaseID = diseaseID;

if claimed > avg_claim then 
set rate = 'claimed higher than average';
else set rate = 'claimed lower than average';
end if;

end$$

delimiter ;

call rate_of_claim(1, @rate);

select @rate;

-- Problem Statement 2:  
-- Joseph from Healthcare department has requested for an application which helps him get genderwise report for any disease. 
-- Write a stored procedure when passed a disease_id returns 4 columns,
-- disease_name, number_of_male_treated, number_of_female_treated, more_treated_gender
-- Where, more_treated_gender is either ‘male’ or ‘female’ based on which gender underwent more often for the disease, if the number
--  is same for both the genders, the value should be ‘same’.
delimiter $$

create procedure genderwise_report (in diseaseID int)
begin


SELECT 
    d.diseaseName,
    SUM(IF(p.gender = 'male', 1, 0)) AS number_of_male_treated,
    SUM(IF(p.gender = 'female', 1, 0)) AS number_of_male_treated,
    CASE
        WHEN SUM(IF(p.gender = 'male', 1, 0)) < SUM(IF(p.gender = 'female', 1, 0)) THEN 'female'
        ELSE 'male'
    END AS most_treated_gender
FROM
    disease d
        JOIN
    treatment t ON t.diseaseID = d.diseaseID
        JOIN
    person p ON p.personID = t.patientID
WHERE
    d.diseaseID = diseaseID
GROUP BY d.diseaseName;

end $$
delimiter ;

call genderwise_report(12);
drop procedure genderwise_report;
-- Problem Statement 3:  
-- The insurance companies want a report on the claims of different insurance plans. 
-- Write a query that finds the top 3 most and top 3 least claimed insurance plans.
-- The query is expected to return the insurance plan name, the insurance company name which has that plan, and whether the plan is the most claimed or least claimed. 

WITH ClaimsCount AS (
    SELECT
        insuranceplan.planName,
        insurancecompany.companyName,
        COUNT(claim.uin) AS claimCount
    FROM insuranceplan 
    JOIN claim  ON insuranceplan.uin = claim.uin
    JOIN insurancecompany  ON insuranceplan.companyID = insurancecompany.companyID
    GROUP BY insuranceplan.planName, insurancecompany.companyName
),
RankedClaims AS (
    SELECT
        planName,
        companyName,
        claimCount,
        RANK() OVER (PARTITION BY companyName ORDER BY claimCount DESC) AS mostClaimedRank,
        RANK() OVER (PARTITION BY companyName ORDER BY claimCount ASC) AS leastClaimedRank
    FROM ClaimsCount
)
SELECT planName,companyName,
CASE
        WHEN mostClaimedRank <= 3 THEN 'Most Claimed'
        ELSE 'Least Claimed'
    END AS claimStatus
FROM RankedClaims
WHERE mostClaimedRank <= 3 OR leastClaimedRank <= 3;
    

-- Problem Statement 4: 
-- The healthcare department wants to know which category of patients is being affected the most by each disease.
-- Assist the department in creating a report regarding this.
-- Provided the healthcare department has categorized the patients into the following category.
-- YoungMale: Born on or after 1st Jan  2005  and gender male.
-- YoungFemale: Born on or after 1st Jan  2005  and gender female.
-- AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
-- AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
-- MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
-- MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
-- ElderMale: Born before 1st Jan 1970, and gender male.
-- ElderFemale: Born before 1st Jan 1970, and gender female.


SELECT patient.patientID, person.personName, person.gender, patient.dob,
    IF(dob >= "2005-01-01" AND gender = "male", "YoungMale",
    IF(dob < "2005-01-01" AND gender = "female", "YoungFemale",
    IF(dob < "2005-01-01" AND dob >= "1985-01-01" AND gender = "male", "AdultMale",
    IF(dob < "2005-01-01" AND dob >= "1985-01-01" AND gender = "female", "AdultFemale",
    IF(dob < "1985-01-01" AND dob >= "1970-01-01" AND gender = "male", "MidAgeMale",
    IF(dob < "1985-01-01" AND dob >= "1970-01-01" AND gender = "female", "MidAgeFemale",
    IF(dob < "1970-01-01" AND gender = "male", "ElderMale",
    IF(dob < "1970-01-01" AND gender = "female", "ElderFemale", NULL)))))))) AS categorize
FROM person
JOIN patient ON person.personID = patient.patientID;



-- Problem Statement 5:  
-- Anna wants a report on the pricing of the medicine. She wants a list of the most expensive and most affordable medicines only. 
-- Assist anna by creating a report of all the medicines which are pricey and affordable, listing the companyName, productName, description, maxPrice, and the price category of each. Sort the list in descending order of the maxPrice.
-- Note: A medicine is considered to be “pricey” if the max price exceeds 1000 and “affordable” if the price is under 5. Write a query to find 

SELECT 
    companyName,
    productName,
    description,
    maxPrice,
    IF(maxPrice > 1000,'Pricey',
        IF(maxPrice < 5, 'Affordable', NULL)) AS price_category
FROM
    medicine
ORDER BY maxPrice;


-- # FILE 8

-- The healthcare department attempting to use the resources more efficiently. It already has some queries that are being used for different purposes. The management suspects that these queries might not be efficient so they have requested to optimize the existing queries wherever necessary.

-- Given are some queries written in SQL server which may be optimized if necessary.

-- Query 1: 
-- For each age(in years), how many patients have gone for treatment?
-- SELECT DATEDIFF(hour, dob , GETDATE())/8766 AS age, count(*) AS numTreatments
-- FROM Person
-- JOIN Patient ON Patient.patientID = Person.personID
-- JOIN Treatment ON Treatment.patientID = Patient.patientID
-- group by DATEDIFF(hour, dob , GETDATE())/8766
-- order by numTreatments desc;
SELECT 
    DATEDIFF(CURDATE(), dob) / 365 AS age,
    COUNT(treatment.treatmentID) AS numTreatments
FROM Patient
JOIN Treatment ON Treatment.patientID = Patient.patientID
GROUP BY DATEDIFF(CURDATE(), dob) / 365
ORDER BY numTreatments DESC;

-- Query 2: 
-- For each city, Find the number of registered people, number of pharmacies, and number of insurance companies.

-- drop table if exists T1;
-- drop table if exists T2;
-- drop table if exists T3;

-- select Address.city, count(Pharmacy.pharmacyID) as numPharmacy
-- into T1
-- from Pharmacy right join Address on Pharmacy.addressID = Address.addressID
-- group by city
-- order by count(Pharmacy.pharmacyID) desc;

-- select Address.city, count(InsuranceCompany.companyID) as numInsuranceCompany
-- into T2
-- from InsuranceCompany right join Address on InsuranceCompany.addressID = Address.addressID
-- group by city
-- order by count(InsuranceCompany.companyID) desc;

-- select Address.city, count(Person.personID) as numRegisteredPeople
-- into T3
-- from Person right join Address on Person.addressID = Address.addressID
-- group by city
-- order by count(Person.personID) desc;

-- select T1.city, T3.numRegisteredPeople, T2.numInsuranceCompany, T1.numPharmacy
-- from T1, T2, T3
-- where T1.city = T2.city and T2.city = T3.city
-- order by numRegisteredPeople desc;
select
	a.city, count(p.personID), count(i.companyID), count(ph.pharmacyID)
from address a left join insurancecompany i using(addressID)
left join pharmacy ph using(addressID)
left join person p using(addressID)
group by a.city;


-- Query 3: 
-- Total quantity of medicine for each prescription prescribed by Ally Scripts
-- If the total quantity of medicine is less than 20 tag it as "Low Quantity".
-- If the total quantity of medicine is from 20 to 49 (both numbers including) tag it as "Medium Quantity".
-- If the quantity is more than equal to 50 then tag it as "High quantity".

SELECT 
    C.prescriptionID,
    SUM(C.quantity) AS totalQuantity,
    CASE
        WHEN SUM(C.quantity) < 20 THEN 'Low Quantity'
        WHEN SUM(C.quantity) < 50 THEN 'Medium Quantity'
        ELSE 'High Quantity'
    END AS Tag
FROM Contain C
JOIN Prescription P USING (prescriptionID)
JOIN Pharmacy USING (pharmacyID)
WHERE Pharmacy.pharmacyName = 'Ally Scripts'
GROUP BY C.prescriptionID;


-- Query 4: 
-- The total quantity of medicine in a prescription is the sum of the quantity of all the medicines in the prescription.
-- Select the prescriptions for which the total quantity of medicine exceeds
-- the avg of the total quantity of medicines for all the prescriptions.

-- drop table if exists T1;
-- select Pharmacy.pharmacyID, Prescription.prescriptionID, sum(quantity) as totalQuantity
-- into T1
-- from Pharmacy
-- join Prescription on Pharmacy.pharmacyID = Prescription.pharmacyID
-- join Contain on Contain.prescriptionID = Prescription.prescriptionID
-- join Medicine on Medicine.medicineID = Contain.medicineID
-- join Treatment on Treatment.treatmentID = Prescription.treatmentID
-- where YEAR(date) = 2022
-- group by Pharmacy.pharmacyID, Prescription.prescriptionID
-- order by Pharmacy.pharmacyID, Prescription.prescriptionID;

-- select * from T1
-- where totalQuantity > (select avg(totalQuantity) from T1);

with cte as(
select 
	p.pharmacyID,pr.prescriptionID,sum(c.quantity) as totalQuantity
from pharmacy p join prescription pr using(pharmacyID)
join contain c using(prescriptionID)
join medicine m using(medicineID)
join treatment t using(treatmentID)
where year(t.date)=2022
group by p.pharmacyID,pr.prescriptionID
)
select * from cte 
where totalQuantity > (select avg(totalQuantity) from cte);


-- Query 5: 

-- Select every disease that has 'p' in its name, and 
-- the number of times an insurance claim was made for each of them. 

-- SELECT Disease.diseaseName, COUNT(*) as numClaims
-- FROM Disease
-- JOIN Treatment ON Disease.diseaseID = Treatment.diseaseID
-- JOIN Claim On Treatment.claimID = Claim.claimID
-- WHERE diseaseName IN (SELECT diseaseName from Disease where diseaseName LIKE '%p%')
-- GROUP BY diseaseName;

select d.diseaseName,count(t.claimID)
from treatment t join disease d using(diseaseID)
group by d.diseaseName;




-- # FILE 9 roll up

-- Problem Statement 1: 
-- Brian, the healthcare department, has requested for a report that shows for each state how many people underwent treatment for the disease “Autism”.  He expects the report to show the data for each state as well as each gender and for each state and gender combination. 
-- Prepare a report for Brian for his requirement.

SELECT
    IFNULL(address.state, 'Total') AS state,
    IFNULL(person.gender, 'Total') AS gender,
    COUNT(treatment.treatmentID) AS count_treatment
FROM address
JOIN person ON address.addressID = person.addressID
JOIN patient ON patient.patientID = person.personID
JOIN treatment ON patient.patientID = treatment.patientID
WHERE treatment.diseaseID = 8
GROUP BY address.state, person.gender
WITH ROLLUP;



-- Problem Statement 2:  
-- Insurance companies want to evaluate the performance of different insurance plans they offer. 
-- Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for. The report would be more relevant if the data compares the performance for different years(2020, 2021 and 2022) and if the report also includes the total number of claims in the different years, as well as the total number of claims for each plan in all 3 years combined.


SELECT 
    IFNULL(YEAR(treatment.date), 'Total') AS yr,
    IFNULL(insuranceplan.planName, 'Total') AS PlanName,
    COUNT(*) AS total_claims
FROM insurancecompany
JOIN insuranceplan ON insuranceplan.companyID = insurancecompany.companyID
JOIN claim ON insuranceplan.uin = claim.uin
JOIN treatment ON treatment.claimID = claim.claimID
GROUP BY yr , insuranceplan.planName 
WITH ROLLUP
;


-- Problem Statement 3:  
-- Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. Assist Sarah by creating a report which shows each state the number of the most and least treated diseases by the patients of that state in the year 2022. It would be helpful for Sarah if the aggregation for the different combinations is found as well. Assist Sarah to create this report. 

with cte as(select state,diseaseID as max_disease_id from(select state,diseaseID,cc,max(cc) over(partition by state) as maxii from (select 
address.state,
	treatment.diseaseID,
    count(treatment.treatmentID) as cc
 FROM address
LEFT JOIN person ON address.addressID = person.addressID
LEFT JOIN patient ON patient.patientID = person.personID
LEFT JOIN treatment ON treatment.patientID = patient.patientID
where treatment.diseaseID is not null 
group by address.state,treatment.diseaseID
) op)opp
where maxii=cc),

cte1 as(select state,diseaseID as min_disease_id from(select state,diseaseID,cc,min(cc) over(partition by state) as mini from (select 
address.state,
	treatment.diseaseID,
    count(treatment.treatmentID) as cc
FROM address
LEFT JOIN person ON address.addressID = person.addressID
LEFT JOIN patient ON patient.patientID = person.personID
LEFT JOIN treatment ON treatment.patientID = patient.patientID
where treatment.diseaseID is not null 
group by address.state,treatment.diseaseID
) op)opp
where mini=cc)


SELECT 
    cte.state  AS State,
    cte.max_disease_id AS Max_Disease_ID,
    cte1.min_disease_id AS Min_Disease_ID
FROM cte
LEFT JOIN cte1 ON cte.state = cte1.state

GROUP BY State, Max_Disease_ID, Min_Disease_ID
WITH ROLLUP
having max_disease_id is not null and min_disease_id is not null;


-- Problem Statement 4: 
-- Jackson has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for each disease in the year 2022, along with this Jackson also needs to view how many prescriptions were prescribed by each pharmacy, and the total number prescriptions were prescribed for each disease.
-- Assist Jackson to create this report. 

with cte as(select prescription.pharmacyID,count(prescription.prescriptionID) as no_of_pres from treatment
join prescription on treatment.treatmentID=prescription.treatmentID
where  year(treatment.date)=2022
group by year(treatment.date),prescription.pharmacyID
with rollup)

select pharmacy.pharmacyName,cte.*
from pharmacy
join cte on cte.pharmacyID=pharmacy.pharmacyID;

-- Problem Statement 5:  
-- Praveen has requested for a report that finds for every disease how many males and females underwent treatment for each in the year 2022. It would be helpful for Praveen if the aggregation for the different combinations is found as well.
-- Assist Praveen to create this report. 


with cte as(SELECT 
    IFNULL(treatment.diseaseID, 'Total') AS Disease_id,
    IFNULL(person.gender, 'Total') AS Gender,
    COUNT(treatment.patientID) AS count_treatament
FROM person
JOIN patient ON patient.patientID = person.personID
JOIN treatment ON treatment.patientID = patient.patientID
GROUP BY treatment.diseaseID , person.gender WITH ROLLUP
)
select disease.diseaseName,cte.Gender,cte.count_treatament
from disease
join cte on cte.Disease_id=disease.diseaseID
;

-- # FILE 10 stored routines -1
-- Problem Statement 1:

-- The healthcare department has requested a system to analyze the performance of insurance companies and their plan.

-- For this purpose, create a stored procedure that returns the performance of different insurance plans of an insurance company. When passed the insurance company ID the procedure should generate and return all the insurance plan names the provided company issues, the number of treatments the plan was claimed for, and the name of the disease the plan was claimed for the most. The plans which are claimed more are expected to appear above the plans that are claimed less.


DELIMITER //
create procedure get_info( in idid int)
begin 
with cte as (select insuranceplan.planName,count(treatment.claimID) as cc,dense_rank() over(partition by planName order by count(treatment.claimID) desc) as ranking,treatment.diseaseID from insurancecompany
join insuranceplan on insurancecompany.companyID=insuranceplan.companyID
join claim on insuranceplan.uin=claim.uin
join treatment on treatment.claimID=claim.claimID
where insurancecompany.companyID=idid
group by insuranceplan.planName,treatment.diseaseID)

select planName,cc,diseaseID
from cte
where ranking=1;
END //
DELIMITER ;
call get_info(7923);
drop procedure get_info;


-- Problem Statement 2:
-- It was reported by some unverified sources that some pharmacies are more popular for certain diseases. The healthcare department wants to check the validity of this report.
-- Create a stored procedure that takes a disease name as a parameter and would return the top 3 pharmacies the patients are preferring for the treatment of that disease in 2021 as well as for 2022.
-- Check if there are common pharmacies in the top 3 list for a disease, in the years 2021 and the year 2022.
-- Call the stored procedure by passing the values “Asthma” and “Psoriasis” as disease names and draw a conclusion from the result.

DELIMITER //
create procedure get_repo( in dis_name varchar(50))
begin 
with cte as (select pharmacyID,count(prescription.pharmacyID) as op,dense_rank() over( order by count(prescription.pharmacyID) desc) as ranking from disease
join treatment on treatment.diseaseID=disease.diseaseID
join prescription on prescription.treatmentID=treatment.treatmentID
where disease.diseaseName=dis_name and( year(date)=2021 or year(date)=2022)
group by disease.diseaseID,pharmacyID
order by count(pharmacyID) desc)

select cte.pharmacyID,pharmacyName
from cte
join pharmacy on pharmacy.pharmacyID =cte.pharmacyID
where ranking =1;
END //
DELIMITER ;
call get_repo("Asthma");
call get_repo("Psoriasis");
drop procedure get_repo;



-- Problem Statement 3:
-- Jacob, as a business strategist, wants to figure out if a state is appropriate for setting up an insurance company 
-- or not.
-- Write a stored procedure that finds the num_patients, num_insurance_companies, and insurance_patient_ratio, the stored 
-- procedure should also find the avg_insurance_patient_ratio and if the insurance_patient_ratio of the given state is less 
-- than the avg_insurance_patient_ratio then it Recommendation section can have the value “Recommended” otherwise the value 
-- can be “Not Recommended”.
delimiter $$
create procedure stateRecommendation (in state varchar(100), out recommendation varchar(150))
begin
declare num_patients, num_insurance_companies, insurance_patient_ratio, avg_insurance_patient_ratio int default 0;
start transaction;
SELECT COUNT(p1.patientID)
INTO num_patients FROM patient p1
JOIN person p2 ON p1.patientID = p2.personID
JOIN address a ON a.addressID = p2.addressID
WHERE a.state = state;

SELECT COUNT(ic.companyID)
INTO num_insurance_companies 
FROM insurancecompany ic
JOIN address a ON ic.addressID = a.addressID
WHERE a.state = state;

SELECT num_patients / num_insurance_companies INTO insurance_patient_ratio;

SELECT 
    (SELECT COUNT(*)
        FROM patient) / (SELECT 
            COUNT(*)
        FROM insurancecompany)
INTO avg_insurance_patient_ratio;

if insurance_patient_ratio < avg_insurance_patient_ratio
then set recommendation = 'Recommended';
else set recommendation = 'Not Recommended';
end if;

end;
end$$

delimiter ;

call stateRecommendation('MA', @recommendation);
select @recommendation;
call stateRecommendation('TN', @recommendation);
select @recommendation;


-- Problem Statement 4:
-- Currently, the data from every state is not in the database, The management has decided to add the data from other 
-- states and cities as well. It is felt by the management that it would be helpful if the date and time were to be stored 
-- whenever new city or state data is inserted.
-- The management has sent a requirement to create a PlacesAdded table if it doesn’t already exist, that has four attributes. 
-- placeID, placeName, placeType, and timeAdded.
-- Description
-- placeID: This is the primary key, it should be auto-incremented starting from 1
-- placeName: This is the name of the place which is added for the first time
-- placeType: This is the type of place that is added for the first time. The value can either be ‘city’ or ‘state’
-- timeAdded: This is the date and time when the new place is added
-- You have been given the responsibility to create a system that satisfies the requirements of the management. Whenever some 
-- data is inserted in the Address table that has a new city or state name, the PlacesAdded table should be updated with relevant data. 

create table if not exists PlacesAdded(
placeID int auto_increment primary key,
PlaceName varchar(100) unique,
placeType enum('state','city'),
timeAdded datetime default current_timestamp()
);

delimiter $$
drop trigger if exists addPlace;
create trigger addPlace 
after insert on address for each row
begin
if exists(
	select 1 from address where state = new.state
) and not exists(
	select 1 from placesadded where placetype = 'state' and placename = new.state
)then insert into placesadded(placename, placetype) values(new.state, 'state');
end if;
if exists(
	select 1 from address where city = new.city
) and not exists(
	select 1 from placesadded where placetype = 'city' and placename = new.city
)then insert into placesadded(placename, placetype) values(new.city, 'city');
end if;
end $$

delimiter ;
insert into address values(1000000, 'bibwewadi', 'Pune', 'MH', 411037);
insert into address values(1000002, 'kothrud', 'Pune', 'MH', 411041);
insert into address values(1000003, 'anandnagar', 'jamner', 'MH', 424241);
insert into address values(1000004, 'Kishorsangha', 'Alipurduar', 'WB', 736121);

#------------------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER addPlace 
AFTER INSERT ON address
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM placesadded WHERE placetype = 'state' AND placename = NEW.state) THEN
        INSERT INTO placesadded (placename, placetype) VALUES (NEW.state, 'state');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM placesadded WHERE placetype = 'city' AND placename = NEW.city) THEN
        INSERT INTO placesadded (placename, placetype) VALUES (NEW.city, 'city');
    END IF;
END $$

DELIMITER ;

INSERT INTO address (addressID, street, city, state, postalCode) VALUES (1000000, 'bibwewadi', 'Pune', 'MH', 411037);
INSERT INTO address (addressID, street, city, state, postalCode) VALUES (1000002, 'kothrud', 'Pune', 'MH', 411041);
INSERT INTO address (addressID, street, city, state, postalCode) VALUES (1000003, 'anandnagar', 'jamner', 'MH', 424241);
INSERT INTO address (addressID, street, city, state, postalCode) VALUES (1000004, 'Kishorsangha', 'Alipurduar', 'WB', 736121);


-- Problem Statement 5:
-- Some pharmacies suspect there is some discrepancy in their inventory management. The quantity in the ‘Keep’ is updated
--  regularly and there is no record of it. They have requested to create a system that keeps track of all the transactions 
--  whenever the quantity of the inventory is updated.
-- You have been given the responsibility to create a system that automatically updates a Keep_Log table which has  the following fields:
-- id: It is a unique field that starts with 1 and increments by 1 for each new entry
-- medicineID: It is the medicineID of the medicine for which the quantity is updated.
-- quantity: The quantity of medicine which is to be added. If the quantity is reduced then the number can be negative.
-- For example:  If in Keep the old quantity was 700 and the new quantity to be updated is 1000, then in Keep_Log the quantity should be 300.
-- Example 2: If in Keep the old quantity was 700 and the new quantity to be updated is 100, then in Keep_Log the quantity should be -600.
         
create table if not exists keepLog(
id int auto_increment primary key,
medicineID int references medicine(medicineID),
quantity int);

delimiter $$
drop trigger if exists keepUpdates $$
create trigger keepUpdates 
after update on keep 
for each row
begin
declare changes int;
set changes = new.quantity - old.quantity;
insert into keepLog (medicineID, quantity) values (new.medicineID, changes);
end $$

delimiter ;

update keep
set quantity = 1000 
where pharmacyID = 5527 and medicineID = 1;

select * from keeplog;


-- # FILE 11 stored routines -2
-- Problem Statement 1:
-- Patients are complaining that it is often difficult to find some medicines. They move from pharmacy to pharmacy to get the required 
-- medicine. A system is required that finds the pharmacies and their contact number that have the required medicine in their inventory. 
-- So that the patients can contact the pharmacy and order the required medicine.
-- Create a stored procedure that can fix the issue.
delimiter $$

create procedure findPharmacy (in company varchar(100), product varchar(100))
begin
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
SELECT 'An error has occurred, operation rollbacked and the stored procedure was terminated';
END;
start transaction;
SELECT p.pharmacyName, p.phone
FROM medicine m
JOIN keep k USING (medicineID)
JOIN pharmacy p USING (pharmacyID)
WHERE m.productName = product AND m.companyname = company;
end;
commit 
end$$

delimiter ;

call findPharmacy('LUPER INDUSTRIA FARMACEUTICA LTDA','CETIL');

-- Problem Statement 2:
-- The pharmacies are trying to estimate the average cost of all the prescribed medicines per prescription, for all the prescriptions 
-- they have prescribed in a particular year. Create a stored function that will return the required value when the pharmacyID and year 
-- are passed to it. Test the function with multiple values.
delimiter &&
drop function if exists estimateCost;
create function estimateCost (pharmacyID int, year int)
returns int
reads sql data
begin 
declare cost int;

SELECT AVG(m.maxPrice - (m.maxPrice / k.discount))
INTO cost 
FROM pharmacy p
JOIN keep k USING (pharmacyID)
JOIN medicine m USING (medicineID)
GROUP BY p.pharmacyID
HAVING p.pharmacyID = pharmacyID;

return cost;
end&&

delimiter ;

select estimateCost(1008,2021);
select estimateCost(1145,2021);

-- Problem Statement 3:
-- The healthcare department has requested an application that finds out the disease that was spread the most in a state for a given year. 
-- So that they can use the information to compare the historical data and gain some insight.
-- Create a stored function that returns the name of the disease for which the patients from a particular state had the most number of 
-- treatments for a particular year. Provided the name of the state and year is passed to the stored function.
delimiter &&
drop function if exists findDiseases;
create function findDiseases (dstate varchar(100), dyear int)
returns varchar(100)
deterministic
begin 

declare mostSpreaded varchar(100);

select diseaseName into mostSpreaded from
(select d.diseaseName, a.state, year(t.date) as year, count(p.personID) as total, 
dense_rank() over (order by count(p.personID) desc) as dr
from treatment t
join disease d using(diseaseID)
join person p on t.patientID = p.personID
join address a using(addressID)
group by d.diseaseName, a.state, year
having a.state = dstate and year = dyear) d
where dr = 1;

return mostSpreaded;
end&&

delimiter ;

select findDiseases('AL', 2021);
select findDiseases('OK', 2020);

-- Problem Statement 4:
-- The representative of the pharma union, Aubrey, has requested a system that she can use to find how many people in a specific city 
-- have been treated for a specific disease in a specific year.
-- Create a stored function for this purpose.
delimiter &&
create function getPeopleCount (pdiseasename varchar(100), pcity varchar(100), pyear int)
returns int
deterministic
begin 
declare peopleCount int;

SELECT COUNT(p.personID)
INTO peopleCount 
FROM treatment t
JOIN disease d USING (diseaseID)
JOIN person p ON t.patientID = p.personID
JOIN address a USING (addressID)
WHERE d.diseaseName = pdiseasename AND a.city = pcity AND YEAR(t.date) = pyear;

return peopleCount;
end&&

delimiter ;

select getPeopleCount('cancer', 'Oklahoma City', 2021);
select getPeopleCount('Asthma', 'Washington', 2020);

-- Problem Statement 5:
-- The representative of the pharma union, Aubrey, is trying to audit different aspects of the pharmacies. She has requested a system 
-- that can be used to find the average balance for claims submitted by a specific insurance company in the year 2022. 
-- Create a stored function that can be used in the requested application. 
delimiter &&

create function claimBalance (insurance_company varchar(100))
returns int
reads sql data
begin 
declare avg_balance int;
SELECT AVG(c.balance)
INTO avg_balance 
FROM treatment t
JOIN claim c USING (claimID)
JOIN insuranceplan ip USING (uin)
JOIN insurancecompany ic USING (companyID)
WHERE companyName LIKE CONCAT('%', insurance_company, '%') AND YEAR(t.date) = 2022;
return avg_balance;
end&&

delimiter ;

select claimBalance('Bajaj Allianz General Insurance Co. Ltd.�');
select claimBalance('Future Generali India Insurance Company Limited.���');
