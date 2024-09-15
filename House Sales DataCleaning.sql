-- DATA CLEANING PROJECT (HOUSE SALES)

-- A LOOK AT DATSET

SELECT * FROM 
housing_data;
		-- 24007 ROWS RETURNED

-- # DATA CLEANING

-- LIST OF ALL THE COLUMNS 
               -- 1. UniquesID               2. ParcelID             3. LandUse            4. PropertyAddress 
               -- 5. SaleDate                6. SalePrice            7. LegalReference     8. SoldAsVacant
               -- 9. OwnerName              10. OwnerAddress        11. Acreage           12. TaxDistrict
	       -- 13. LandValue              14. BuildingValue       15. TotalValue        16. YearBuilt
               -- 17. Bedrooms               18. FullBath            19. HalfBath          
			
-- STANDARDIZING DATE FORMAT 

SELECT SaleDate , STR_TO_DATE(SaleDate, '%M %d, %Y')
FROM housing_data;

UPDATE housing_data 
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');
			
ALTER TABLE housing_data
MODIFY COLUMN SaleDate DATE;
					-- SALEDATE HAS BEEN UPDATED 
                    
-- LOOKING AT PROPERTY ADDRESS COLUMN 

SELECT PropertyAddress FROM housing_data
GROUP BY PropertyAddress
ORDER BY 1;
         -- 21539 ROWS RETURNED 
         
SELECT * FROM housing_data
WHERE PropertyAddress IS NULL OR PropertyAddress = '';
		-- WE HAVE 18 EMPTY VALUES IN PROPERTY ADDRESS

-- POPULATING EMPTY PROPERTY COLUMN WHERE APPLICABLE 

SELECT T1.ParcelID, T1.PropertyAddress, T2.ParcelID, T2.PropertyAddress FROM housing_data AS T1
JOIN housing_data AS T2
ON T1.ParcelID = T2.ParcelID
WHERE T1.PropertyAddress = '' AND T2.PropertyAddress <> "";

UPDATE housing_data AS T1
JOIN housing_data AS T2
	ON T1.ParcelID = T2.ParcelID
SET T1.PropertyAddress = T2.PropertyAddress
WHERE T1.PropertyAddress = '' AND T2.PropertyAddress <> "";

SELECT PropertyAddress FROM housing_data
WHERE PropertyAddress = '';
					-- ALL EMPTY VALUES HAS BEEN REMOVED 
                    
-- SEPERATING PROPERTY ADDRESS COLUMN INTO 2 COLUMNS (ADDRESS, CITY)

SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',',PropertyAddress) -1) AS Address, 
SUBSTRING(PropertyAddress, LOCATE(',',PropertyAddress) +1, LENGTH(PropertyAddress)) AS City
FROM housing_data; 

-- ADDING BOTH PROPERTY ADDRESS AND PROPERTY CITY INTO DATASET

ALTER TABLE housing_data
ADD Address TEXT; 
ALTER TABLE housing_data
ADD City TEXT; 

UPDATE housing_data
SET City = SUBSTRING(PropertyAddress, LOCATE(',',PropertyAddress) +1, LENGTH(PropertyAddress)); 
UPDATE housing_data
SET Address = SUBSTRING(PropertyAddress, 1, LOCATE(',',PropertyAddress) -1);

SELECT * FROM housing_data;

-- SPLITTING OWNER ADRESS INTO 3 (ADDRESS, CITY, STATE)

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1),
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
SUBSTRING_INDEX(OwnerAddress, ',', -1) 
FROM housing_data;

ALTER TABLE housing_data
ADD OwnerStreetAddress TEXT,
ADD OwnerCity TEXT,
ADD OwnerState TEXT;

UPDATE housing_data
SET OwnerStreetAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1);
						-- DATA HAS BEEN ADDED
                        
-- LOOKING AT SOLD AS VACANT COLUMN 

SELECT DISTINCT(SoldAsVacant) FROM housing_data;

