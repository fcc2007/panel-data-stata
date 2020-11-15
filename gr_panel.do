* -----------------------------------------------------------------------------
*                               Introduction
* -----------------------------------------------------------------------------
* 11921 Users at a Chinese social Q&A community were tracked for a 20-week 
* period from December 16, 2017 to April 28, 2018. Some key variables were 
* recorded, including counts of answers, questions and followers, etc. Using
* this panel data, I will show how to estimate pooled, fixed and random
* effects models in Stata, and how to select among those models in it also.
* -----------------------------------------------------------------------------

* -----------------------------------------------------------------------------
*                                 Dataset
* -----------------------------------------------------------------------------
set mem 2000m //set memory
set matsize 5000 //set the max number of variables
clear all //clear memory                 
set more off //don't pause when screen fills

cd "/Users/jimmyc.fang/Desktop/gr_panel" //set work directory
log using gr_panel.log, replace //create a log-file to save code and output
import delimited grassroots.csv, encoding(ISO-8859-1) //import dataset

gen date1 = date(substr(date,1,10), "YMD") //truncate time from date
format %td date1 //format date
drop date
rename date1 date
encode url_token, gen(user) //format url_token and store it as user
drop url_token
xtset user date, delta(7 days) //set panel data

* -----------------------------------------------------------------------------
*                    Descriptive Statistics and Graphs
* -----------------------------------------------------------------------------
xtdes //check data
xtsum answer_count question_count articles_count follower_count favorited_count following_count following_question_count participated_live_count //summarize variables
twoway (scatter answer_count follower_count) (lfit answer_count follower_count) //scatter plot and fitted line
twoway (scatter question_count follower_count) (lfit question_count follower_count) //scatter plot and fitted line

* -----------------------------------------------------------------------------
*                           LSDV Regression
* -----------------------------------------------------------------------------
gen ln_answer = ln(answer_count + 1) //logarithmize answer_count
gen ln_question = ln(question_count + 1) //logarithmize question_count
gen ln_follower = ln(follower_count + 1) //logarithmize follower_count
gen ln_favorited = ln(favorited_count + 1) //logarithmize favorited_count
gen ln_following = ln(following_count + 1) //logarithmize following_count
gen ln_following_question = ln(following_question_count + 1) //logarithmize following_question_count
gen ln_participated_live = ln(participated_live_count + 1) //logarithmize participated_live_count

tab date, gen(date) //generate date dummy variables
reg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20 i.user //LSDV regression
avplot ln_follower //partial regression plot of ln_follower
avplots // all partial regression plots
xtline ln_answer //time series plot of ln_answer

* -----------------------------------------------------------------------------
*              Model Selection - Pooled vs Fixed Effects Regression
* -----------------------------------------------------------------------------
xtreg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20, fe //twoway fixed effects model
ssc install xtcsd //install xtcsd
xtcsd, pes //test cross sectional dependency
xtcsd, fri //test cross sectional dependency
xtcsd, fre //test cross sectional dependency

* when cross sectional dependency exists
ssc install xtscc //install xtscc
xi: xtscc ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20 i.user
testparm _Iuser* //F test

* when cross sectional dependency does not exist
xi: reg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20 i.user, cluster(user)
testparm _Iuser* //F test

* -----------------------------------------------------------------------------
*              Model Selection - Pooled vs Random Effects Regression
* -----------------------------------------------------------------------------
xtreg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20, re //random effects model
findit xttest0 //install command
findit xttest1 //install command
xttest0 //LM test of individuality
xttest1 //LM test of individuality

* -----------------------------------------------------------------------------
*              Model Selection - Fixed vs Random Effects Regression
* -----------------------------------------------------------------------------
xtreg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20, fe // fixed effects model
est store FE //store the estimations
xtreg ln_answer ln_follower ln_favorited ln_following ln_following_question ln_participated_live date2-date20, re // random effects model
hausman FE, sigmamore/sigmaless // compare two models using hausman test

* -----------------------------------------------------------------------------
*                                 Outro
* -----------------------------------------------------------------------------
* For readers who are not familiar with panel data models, please go to 
* www.icourse163.org. You will find an online Chinese course about panel data
* analysis given by Prof. Hongsheng Fang from Zhejiang University. It 
* elaborates on panel data models and their application in Stata. The codes 
* provided in his course are much more detailed than the codes here.
* -----------------------------------------------------------------------------

log close
translate gr_panel.smcl gr_panel.txt, replace
