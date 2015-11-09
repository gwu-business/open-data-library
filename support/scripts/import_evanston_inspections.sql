/*
  Use this script to import into a mysql database all .csv files from relational-data/evanston_healthscores/
  ... adding unique identifiers as applicable thanks to http://stackoverflow.com/a/13550826/670433
*/

DROP DATABASE IF EXISTS evanston_healthscores;
CREATE DATABASE evanston_healthscores;

/*
  FEED INFO
*/
DROP TABLE IF EXISTS evanston_healthscores.feed_info_temp;

CREATE TABLE evanston_healthscores.feed_info_temp (
  `feed_date` int(11) DEFAULT NULL,
  `feed_version` varchar(255) DEFAULT NULL,
  `municipality_name` varchar(255) DEFAULT NULL,
  `municipality_url` varchar(255) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOAD DATA LOCAL INFILE '~/projects/gwu-business/open-data-library/relational-data/evanston_healthscores/feed_info.csv'
INTO TABLE evanston_healthscores.feed_info_temp
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- mac-style line breaks
  IGNORE 1 LINES
;

DROP TABLE IF EXISTS evanston_healthscores.feed_info;
CREATE TABLE  evanston_healthscores.feed_info AS (
  SELECT
    -- feed_date AS feed_date_original
    -- ,LEFT(feed_date,4) AS feed_year
    -- ,substring(feed_date, 5,2) AS feed_month
    -- ,RIGHT(feed_date,2) AS feed_day
    str_to_date(
     concat(
        LEFT(feed_date,4)
        ,"-"
        ,substring(feed_date, 5,2)
        ,"-"
        ,RIGHT(feed_date,2)
      ), '%Y-%m-%d'
    ) AS feed_date
    ,feed_version
    ,municipality_name
    ,municipality_url
    ,contact_email
  FROM evanston_healthscores.feed_info_temp
);

DROP TABLE IF EXISTS evanston_healthscores.feed_info_temp; -- clean-up

/*
  BUSINESSES
*/

DROP TABLE IF EXISTS evanston_healthscores.businesses;
CREATE TABLE evanston_healthscores.businesses (
  `business_id` VARCHAR(255) DEFAULT NULL,
  `name` VARCHAR(255) DEFAULT NULL,
  `address` VARCHAR(255) DEFAULT NULL,
  `city` VARCHAR(255) DEFAULT NULL,
  `state` VARCHAR(255) DEFAULT NULL,
  `postal_code` INT(11) DEFAULT NULL,
  `phone_number` VARCHAR(255) DEFAULT NULL,
  `latitude` VARCHAR(255) DEFAULT NULL,
  `longitude` VARCHAR(255) DEFAULT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8; -- this table definition was copied from sequel pro's "table info" menu after the .csv file was first imported...

LOAD DATA LOCAL INFILE '~/projects/gwu-business/open-data-library/relational-data/evanston_healthscores/businesses.csv'
INTO TABLE evanston_healthscores.businesses
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- mac-style line breaks
  IGNORE 1 LINES
;

SELECT business_id, count(*) AS row_count
FROM evanston_healthscores.businesses
GROUP BY business_id
HAVING row_count > 1
ORDER BY row_count DESC; -- verify uniqueness of business_id attribute

ALTER TABLE evanston_healthscores.businesses ADD PRIMARY KEY(business_id);

/*
  INSPECTIONS
*/

DROP TABLE IF EXISTS evanston_healthscores.inspections_temp;
CREATE TABLE evanston_healthscores.inspections_temp (
  `business_id` VARCHAR(255) DEFAULT NULL,
  `score` INT(11) DEFAULT NULL,
  `date` INT(11) DEFAULT NULL,
  `type` VARCHAR(255) DEFAULT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8;

LOAD DATA LOCAL INFILE '~/projects/gwu-business/open-data-library/relational-data/evanston_healthscores/inspections.csv'
INTO TABLE evanston_healthscores.inspections_temp
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- mac-style line breaks
  IGNORE 1 LINES
;

SELECT
  business_id
 , count(*) AS row_count
FROM inspections_temp
GROUP BY business_id
HAVING row_count > 1
ORDER BY 2 DESC; -- business_id is not a primary key

SELECT
  i.business_id
  ,i.date
 , count(*) AS row_count
FROM inspections_temp i
GROUP BY 1,2
HAVING row_count > 1
ORDER BY 3 DESC; -- business_id and date do not comprise a composite primary key...

DROP TABLE IF EXISTS evanston_healthscores.inspections;
SET @row_num = 0;
CREATE TABLE  evanston_healthscores.inspections AS (
  SELECT
    @row_num := @row_num + 1 AS id
    ,i.business_id
    ,i.score
    ,str_to_date(
     concat(
        LEFT(i.date,4)
        ,"-"
        ,substring(i.date, 5,2)
        ,"-"
        ,RIGHT(i.date,2)
      ), '%Y-%m-%d'
    ) AS `date`
    ,i.type
  FROM evanston_healthscores.inspections_temp i
);

DROP TABLE IF EXISTS evanston_healthscores.inspections_temp; -- clean-up

/*
  VIOLATIONS
*/

DROP TABLE IF EXISTS evanston_healthscores.violations_temp;
CREATE TABLE evanston_healthscores.violations_temp (
  `business_id` varchar(255) DEFAULT NULL,
  `date` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `description` text
) ENGINE=INNODB DEFAULT CHARSET=utf8;

LOAD DATA LOCAL INFILE '~/projects/gwu-business/open-data-library/relational-data/evanston_healthscores/violations.csv'
INTO TABLE evanston_healthscores.violations_temp
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- mac-style line breaks
  IGNORE 1 LINES
;

SELECT
  business_id
 , count(*) AS row_count
FROM violations_temp
GROUP BY business_id
HAVING row_count > 1
ORDER BY 2 DESC; -- business_id is not a primary key

SELECT
  i.business_id
  ,i.date
 , count(*) AS row_count
FROM violations_temp i
GROUP BY 1,2
HAVING row_count > 1
ORDER BY 3 DESC; -- business_id and date do not comprise a composite primary key...

DROP TABLE IF EXISTS evanston_healthscores.violations;
SET @row_num = 0;
CREATE TABLE  evanston_healthscores.violations AS (
  SELECT
    @row_num := @row_num + 1 AS id
    ,v.business_id
    ,str_to_date(
     concat(
        LEFT(v.date,4)
        ,"-"
        ,substring(v.date, 5,2)
        ,"-"
        ,RIGHT(v.date,2)
      ), '%Y-%m-%d'
    ) AS `date`
    ,v.code
    ,v.description
  FROM evanston_healthscores.violations_temp v
);

DROP TABLE IF EXISTS evanston_healthscores.violations_temp; -- clean-up