-- CHANGING Y AND N TO YES AND NO IN SOLD AS VACANT 

UPDATE housing_data
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant LIKE 'N%' THEN 'No'
    WHEN SoldAsVacant LIKE 'Y%' THEN 'Yes'
END;
	-- DATA HAS BEEN UPDATED 
    
-- LOOKING AT LANDUSE COLUMN 

SELECT LandUse, COUNT(LandUse) FROM housing_data
GROUP BY LandUse;
			-- COLUMN DO NOT HAVE ANY PROBLEM 
            
-- LOOKING AT TAX DISTRICT COLUMN 

SELECT TaxDistrict, COUNT(TaxDistrict) FROM housing_data
GROUP BY TaxDistrict;
				-- COLUMN DO NOT HAVE ANY PROBLEM 
                
-- CHECKING FOR DUPLICATES (IGNORING UNIQUE ID)

WITH Duplicate_cte AS
(
SELECT *, ROW_NUMBER() OVER(
PARTITION BY ParcelID, LandUse ,PropertyAddress ,SaleDate ,SalePrice, LegalReference ,SoldAsVacant ,OwnerName ,OwnerAddress
,Acreage ,TaxDistrict ,LandValue ,BuildingValue ,TotalValue ,YearBuilt  ,Bedrooms  ,FullBath ,HalfBath ,Address ,City  ,OwnerStreetAddress 
,OwnerCity, OwnerState ) AS row_num
FROM housing_data
)
SELECT * FROM Duplicate_cte
WHERE row_num > 1;
			   -- 45 DUPLICATES FOUND 
               
-- REMOVING DUPLICATES 

CREATE TABLE `housing_data_cleaned` (
  `UniqueID` int DEFAULT NULL,
  `ParcelID` text,
  `LandUse` text,
  `PropertyAddress` text,
  `SaleDate` date DEFAULT NULL,
  `SalePrice` int DEFAULT NULL,
  `LegalReference` text,
  `SoldAsVacant` text,
  `OwnerName` text,
  `OwnerAddress` text,
  `Acreage` double DEFAULT NULL,
  `TaxDistrict` text,
  `LandValue` int DEFAULT NULL,
  `BuildingValue` int DEFAULT NULL,
  `TotalValue` int DEFAULT NULL,
  `YearBuilt` int DEFAULT NULL,
  `Bedrooms` int DEFAULT NULL,
  `FullBath` int DEFAULT NULL,
  `HalfBath` int DEFAULT NULL,
  `Address` text,
  `City` text,
  `OwnerStreetAddress` text,
  `OwnerCity` text,
  `OwnerState` text,
  `row_Num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO housing_data_cleaned
SELECT *, ROW_NUMBER() OVER(
PARTITION BY ParcelID, LandUse ,PropertyAddress ,SaleDate ,SalePrice, LegalReference ,SoldAsVacant ,OwnerName ,OwnerAddress
,Acreage ,TaxDistrict ,LandValue ,BuildingValue ,TotalValue ,YearBuilt  ,Bedrooms  ,FullBath ,HalfBath ,Address ,City  ,OwnerStreetAddress 
,OwnerCity, OwnerState ) AS row_num
FROM housing_data;

SELECT * FROM housing_data_cleaned
WHERE row_num > 1;

-- DELETING DUPLICATE DATA 

DELETE FROM housing_data_cleaned
WHERE row_num > 1;

-- REMOVING UNWANTED COLUMNS 

ALTER TABLE housing_data_cleaned
DROP COLUMN OwnerAddress, 
DROP COLUMN PropertyAddress,
DROP COLUMN row_num;

-- RENAMING COLUMNS

ALTER TABLE housing_data_cleaned
RENAME COLUMN Address TO PropertyAddress,
RENAME COLUMN City TO PropertyCity;
					-- DATA HAS BEEN CLEANED

-- A LOOK INTO CLEANED DATASET

SELECT * FROM housing_data_cleaned;







