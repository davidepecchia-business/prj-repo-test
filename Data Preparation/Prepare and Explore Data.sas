cas;
caslib _all_ assign;

/************************************************************************/
/* This example illustrates various tools for assaying, assessing,      */
/* modifying and preparing data prior to modeling. It uses HMEQ         */
/* dataset as input and produces HMEQ_PREPPED dataset. The HMEQ_PREPPED */
/* dataset is used in subsequent examples.                              */
/*                                                                      */
/* The steps include:                                                   */
/*                                                                      */
/* (1) PREPARE AND EXPLORE                                              */
/*     a) Load data set into CAS                                        */
/*     b) Explore                                                       */
/*     c) Impute                                                        */
/*     d) Identify variables that explain variance                      */
/*     e) Perform a cluster analysis to identify homogeneous            */
/*        groups in the data                                            */
/*     f) Perform principal components analysis to assess collineary    */
/*        among candidate, interval valued inputs                       */
/************************************************************************/

/************************************************************************/
/* Setup and initialize for later use in the program                    */
/************************************************************************/
/* Define a CAS engine libref for CAS in-memory data tables */

/* Specify the data set names */
%let sasdata          = INPUT.CREDITWRITEOFF;                     
%let casdata          = INPUT.CREDITWRITEOFF;

/* Specify the data set inputs and target */
%let class_inputs    = atmuser CARD_TYPE ecomuser okmail;
%let interval_inputs = acctcd_n age behave_scr CREDIT_LIM; 
%let target          = writeoff;

%let im_class_inputs    = atmuser CARD_TYPE ecomuser okmail;
%let im_interval_inputs = im_acctcd_n im_age im_behave_scr im_CREDIT_LIM; 


/* Specify a folder path to write the temporary output files */
%let outdir = &_SASWORKINGDIR;


/************************************************************************/
/* Load data into CAS if needed. Data should have been loaded in        */
/* step 1, it will be loaded here after checking if it exists in CAS    */
/************************************************************************/
%if not %sysfunc(exist(&casdata)) %then %do;
  proc casutil;
    load data=&sasdata casout="creditwriteoff" outcaslib=input;
  run;
%end;


/************************************************************************/
/* Explore the data and plot missing values                             */
/************************************************************************/
proc cardinality data=&casdata outcard=input.data_card;
run;

proc print data=input.data_card(where=(_nmiss_>0));
  title "Data Summary";
run;

data data_missing;
  set input.data_card (where=(_nmiss_>0) keep=_varname_ _nmiss_ _nobs_);
  _percentmiss_ = (_nmiss_/_nobs_)*100;
  label _percentmiss_ = 'Percent Missing';
run;

proc sgplot data=data_missing;
  title "Percentage of Missing Values";
  vbar _varname_ / response=_percentmiss_ datalabel categoryorder=respdesc;
run;
title;


/************************************************************************/
/* Impute missing values                                                */
/************************************************************************/
proc varimpute data=&casdata;
  input acctcd_n /ctech=mean;
  input age /ctech=median;
  input behave_scr /ctech=random;
  input CREDIT_LIM /ctech=mean ;
  output out=input.creditwriteoff_prepped copyvars=(_ALL_);
  code file="&outdir./impute_score.sas";
run;
    
    
/************************************************************************/
/* Identify variables that explain variance in the target               */
/************************************************************************/
/* Discriminant analysis for class target */
proc varreduce data=input.creditwriteoff_prepped technique=discriminantanalysis;  
  class &target &im_class_inputs.;
  reduce supervised &target=&im_class_inputs. &im_interval_inputs. / maxeffects=8;
  ods output selectionsummary=summary;	     
run;

data out_iter (keep=Iteration VarExp Base Increment Parameter);
  set summary;
  Increment=dif(VarExp);
  if Increment=. then Increment=0;
  Base=VarExp - Increment;
run;

proc transpose data=out_iter out=out_iter_trans;
  by Iteration VarExp Parameter;
run;

proc sort data=out_iter_trans;
  label _NAME_='Group';
  by _NAME_;
run;

/* Variance explained by Iteration plot */
proc sgplot data=out_iter_trans;
  title "Variance Explained by Iteration";
  yaxis label="Variance Explained";
  vbar Iteration / response=COL1 group=_NAME_;
run;
title;





