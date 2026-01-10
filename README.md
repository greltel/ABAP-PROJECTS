[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/greltel/ABAP-Cloud-Logger/blob/main/LICENSE)
![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/ABAP-Cloud-Logger)

# Table of contents
1. [ABAP-Projects](#ABAP-Projects)
2. [License](#License)
3. [Contributors-Developers](#Contributors-Developers)
4. [Motivation for Creating the Repository](#Motivation-for-Creating-the-Repository)
5. [Design Goals-Features](#Design-Goals-Features)
6. [Project 1 Dynamic SALV Console](#Project-1-Dynamic-SALV-Console)
7. [Project 2 Dynamic Count of Unique-Multiple Values of Internal Table](#Project-2-Dynamic-Count-of-Unique-Multiple-Values-of-Internal-Table)
8. [Project 3 Dynamic Texts Export](#Project-3-Dynamic-Texts-Export)
9. [Project 4 Dynamic Input-Output Convertion](#Project-4-Dynamic-Input-Output-Convertion)
10. [Project 5 Dynamic Split of Table into Smaller Ones](#Project-5-Dynamic-Split-of-Table-into-Smaller-Ones)

# ABAP-Projects

Repository for Projects based on ABAP.It contains a collection of modern, reusable ABAP utilities and dynamic tools designed to streamline daily development tasks.

# License
This project is licensed under the [MIT License](https://github.com/greltel/ABAP-PROJECTS/blob/Main/LICENSE).

# Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

# Motivation for Creating the Repository

The primary motivation behind this repository is to share knowledge and foster growth within the ABAP community. My goal is to help fellow developers boost their productivity by providing reusable, modern, and clean code solutions.

Since the ABAP ecosystem is niche, I strongly believe in the power of open-source sharing to drive our collective progress. Contributions, suggestions for code optimization, or new project ideas are always welcome.

# Design Goals-Features

* Install via [ABAPGit](http://abapgit.org)
* Code based on New ABAP Syntax. 7.50 and later
* Comments throughout the Code(when necessary)
* Passed ATC Check Variant S4HANA_READINESS_2023
* Unit Tested

# Project 1 Dynamic SALV Console

Display any table using cl_salv_Table alv. Scope of this project is to create a cl_salv_table based alv which is
as dynamic as possible. There are no data declarations(wherever possible), no custom screen, no gui status etc.
Also many custom functions have been added to ALV toolbar like custom details screen( se16n inspired ), 
hide/show empty columns of table and edit button. The whole point of this project is to reveal the real potential of 
cl_salv_table based ALV even though there are limitations compared to cl_gui_alv_grid. We call this project Console because
you can use it as a utility to display any table of the system plus display your own Excel file.

# Project 2 Dynamic Count of Unique-Multiple Values of Internal Table

Use the Static Class Method to Retrieve Unique and Multiple values of Any Table.

# Project 3 Dynamic Texts Export

Download any Text Object of SAP System into Excel File directly.

# Project 4 Dynamic Input-Output Convertion

Dynamically convert a DDIC value to Input/Output format.

# Project 5 Dynamic Split of Table into Smaller Ones

Split Internal Table into Smaller ones specifying split segments.
Especially useful for parallel processing tasks.
