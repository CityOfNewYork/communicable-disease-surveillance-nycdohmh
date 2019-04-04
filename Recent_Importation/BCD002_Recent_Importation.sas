
data _null_;
call symput ('tday',put(today(),date9.));
run;

%put &tday;

/*Read in refreshed dataset*/
data zikawork;
set zika.Zika_input_dataset_&tday;
run;

/*Assign weight only to census tracts with any recent tests*/
data zikaworkall;
set zikawork;
if ZikaTestsRecent>0 then weight=1;
run;

/*Fit logistic regression model; output dataset with both individual and cross-validated prediction probabilities*/
proc logistic data=zikaworkall;
class Qimmigrants (ref='1') Qancestry (ref='1') QAllResidents (ref='1') / param=ref;
model Binary1mo (event='1') = OldCases DNFCHKCases  PovProp Qimmigrants Qancestry HispProp Fem1544Prop  QAllResidents / 
      firth lackfit rsq;
weight weight;
output out=preds predprobs=i predprobs=crossvalidate;
run;

/*Compare ROC curves for fitted vs. uninformative (intercept-only) model applied to cross-validated data*/
      proc logistic data=preds;
        model Binary1mo (event='1') = ;
            weight weight;
        roc pred=xp_1;
        roccontrast;
            where xp_1 ne . and ZikaTestsRecent>0;
        run;
            
/*Save individual predicted probability for mapping nowcast*/     
proc sql;
create table zikapreds as
      select      CensusTract,
                  ZikaTestsRecent,
                  ZIKCASES_1mo,
                  (ZIKCASES_1mo/ZikaTestsRecent) as PosRate,
                  ip_1 as PREDICTED_RISK
      from preds;
quit;

