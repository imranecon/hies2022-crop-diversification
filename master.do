*==============================================================================
* master.do
* Crop diversification and household income in rural Bangladesh (HIES 2022)
* 
* Author: Imran Hossain
*
* Set the root path below, then run this file. It runs every script in order.
*==============================================================================

version 16
clear all
set more off
set linesize 120

*-- Root path: change this line only ------------------------------------------
global root    "D:/hies2022-crop-diversification"

*-- Folders -------------------------------------------------------------------
global data    "$root/data"
global derived "$root/data/derived"
global code    "$root/code"
global out     "$root/output"

capture mkdir  "$derived"
capture mkdir  "$out"
capture mkdir  "$out/tables"
capture mkdir  "$out/figures"
capture mkdir  "$out/logs"

*-- User-written packages -----------------------------------------------------
capture which esttab
if _rc ssc install estout, replace

*-- Run ----------------------------------------------------------------------
capture log close
log using "$out/logs/master.log", replace text

do "$code/01_build.do"
do "$code/02_clean.do"
do "$code/03_analysis.do"

log close
