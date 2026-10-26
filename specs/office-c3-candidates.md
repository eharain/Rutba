# Office C3: real public documents to measure against (for the owner's approval)

Listed 2026-10-26 by the open-formats builder from its own knowledge; nothing
has been fetched, and no address has been checked. Each file and its licence
are confirmed when it is fetched. Plan Part C item 3; the owner approves the
list before anything is downloaded.

| # | Publisher | Item and address | Format | Licence |
|---|---|---|---|---|
| 1 | ONS | Consumer price inflation tables: ons.gov.uk/economy/inflationandpriceindices/datasets/consumerpriceinflation | xlsx | OGL v3 |
| 2 | ONS | Summary of labour market statistics (A01): ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/datasets/summaryoflabourmarketstatistics | xlsx/xls | OGL v3 |
| 3 | ONS | Population estimates UK/E&W/S/NI: ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland | xlsx | OGL v3 |
| 4 | MHCLG | English indices of deprivation 2019: gov.uk/government/statistics/english-indices-of-deprivation-2019 | xlsx | OGL v3 |
| 5 | DESNZ | Energy Trends: gov.uk/government/statistics/energy-trends | xlsx (ods) | OGL v3 |
| 6 | DfT | Road traffic statistics (TRA): gov.uk/government/statistical-data-sets/road-traffic-statistics-tra | ods/xlsx | OGL v3 |
| 7 | HM Treasury | PESA tables: gov.uk/government/collections/public-expenditure-statistical-analyses-pesa | xlsx | OGL v3 |
| 8 | MHCLG | Local authority revenue expenditure and financing: gov.uk/government/collections/local-authority-revenue-expenditure-and-financing | xlsx/ods | OGL v3 |
| 9 | Greater London Authority | London Borough Profiles: data.london.gov.uk/dataset/london-borough-profiles | xlsx | OGL |
| 10 | Scottish Government | SIMD 2020: gov.scot/collections/scottish-index-of-multiple-deprivation-2020/ | xlsx | OGL v3 |
| 11 | NHS England (Digital) | Appointments in General Practice: digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice | xlsx | OGL v3 |
| 12 | Councils (Data Mill North) | council datasets with xlsx files: datamillnorth.org | xlsx | OGL (per dataset) |
| 13 | UK Parliament, Commons Library | constituency data workbooks: commonslibrary.parliament.uk | xlsx | Open Parliament Licence |
| 14 | Cabinet Office / CCS | Model Services Contract: gov.uk/government/publications/model-services-contract | docx | OGL v3 |
| 15 | Cabinet Office | The Short Form Contract: gov.uk/government/publications/the-short-form-contract | docx | OGL v3 |
| 16 | Cabinet Office | The Mid-tier Contract: gov.uk/government/publications/the-mid-tier-contract | docx | OGL v3 |
| 17 | Charity Commission | Model governing documents: gov.uk/government/publications/setting-up-a-charity-model-governing-documents | docx/odt | OGL v3 |
| 18 | DfE | Academy model funding agreements: gov.uk/government/publications/academy-model-funding-agreements | docx | OGL v3 |
| 19 | US Census Bureau | State population estimates: census.gov/data/tables/time-series/demo/popest/2020s-state-total.html | xlsx | US public domain |
| 20 | US BLS | CPI supplemental files: bls.gov/cpi/tables/supplemental-files/ | xlsx | US public domain |
| 21 | US EIA | Monthly Energy Review: eia.gov/totalenergy/data/monthly/ | xlsx | public domain |
| 22 | NIST | SP 800-53 Rev. 5 control catalog: csrc.nist.gov/pubs/sp/800/53/r5/upd1/final | xlsx, docx | US public domain |
| 23 | FedRAMP (GSA) | Documents and templates: fedramp.gov/documents-templates/ | docx, xlsx | US public domain |
| 24 | data.gov | datasets with PPTX resources: catalog.data.gov/dataset?res_format=PPTX | pptx | mostly public domain, per dataset |
| 25 | data.gov | datasets with DOCX resources: catalog.data.gov/dataset?res_format=DOCX | docx | per dataset |
| 26 | data.gov.uk | datasets in PPTX: data.gov.uk/search?filters[format]=PPTX | pptx | OGL, per dataset |
| 27 | Eurostat | tables and Statistics Explained Excel files: ec.europa.eu/eurostat/data/database | xlsx | CC BY 4.0 |
| 28 | European Commission | Funding and Tenders reference documents: ec.europa.eu/info/funding-tenders/opportunities/portal/screen/how-to-participate/reference-documents | docx, xlsx | CC BY 4.0 (confirm per document) |
| 29 | UN DESA | World Population Prospects 2024: population.un.org/wpp/ | xlsx (large) | CC BY 3.0 IGO |
| 30 | World Bank | World Development Indicators, Excel bulk: datacatalog.worldbank.org/search/dataset/0037712/World-Development-Indicators | xlsx (large) | CC BY 4.0 |
| 31 | Australian Bureau of Statistics | CPI time series: abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia | xlsx | CC BY 4.0 |
| 32 | OpenStax | textbook lecture slides, e.g. openstax.org/details/books/introduction-sociology-3e | pptx | CC BY 4.0 (confirm no instructor account needed) |
| 33 | Apache POI | test-data, including spreadsheet/sample.strict.xlsx: github.com/apache/poi/tree/trunk/test-data | xlsx/docx/pptx, some Strict | Apache-2.0 (files from bug reports; check each) |
| 34 | LibreOffice | core QA data (sw/qa/extras/ooxmlexport/data, sc/qa/unit/data/xlsx, sd/qa/unit/data/pptx): git.libreoffice.org/core | docx/xlsx/pptx, possibly Strict | MPL-2.0 |
| 35 | .NET Foundation | Open XML SDK test assets: github.com/dotnet/Open-XML-SDK | docx/xlsx/pptx, possibly Strict | MIT |
| 36 | (made here) | Strict twins of approved items 1 to 31, saved as Strict by Word, Excel and PowerPoint | Strict docx/xlsx/pptx | the source's licence carries over |

No publisher is known to issue Strict as its normal output; real Strict files
come from the open-source test sets (33 to 35) and the twins (36).

How it is measured once approved: the files go in a git-ignored corpus folder
with a SOURCES.json (file, address, publisher, licence, sha256); `npm run
verify:corpus` gives the open rate, round trips, warnings, faults and hangs
per format; under the window lock the same in the real windows, and layout
against Word's and Excel's own PDFs (compare-word.ps1, compare-excel.ps1,
pdf-pages.ps1); Strict and usual forms of each file must open alike, and
Office must reopen our Strict saves (check-strict-office.ps1 needs a -Files
form for this).
