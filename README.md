# In Vitro Screening Comparison

Data and code to accompany the paper "Citation screening for in vitro systematic reviews: a comparison of screening methods and training of a machine learning classifier".

## Code scripts

All code is written in R using R Markdown documents. R version number and package version numbers are included in each script. Details of each script are below. Run each script in order.

- **1-1_data cleaning.Rmd:** Prepare screening method comparison data for analysis; remove excluded data
- **1-2_calculate_performance.Rmd:** Calaculate the performace (sensitivity and specificity) of screening methods at various thresholds
- **1-3_analyse_performance.Rmd:** Plot the performance in a ROC curve and determine the optimal threshold for regex screening methods
- **1-4_search_term_retrieval_comparison.Rmd:** Additional analysis comparing retrieval of studies using the planned vs actual search terms

## Data

Data are stored in the following folders:

- **data-raw:** raw data to be processed
- **data:** data which have undergone some processing
- **data-analysis:** final clean datasets

## Plots

Plot outputs (in PDF file format) are in the `plots` folder.
