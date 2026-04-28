# Replication files for *Inequality of Opportunity in South Asia: The Puzzle of Educational Gains Without Consumption Gains*

## Contents

1. [Overview](#overview)
2. [Data Availability](#data-availability)
3. [Instructions for Replicators](#instructions-for-replicators)
4. [List of Exhibits](#list-of-exhibits)
5. [Requirements](#requirements)
6. [Code Description](#code-description)
7. [Folder Structure](#folder-structure)

## Overview

The repository contains all code files to replicate the dataset construction (`Stata`) and the analysis with all tables and figures of the manuscript (`R`).
After setting the root directory, the replicator first has to run the main cleaning file and subsequently the main analysis file. The table and figure names are detailed below (see [list of exhibits](#list-of-exhibits)).

## Data Availability

The used household and labor force surveys are subject to data access approval, such that the main data of the manuscript cannot be made publicly available. Get in contact with [Maurizio Bussolo](mailto:mbussolo@worldbank.org) for data sharing requests.

### Data Sources

Our main data sources are household surveys (HHS) and labor force surveys (LFS). Besides the raw data, we rely on harmonized files by the World Bank via the South Asia Regional Micro Database ([SARMD](https://worldbank.github.io/SARMD_guidelines)), the Global Labor Database ([GLD](https://worldbank.github.io/gld)) and the South Asia Labor Force Surveys repository ([SARLAB](https://github.com/worldbank/SAR_LaborForceSurveys)). The exact surveys and files are listed below (see Section A1 for more details on their selection). Both types of data, raw and harmonized, are access restricted (exceptions are marked with "*" but require prior registration with the data provider).

Beyond those surveys, we draw on the World Bank's World Development Indicators (WDI) and the ILOSTAT's Labour Force Statistics (LFS) database to obtain the labor force participation rate (% of total population ages 15-64) as [modeled ILO estimate (ILO_lfp_model.csv, 1/28/2025)](https://data.worldbank.org/indicator/SL.TLF.ACTI.ZS) and
[labor force survey based estimate (ILO_lfp_lfs.csv, 2/1/2025)](https://rplumber.ilo.org/data/indicator/?id=EAP_DWAP_SEX_AGE_RT_A&lang=en&type=label&format=.csv&channel=ilostat&title=labour-force-participation-rate-by-sex-and-age-annual), the [consumer price index (2010 = 100; cpi2010.csv, 8/22/2024)](https://data.worldbank.org/indicator/FP.CPI.TOTL) from IMF'S International Financial Statistics database as well as the [total population by country (population.csv, 8/5/2022)](https://data.worldbank.org/indicator/SP.POP.TOTL).
Further, we draw on the World Bank's [Poverty and Inequality Platform (PIP)](https://pip.worldbank.org/) for gini estimate comparison (release 20250930_2017_01_02_PROD, 10/28/2025; for India up until 2011 release 20240627_2017_01_02_PROD, 5/7/2025, is used to align with the change survey methodology underlying our estimates, see Table A9) and on IOp estimates from the the Global Estimates of Opportunity and Mobility database ([GEOM](https://geom.ecineq.org/), 2/7/2025). Further, manual mappings across different geographic levels (`geo_level`) and demographic groups (`demo`) are provided. Only those auxiliary datafiles are included in the freely available replication package (`auxiliary`). Additionally, we draw on the "Survey of the Afghan People (2004-2019)" conducted by the Asia Foundation for classifying the regions of Afghanistan by their ethnical group ([access request](https://doi.org/10.26193/VDDO0X), `auxiliary_non_public`, 11/18/2022).

| Name | Survey name | Years | Source | URL raw data (date of access) | SARMD/GLD/SARLAB files (date of access) |
|------|-------------|-------|--------|--------------|------------------------|
| NRVA | National Risk and Vulnerability Assessment | 2007-2008, 2011-2012 | Central Statistics Organization (CSO) | [NRAVA 2008](https://catalog.ihsn.org/index.php/catalog/935) (8/27/2021), [NRVA 2012](https://catalog.ihsn.org/index.php/catalog/5230) (8/27/2021) | `AFG_2008_NRVA_v01_M_v01_A_SARMD_IND` (1/30/2023), `AFG_2012_NRVA_v01_M_v01_A_SARMD_IND` (1/30/2023) |
| ALCS | Afghanistan Living Conditions Survey | 2013-2014, 2016-2017 | Central Statistics Organization (CSO) | [ALCS 2014](https://catalog.ihsn.org/index.php/catalog/6557) (8/27/2021), [ALCS 2017](https://catalog.ihsn.org/index.php/catalog/8014) (8/27/2021) | `AFG_2016_LCS_v01_M_v01_A_SARMD_IND` (1/28/2023) |
| IELFS | Integrated Expenditure and Labor Force Survey | 2020 | National Statistics and Information Authority (NSIA) | [IE&LFS 2020](https://fscluster.org/afghanistan/document/income-and-expenditure-labor) (8/27/2021) | |
| BGD-HIES | Household Income and Expenditure Survey | 2000, 2005, 2010, 2016-2017, 2022 | Bangladesh Bureau of Statistics (BBS) | [HIES 2000](https://catalog.ihsn.org/index.php/catalog/135), [HIES 2005](https://catalog.ihsn.org/index.php/catalog/138), [HIES 2010](https://catalog.ihsn.org/index.php/catalog/2257), [HIES 2016](https://catalog.ihsn.org/index.php/catalog/7399), [HIES 2022](https://bbs.gov.bd/site/page/648dd9f5-067b-4bcc-ba38-45bfb9b12394/Income,-Expenditure-%26-Poverty) (raw data not used), [Data access request](http://nsds.bbs.gov.bd/storage/files/1/BBS-Application-form-for-research-entities.docx) | `BGD_2000_HIES_v01_M_v05_A_SARMD_IND` (4/26/2022), `BGD_2005_HIES_v01_M_v05_A_SARMD_IND` (4/26/2022), `BGD_2010_HIES_v01_M_v05_A_SARMD_IND` (4/26/2022), `BGD_2016_HIES_v01_M_v04_A_SARMD_IND` (4/26/2022), `BGD_2022_HIES_v01_M_v01_A_SARMD_IND` (11/3/2023)|
| BGD-LFS | Labor Force Survey | 2005-2006, 2010, 2013, 2015-2016, 2016-2017, 2022 | Bangladesh Bureau of Statistics (BBS) |[LFS2005](https://webapps.ilo.org/surveyLib/index.php/catalog/7874) (12/13/2025), [LFS 2010](https://webapps.ilo.org/surveyLib/index.php/catalog/7873) (12/13/2025), [LFS 2013](https://webapps.ilo.org/surveyLib/index.php/catalog/7872) (12/13/2025), [LFS 2015](https://catalog.ihsn.org/index.php/catalog/7277) (12/13/2025), [LFS 2016](https://catalog.ihsn.org/index.php/catalog/8021) (1/14/2026), [LFS 2022](https://webapps.ilo.org/surveyLib/index.php/catalog/8538) (12/13/2025), [Data access request](http://nsds.bbs.gov.bd/storage/files/1/BBS-Application-form-for-research-entities.docx) | `BGD_2005_LFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `BGD_2010_LFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `BGD_2013_LFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `BGD_2015_QLFS_V02_M_V01_A_GLD_ALL` (12/13/2025), `BGD_2016_QLFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `BGD_2022_QLFS_v01_M_v01_A_SARLD_Q1` (12/13/2025)|
| BLSS | Bhutan Living Standards Survey | 2003, 2007, 2012, 2017, 2022 | National Statistics Bureau (NSB) | [BLSS 2003](https://catalog.ihsn.org/index.php/catalog/23) (8/27/2021), [BLSS 2007](https://catalog.ihsn.org/index.php/catalog/24) (8/27/2021), [BLSS 2012](https://catalog.ihsn.org/index.php/catalog/3250) (8/27/2021), [BLSS 2017](https://www.nsb.gov.bt/wp-content/uploads/2020/10/BLSS-2017-Report.pdf) (8/27/2021), [BLSS 2022](https://www.nsb.gov.bt/wp-content/uploads/dlm_uploads/2022/12/BLSS-2022-for-WEB.pdf) (3/6/2025), [Data access request](https://www.nsb.gov.bt/services/statistical-data-request/) | `BTN_2003_BLSS_v01_M_v05_A_SARMD_IND` (12/18/2022), `BTN_2007_BLSS_v01_M_v05_A_SARMD_IND` (12/18/2022), `BTN_2012_BLSS_v01_M_v06_A_SARMD_IND` (12/18/2022), `BTN_2017_BLSS_v01_M_v03_A_SARMD_IND` (12/18/2022), `BTN_2022_BLSS_v01_M_v02_A_SARMD_COR` (3/6/2025) | 
| BHT-LFS | Labor Force Survey | National Statistics Bureau (NSB) | 2018, 2019, 2020, 2022 | [LFS 2018](https://webapps.ilo.org/surveyLib/index.php/catalog/7986), [LFS 2019](https://webapps.ilo.org/surveyLib/index.php/catalog/7985), [LFS 2020](https://webapps.ilo.org/surveyLib/index.php/catalog/7984), [LFS 2022](https://webapps.ilo.org/surveyLib/index.php/catalog/8405) (raw data not used), [Data access request](https://www.nsb.gov.bt/services/statistical-data-request/) | `BTN_2018_LFS_v01_M_v01_A_SARLAB_IND`, `BTN_2019_LFS_v01_M_v01_A_SARLAB_IND`, `BTN_2020_LFS_v01_M_v01_A_SARLAB_IND`, `BTN_2022_LFS_v01_M_v01_A_SARLAB_IND` (all accessed on 6/5/2025) |
| IHDS* | India Human Development Survey | 2005, 2011 | ICPSR - University of Maryland | [IHDS 2005](https://www.icpsr.umich.edu/web/DSDR/studies/22626) (8/16/2025), [IHDS 2011](http://www.icpsr.umich.edu/icpsrweb/DSDR/studies/36151) (8/16/2025) | |
| NSS* | National Sample Survey | 1993-1994 (50th), 2004-2005 (61st), 2009-2010 (66th), 2011-2012 (68th) | National Sample Survey Office (NSSO) | [NSS 1993](http://www.icssrdataservice.in/datarepository/index.php/catalog/8) (4/27/2025), [NSS 2004](http://www.icssrdataservice.in/datarepository/index.php/catalog/3) (1/23/2023), [NSS 2009](http://www.icssrdataservice.in/datarepository/index.php/catalog/89) (1/23/2023), [NSS 2011](http://www.icssrdataservice.in/datarepository/index.php/catalog/135) (1/23/2023) |`IND_1993_NSS50-SCH1.0_v01_M_v04_A_SARMD_IND` (4/21/2025), `IND_2004_NSS61-SCH1.0_v01_M_v05_A_SARMD_IND_GMD_ALL` (4/18/2025), `IND_2009_NSS66-SCH1.0-T1_v01_M_v05_A_SARMD_IND_GMD_ALL` (4/18/2025), `IND_2011_NSS-SCH1_V01_M_V06_A_GMD_ALL` (3/6/2025), `IND_2011_NSS-SCH2_v02_M_v01_A_GMD_ALL` (3/6/2025) |
| HCES* | Household Consumption Expenditure Survey | 2022-2023 | National Sample Survey Office (NSSO) | [HCES 2022](https://microdata.gov.in/NADA/index.php/catalog/224) (3/6/2025) | `IND_2022_HCES_v02_M_v01_A_GMD_ALL` (3/6/2025) | 
| EUS | Employment and Unemployment Survey | 1987-88 (NSS 43rd), 1993-1994 (NSS 50th), 1999-2000(NSS 55th), 2004-2005 (NSS 61th), 2005-2006 (NSS 62nd), 2007-2008 (NSS 64th), 2009-2010 (NSS 66th), 2011-2012 (NSS 68th) | National Sample Survey Office (NSSO) | [EUS 1987](https://microdata.gov.in/NADA/index.php/catalog/55) (12/13/2025), [EUS 1993](https://microdata.gov.in/NADA/index.php/catalog/77) (12/13/2025), [EUS 1999](https://microdata.gov.in/NADA/index.php/catalog/90) (12/13/2025), [EUS 2004](https://microdata.gov.in/NADA/index.php/catalog/109) (12/13/2025), [EUS 2005](https://microdata.gov.in/NADA/index.php/catalog/113) (12/13/2025), [EUS 2007](https://microdata.gov.in/NADA/index.php/catalog/117) (12/13/2025), [EUS 2009](https://microdata.gov.in/NADA/index.php/catalog/124) (14/1/2026), [EUS 2011](https://microdata.gov.in/NADA/index.php/catalog/127) (14/1/2026) |`IND_1983_EUS_V01_M_V07_A_GLD_ALL`, `IND_1987_EUS_V01_M_V06_A_GLD_ALL`, `IND_1993_EUS_V01_M_V06_A_GLD_ALL`,`IND_2004_EUS_V01_M_V05_A_GLD_ALL`, `IND_2005_EUS_V01_M_V05_A_GLD_ALL`, `IND_2007_EUS_V01_M_V05_A_GLD_ALL`,`IND_2009_EUS_V01_M_V07_A_GLD_ALL`, `IND_2011_EUS_V01_M_V07_A_GLD_ALL` (all accessed on 1/25/2026)|
| PLFS | Periodic Labor Force Survey | 2017-2018, 2018-2019, 2019-2020, 2020-2021, 2021-2022, 2022-2023 | National Sample Survey Office (NSSO) | [PLFS 2017](https://microdata.gov.in/NADA/index.php/catalog/204), [PLFS 2018](https://microdata.gov.in/NADA/index.php/catalog/216), [PLFS 2019](https://microdata.gov.in/NADA/index.php/catalog/217), [PLFS 2020](https://microdata.gov.in/NADA/index.php/catalog/206), [PLFS 2021](https://microdata.gov.in/NADA/index.php/catalog/214), [PLFS 2022](https://microdata.gov.in/NADA/index.php/catalog/210) (all accessed on 12/13/2025) | `IND_2017_PLFS_V02_M_V04_A_GLD_ALL`, `IND_2018_PLFS_V02_M_V04_A_GLD_ALL`, `IND_2019_PLFS_V02_M_V04_A_GLD_ALL`, `IND_2020_PLFS_V01_M_V04_A_GLD_ALL`, `IND_2021_PLFS_V01_M_V05_A_GLD_ALL`, `IND_2022_PLFS_V01_M_V02_A_GLD_ALL` (all accessed on 1/25/2026) |
| NPL-LFS | Labor Force Survey| 1998-1999 (first), 2008-2009 (second), 2017-2018 (third) | Central Bureau of Statistics (CBS) | [NPL-LFS 1998](https://microdata.nsonepal.gov.np/index.php/catalog/1), [NPL-LFS 2008](https://microdata.nsonepal.gov.np/index.php/catalog/2), [NPL-LFS 2017](https://microdata.nsonepal.gov.np/index.php/catalog/88) (all accessed on 12/13/2025) | `NPL_1998_LFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `NPL_2008_LFS_V01_M_V01_A_GLD_ALL` (1/25/2026), `NPL_2017_LFS_V01_M_V01_A_GLD_ALL` (12/13/2025)|
| NLSS | Nepal Living Standards Survey | 1995-1996 , 2003-2004, 2010-11, 2022-2023 | Central Bureau of Statistics (CBS) | [NLSS 1995](https://microdata.nsonepal.gov.np/index.php/catalog/7) (12/5/2022), [NLSS 2003](https://microdata.nsonepal.gov.np/index.php/catalog/9) (12/5/2022), [NLSS 2010](https://microdata.nsonepal.gov.np/index.php/catalog/37) (8/27/2021), [NLSS 2022](https://data.nsonepal.gov.np/dataset/b6c3c19b-4b15-44bf-8653-1571e76dad14/resource/e2d52301-1c25-498b-8732-4326c62a2372/download/nlss-iv.pdf) (4/3/2025)| `NPL_1995_LSS-I_v01_M_v03_A_SARMD` (4/8/2022), `NPL_2003_LSS-II_v01_M_v04_A_SARMD` (4/8/2022), `NPL_2010_LSS-III_v01_M_v05_A_SARMD` (4/8/2022), `NPL_2022_LSS-IV_V01_M_V02_A_GMD_ALL` (3/6/2025) |
| NPHC | National Population and Housing Census | 2011 | Central Bureau of Statistics (CBS) | [NPHC 2011](https://microdata.nsonepal.gov.np/index.php/catalog/54) (12/13/2021) | |
| PAK-HIES* | Household Integrated Economic Survey | 2007-2008, 2010-2011, 2011-2012, 2013-2014, 2015-2016, 2018-2019 | Pakistan Bureau of Statistics (PBS) | [PAK-HIES 2007](https://www.pbs.gov.pk/wp-content/uploads/2020/07/microdata_2007_08_stata.zip) (9/10/2022), [PAK-HIES 2010](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data-in-stata-1.zip) (9/10/2022), [PAK-HIES 2011](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data-in-stata.zip) (7/20/2021), [PAK-HIES 2013](https://www.pbs.gov.pk/hies/) (9/10/2022), [PAK-HIES 2015](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data_stata_2015-16.zip) (9/10/2022), [PAK-HIES 2018](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data_in_stata.zip) (9/10/2022) | `PAK_2007_HIES_v02_M_v02_A_SARMD`, `PAK_2010_HIES_v01_M_v05_A_SARMD`, `PAK_2011_HIES_v01_M_v05_A_SARMD`, `PAK_2013_HIES_v01_M_v05_A_SARMD`, `PAK_2015_HIES_v01_M_v03_A_SARMD`, `PAK_2018_HIES_v01_M_v01_A_SARMD` (all accessed on 4/25/2022) |
| PIHS | Pakistan Integrated Household Survey | 1991 | Pakistan Bureau of Statistics (PBS)| [PIHS 1991](https://microdata.worldbank.org/index.php/catalog/543) (4/28/2022) |
| PSLM* | Pakistan Social And Living Standards Measurement | 2010-2011, 2012-2013, 2014-2015, 2019-2020 | Pakistan Bureau of Statistics (PBS) | [PSLM2010](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data-in-stata-10-11.zip) (4/28/2022), [PSLM 2012](https://www.pbs.gov.pk/wp-content/uploads/2020/07/data-in-spss-12-13.zip) (4/28/2022), [PSLM 2014](https://www.pbs.gov.pk/wp-content/uploads/2020/07/Data-in-stata.zip) (4/28/2022), [PSLM 2019](https://www.pbs.gov.pk/wp-content/uploads/2020/07/stata_data_pslm_2019_20.zip) (8/27/2021) | |
| LKA-HIES | Household Income and Expenditure Survey | 1990-1991, 1995-1996, 2002, 2006-2007, 2009-2010, 2012-2013, 2016, 2019 | Department of Census and Statistics (DCS) | [LKA-HIES 1990](https://nada.statistics.gov.lk/index.php/catalog/31), [LKA-HIES 1995](https://nada.statistics.gov.lk/index.php/catalog/33), [LKA-HIES 2002](https://nada.statistics.gov.lk/index.php/catalog/38), [LKA-HIES 2006](https://nada.statistics.gov.lk/index.php/catalog/35), [LKA-HIES 2009](https://nada.statistics.gov.lk/index.php/catalog/36), [LKA-HIES 2012](https://nada.statistics.gov.lk/index.php/catalog/37), [LKA-HIES 2016](https://catalog.ihsn.org/catalog/7380/), [LKA-HIES 2019](https://nada.statistics.gov.lk/index.php/catalog/476) (all accessed on 8/27/2021)| `LKA_2002_HIES_v01_M_v03_A_SARMD_IND` (8/27/2021), `LKA_2006_HIES_v01_M_v03_A_SARMD_IND` (8/27/2021), `LKA_2009_HIES_v01_M_v03_A_SARMD_IND` (8/27/2021), `LKA_2012_HIES_v01_M_v03_A_SARMD_IND` (8/27/2021), `LKA_2016_HIES_v01_M_v02_A_SARMD_IND` (5/23/2022), `LKA_2019_HIES_v01_M_v03_A_SARMD_IND` (3/6/2025) |
| LKA-LFS | Labor Force Survey | 1992-2021 bi-/annual | Department of Census and Statistics (DCS) |[LKA-LFS1992](https://nada.statistics.gov.lk/index.php/catalog/453), [LKA-LFS 1993](https://nada.statistics.gov.lk/index.php/catalog/455), [LKA-LFS 1994](https://nada.statistics.gov.lk/index.php/catalog/460), [LKA-LFS 1995](https://nada.statistics.gov.lk/index.php/catalog/474), [LKA-LFS 1996](https://nada.statistics.gov.lk/index.php/catalog/462), [LKA-LFS 1998](https://nada.statistics.gov.lk/index.php/catalog/13), [LKA-LFS 1999](https://nada.statistics.gov.lk/index.php/catalog/14), [LKA-LFS 2000](https://nada.statistics.gov.lk/index.php/catalog/15), [LKA-LFS 2001](https://nada.statistics.gov.lk/index.php/catalog/16), [LKA-LFS 2002](https://nada.statistics.gov.lk/index.php/catalog/17), [LKA-LFS 2003](https://nada.statistics.gov.lk/index.php/catalog/18), [LKA-LFS 2006](https://nada.statistics.gov.lk/index.php/catalog/336), [LKA-LFS 2007](https://nada.statistics.gov.lk/index.php/catalog/22), [LKA-LFS 2008](https://nada.statistics.gov.lk/index.php/catalog/435), [LKA-LFS 2011](https://nada.statistics.gov.lk/index.php/catalog/26), [LKA-LFS 2012](https://nada.statistics.gov.lk/index.php/catalog/27), [LKA-LFS 2013](https://nada.statistics.gov.lk/index.php/catalog/28), [LKA-LFS 2014](https://nada.statistics.gov.lk/index.php/catalog/29), [LKA-LFS 2015](https://nada.statistics.gov.lk/index.php/catalog/441), [LKA-LFS 2019](https://nada.statistics.gov.lk/index.php/catalog/445), [LKA-LFS 2020](https://nada.statistics.gov.lk/index.php/catalog/481), [LKA-LFS 2021](https://nada.statistics.gov.lk/index.php/catalog/486) (all accessed on 12/13/2025)| `LKA_1992_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1993_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1994_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1995_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1996_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1998_LFS_V01_M_V02_A_GLD_ALL`, `LKA_1999_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2000_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2001_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2002_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2003_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2004_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2006_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2007_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2008_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2011_LFS_V01_M_V02_A_GLD_ALL`, `LKA_2012_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2013_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2014_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2015_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2019_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2020_LFS_V01_M_V03_A_GLD_ALL`, `LKA_2021_LFS_V01_M_V03_A_GLD_ALL` (all accessed on 1/25/2026) |


### Statement about Rights

We certify that the authors of the manuscript have legitimate access to and permission to use the data used in this manuscript.

## Instructions for Replicators

New users should follow these steps to run the package successfully:
- Users must first have access to all data files. While the mentioned links indicate the survey-specific details, it is recommended to download the listed files via datalib (raw and SARMD/SARLAB data), and place them in the `data/raw/HHS` folder (see [folder structure](#folder-structure)). The survey-specific GLD files can be accessed via the dedicated World Bank internal directory `gld-public (\\wbntpcifs\gld)`. Alternatively, users can contact the team to receive the complete data given prior requested and approved data access.
- Ensure all required software and dependencies are installed (see [requirements](#requirements)).
- Update the following files with your root directory path:
    - `1_main_cleaning.do` (line 13)
    - `2_main_analysis.R` (line 9)
- Run the `1_main_cleaning.do` file to create the cleaned datasets used in the analysis.
- Run the `2_main_analysis.R` file to produce the outputs (tables and figures) of the manuscript and its appendix.
Note, the replication of the forest estimation based results (Figure A10) is computational heavy with associated long run times (>5days) and, hence, are excluded from the default options of the main analysis file.

## List of Exhibits

The provided code reproduces all tables and figures in the manuscript (subfolders `main`) and its appendix (subfolders `annex`), i.e., table 1 of the manuscript can be found in `outputs/tables/main` as `survey_overview.tex` and is produced in code file `2.1_IOp_cross-section_intro.R` (line 82).
All results used to create the tables and figures are stored as `.R` files in `outputs/files` with the naming convention `outcome_type_circumstances_datasource_estimation` with the defaults (omitted from name) being cohort-based pseudo panel for `type`, the main dataset (HHS + LFS) as described in Section A1 for `datasource` and parametric for `estimation`. 
In-text numbers can be reproduced with the public material provided.

| Exhibit name | Output filename | Script |
|--------------|-----------------|--------|
| Table 1 – Survey Overview | survey_overview.tex | 2.1_IOp_cross-section_intro.R (line 82) |
| Table 2 – Snapshot: Inequality & IOp across Outcome Dimensions | educ_cons_labor_cs_last.tex | 2.1_IOp_cross-section_intro.R (line 175) |
| Figure 1 – Total Inequality vs IOp across the World | gini_iop_world.png | 2.1_IOp_cross-section_intro.R (line 282) |
| Figure 2 – Evolution Total Inequality and Relative IOp: Education & Consumption | educ_cons.png | 2.7_joint_graphs.R (line 79) |
| Figure 3 – Primary Education: Population Share and IOp | share_iop_prim.png | 2.2_IOp_cohort.R (line 56) |
| Figure 4 – Changes in IOp across Outcome Dimensions | change_educ_lfp_cons.png | 2.7_joint_graphs.R (line 126) |
| Figure 5 – Evolution IOp of Labor Market Outcomes | iop_lfp_paidwage_wage.png | 2.2_IOp_cohort.R (line 264) |
| Figure 6 – Evolution of Education Stocks across Cohorts | shares_educ_cat.png | 2.2_IOp_cohort.R (line 119) |
| Figure 7 – IOp in Education: Years vs. Primary vs. Upper Secondary | iop_uppsec_prim_educ.png | 2.2_IOp_cohort.R (line 82) |
| Figure 8 – Labor Market Returns to Education | returns_educ.png | 2.3_regression_analyses.R (line 182) |
| Figure 9 – Returns to Education by Degree: Primary vs. Upper Secondary | lm_lfp_paidwage_educ_cat.png | 2.3_regression_analyses.R (line 351) |
| Figure 10 – Gender Differential in Educational Returns: Primary vs. Upper Secondary | lm_lfp_paidwage_female.png | 2.3_regression_analyses.R (line 377) |
| Figure 11 – Labor Market IOp by Education Level | iop_lfp_paidwage_educ_cat_sample.png | 2.2_IOp_cohort.R (line 300) |
| Figure 12 – Decomposing IOp in Years of Education by Circumstances | circ_imp_educ.png | 2.5_circ_importance.R (line 40) |
| Figure 13 – Decomposing LFP IOp by Circumstances | circ_imp_lfp.png | 2.5_circ_importance.R (line 112) |
| Figure 14 – Profiles 1950s – Years of Education | prof_educ.png | 2.4_opportunity_profiles.R (line 201) |
| Figure 15 – Changes in Opportunity Profiles – Years of Education | change_5090s_educ.png | 2.4_opportunity_profiles.R (line 221) |
| Figure 16 – Changes in Opportunity: Secondary/Higher Education vs. LFP | change_uppsec_lfp.png | 2.7_joint_graphs.R (line 202) |
| Figure 17 – Growth Incidence (OGIC) – Consumption | growth_5080s_cons.png | 2.4_opportunity_profiles.R (line 237) |
| Appendix | | | |
| Table A1 – Survey Overview by Outcome | survey_overview_outcome.tex | 2.1_IOp_cross-section_intro.R (line 123) |
| Table A2 – Sample Size by Birth Cohort | sample_size_cohort.tex | 2.6_joint_tables.R (line 68) |
| Table A3 – Total Inequality & Relative IOp across Outcomes & Cohorts | educ_cons_labor.tex | 2.6_joint_tables.R (line 51) |
| Table A4 – Circumstances – Geographical Region | geo_level.tex | robustness_checks/robustness_education.R |
| Table A5 – Geo-spatial Migration | migration.tex | robustness_checks/robustness_migration.R (line 19) |
| Table A6 – Circumstances – Demographic Group | demo.tex | 2.6_joint_tables.R |
| Table A7 – Population Summary Opportunity Profiles | p_educ.tex | 2.4_opportunity_profiles.R (line 355) |
| Table A8 – Years of Education Coresident Analysis - Distortion vs. Proxy | distortion_educ.tex | robustness_checks/robustness_coresident.R (line 112) |
| Table A9 – Robustness Consumption: Survey Methodology India | india_cons.tex | robustness_checks/robustness_consumption.R (line 198) |
| Table A10 – Cohort-Age Group Table: Bangladesh | cons_cohort_age_Bangladesh.tex | robustness_checks/robustness_consumption.R (line 36) |
| Table A11 – Labor Market Returns to Education: LFP (years) | reg_lfp_educ_years.tex | 2.3_regression_analyses.R (line 570) |
| Table A12 – Labor Market Returns to Education: Wage-Employment (years) | reg_paidwage_educ_years.tex | 2.3_regression_analyses.R (line 570) |
| Table A13 – Labor Market Returns to Education: Wages (years) | reg_wage_educ_years.tex | 2.3_regression_analyses.R (line 570) |
| Table A14 – Labor Market Returns & Differentials: LFP (edu categories) | reg_lfp_educ_cat.tex | 2.3_regression_analyses.R (line 570) |
| Table A15 – Labor Market Returns to Education: Wage-Employment (edu categories) | reg_paidwage_educ_cat.tex | 2.3_regression_analyses.R (line 570) |
| Figure A1 – Population CDF – Years of Education | cdf_educ_female.png | 2.4_opportunity_profiles.R (line 291) |
| Figure A2 – Assortative Mating across Birth Cohorts | corr_educ.png | robustness_checks/robustness_education.R (line 50) |
| Figure A3 – Sampling Frame: Coresident Share by Gender | coresident_share_gender.png | robustness_checks/robustness_coresident.R (line 145) |
| Figure A4 – Circumstance Importance: Years of Education - Coresident Sample | circ_imp_educ_coresident.png | robustness_checks/robustness_coresident.R (line 178) |
| Figure A5 – Total Inequality Comparison PIP – Consumption | gini_pip.png | 2.1_IOp_cross-section_intro.R (line 336) |
| Figure A6 – Profiles 1950s – Consumption | prof_cons.png | 2.4_opportunity_profiles.R (line 203) |
| Figure A7 – Population CDFs – Consumption: Changes in Urbanity | cdf_cons_urban.png | 2.4_opportunity_profiles.R (line 309) |
| Figure A8 – Growth in Population Shares – Consumption: Changes in Urbanity | n_growth_cons_urban.png | 2.4_opportunity_profiles.R (line 326) |
| Figure A9 – Decomposing Consumption IOp by Circumstances | circ_imp_cons.png | 2.5_circ_importance.R (line 73) |
| Figure A10 – Evolution of IOp: Parametric vs. Forest Estimation | comp_para_forest.png | robustness_checks/robustness_forest.R (line 77) |
| Figure A11 – LFP Estimates across different Data Sources (age 15–64) | lfp_cs_overview.png | robustness_checks/robustness_labor.R (line 88) |
| Figure A12 – IOp in LFP & Wage-Employment by Data Source & Sample Definition | iop_lfp_paidwage_paidwage_all_hhs_lfs.png | 2.2_IOp_cohort.R (line 227) |
| Figure A13 – Evolution Composition prime working age population (35–54 years) | lfp_paidwage_shares.png | 2.3_regression_analyses.R (line 624) |
| Figure A14 – Urban Premia in Educational Returns: Primary vs. Upper Secondary | lm_lfp_paidwage_urban.png | 2.3_regression_analyses.R (line 403) |
| Figure A15 – Profiles 1950s – LFP | prof_lfp.png | 2.4_opportunity_profiles.R (line 203) |
| Figure A16 – Profiles 1950s – Wage-Employment | prof_paidwage.png | 2.4_opportunity_profiles.R (line 203) |
| Figure A17 – Profiles LFP across Surveys (2010s) | prof_lfp_cs_last.png | robustness_checks/robustness_labor.R (line 178) |
| Figure A18 – Profiles Wage-Employment across Surveys (2010s) | prof_paidwage_cs_last.png | robustness_checks/robustness_labor.R (line 195) |
| Figure A19 – Decomposing Wage-Employment IOp by Circumstances | circ_imp_paidwage.png | 2.5_circ_importance.R (line 133) |
| Figure A20 – Decomposing Wage IOp by Circumstances | circ_imp_wage.png | 2.5_circ_importance.R (line 153) |

## Requirements

### Software Requirements

- **Stata version 19**

- **R 4.5.1** with the following packages:
  | Package | Version |
  |---------|---------|
  | tidyverse | 2.0.0 |
  | sandwich | 3.1.1 |
  | rlang | 1.1.6 |
  | haven | 2.5.5 |
  | xtable | 1.8.4 |
  | data.table | 1.17.8 |
  | DescTools | 0.99.60 |
  | broom | 1.0.9 |
  | matrixStats | 1.5.0 |
  | survey | 4.4.8 |
  | margins | 0.3.28 |
  | dineq | 0.1.0 |
  | boot | 1.3.31 |
  | party | 1.3.18 |
  | partykit | 1.2.24 |
  | latex2exp | 0.9.6 |
  | labelled | 2.15.0 |
  | car | 3.1.3 |

### Memory and Runtime and Storage Requirements

The code has been run on a i7-1185G7 (3.00 GHz) with 16GB RAM with runtime of 0:35h for the data cleaning and 5:45h for the analysis (excluding the forest robustness check which takes >5 days).
The unzipped repository requires 45.3 GB of storage.
During the cleaning process interim files are written (5.6 GB) but removed after the final datasets have been created.

## Code Description

The code files are split in two sections, 1. data cleaning and 2. analysis, which have to be run subesquently and are detailed below. While `1_main_cleaning.do` creates the datasets used in the analysis, `2_main_analysis.R` reproduces all tables and figures of the manuscript and its annex (see [List of exhibits](#list-of-exhibits)).

### Data Cleaning
To start the dataset replication, you first have to set the root directory in line 13 of `1_main_cleaning.do`. Running the do-file creates the following two datasets based on different sources.

The `HHS_dataset.dta` is based on *household surveys* (see Table A1 and Section A1 for details) and constructed using the following code files:

- `parent_merge.do` is a program extracting parental background data for individuals coresident with their parents;

- `1.1-1.8_country.do` replicates the construction of the country-specific dataset based on Household Surveys (HHS) using files from the South Asia Region Team for Statistical Development (SARTSD)’s South Asia Regional Micro Database ([SARMD](https://worldbank.github.io/SARMD_guidelines)) and raw data ;

- `1.9_IOp_dataset.do` appends country files to generate dataset for analysis (education, consumption, labor).

The `LFS_dataset.dta` is based on *labor force surveys* (see Table A1 and Section A1 for details) and constructed using the following code files:

- `1.10_LFS_country_datasets.do` replicates the construction of the country-specific datasets based on Labor Force Surveys (LFS) using files from the Jobs Group’s Global Labor Database ([GLD](https://worldbank.github.io/gld)) and the South Asia Regional Statistical Team's repository on Labor Force Surveys ([SARLAB](https://github.com/worldbank/SAR_LaborForceSurveys));

- `1.11_LFS_dataset.do` appends country files to generate dataset for the labor market analysis.


### Analysis
All results can be created using the `2_main_analysis.R` file. To limit running time, one can chose the outcome of interest (all, education, consumption, labor market and coresident education), the type of analysis (cross-section/cohort-based pseudo panel) and the estimation method (parametric/forest). The default option produces all results with the exception of the forest-based estimation. To start the analysis replication, you first have to set the root directory (line 9). The following files are called from the master file:

- `2.0_data_import.R`: imports and prepares the relevant data for analysis;
- `2.1_IOp_cross-section_intro.R`: creates the cross-sectional results of sections 1 and 4.1;
- `2.2_IOp_cohort.R`: creates the cohort-based pseudo panel results of sections 4.2 and 5;
- `2.3_regression_analyses.R`: performs the regression analysis for educational return convexity and differential returns by circumstance;
- `2.4_opportunity_profiles.R`: estimates opportunity profiles and produces related graphs,
- `2.5_circ_importance.R`: estimates circumstance importance and produces related graphs,
- `2.6_joint_tables.R`: produces the survey overview, sample size and result tables (Tables 1, A1, A2, A3);
- `2.7_joint_graphs.R`: produces main graphs across outcome dimensions (Figures 2, 4, 16).

Those files make use of the following *functions*:
- `iop_ex-ante`: estimates IOp for different outcomes, estimation methods and estimation types;
- `circ_imp_para`: computes circumstance importance using the parametric IOp estimation method based on the Shapley value;
- `profiles`: calculates opportunity profiles (i.e., mean outcome of types) by for different outcomes and estimation types.
 
Note, the functions are build to perform a bootstrap analysis to report 95\% confidence intervals (`_u`= upper CI, `_l` = lower CI) besides the point estimate (`_p`). Those are omitted from the manuscript for brevity as CIs are limited in size for the main results. 

Additionally, *robustness checks* are performed for the different outcomes:
- `robustness_consumption.R`: checks results robustness for age-profiles (i.e., cohort age tables, Table A10) and India's different survey methodologies (Table A9);
- `robustness_coresident.R`: creates the coresident-based results of the appendix (section A.2);
- `robustness_education.R`: estimates assortative mating (Figure A2);
- `robustness_labor.R`: produces the comparison of LFP with ILO estimates (Figure A11), estimates the cross-sectional opportunity profiles for comparing LFS \& HHS (Figures A17 and A18);
- `robustness_migration.R`: calculates the migration rates (Table A5);
- `robustness_forest.R`: estimates the main results using the conditional inference forests and produces the comparison with parametric results (Figure A9); to run it set `robustness_forest = TRUE` (`2_main_analysis.R`, line 72).


## Folder Structure

```
data
  ├── raw
  │   ├── HHS
  │   │   ├── AFG
  │   │   │   ├── raw data national survey
  │   │   │   │   ├── first year
  │   │   │   │   ├── ...
  │   │   │   │   └── last year
  │   │   │   └── SARMD
  │   │   ├── ...
  │   │   └── PAK
  │   ├── LFS
  │   │   ├── BGD
  │   │   │   ├── raw data national survey
  │   │   │   │   ├── first year
  │   │   │   │   ├── ...
  │   │   │   │   └── last year
  │   │   │   └── GLD
  │   │   ├── ...
  │   │   └── LKA
  │   ├── auxiliary_non_public
  │   └── auxiliary
  │       ├── demo
  │       ├── geo_level
  │       └── ...
  ├── interim
  └── clean
code
  ├── 1_main_cleaning.do
  ├── 2_main_analysis.R
  ├── 1_cleaning 
  │   └── cleaning do-files & programs
  └── 2_analysis
      └── analysis scripts & functions
outputs
  ├── files
  ├── figures
  │   ├── main
  │   └── annex
  └──tables
      ├── main
      └── annex
```