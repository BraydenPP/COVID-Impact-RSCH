//this first section only saves over itself so does not need to be run any more.
clear
cd \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\mobility/
use raw_mobility
sort simport dimport
merge m:1 simport dimport using \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\mobility/import_names
rename (dimport simport) (google_districts google_states)
drop if _merge !=3
drop _merge google_districts google_states
save monthly_mobility, replace
*****/
//nightlights

use \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\night_light/monthly_light, clear
gen differencesK2 = light_perK2 - light_perK2_19
sort pc11_state_id pc11_district_id month
order pc11_state_id pc11_district_id month
save monthly_light, replace
cd \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\general
save monthly_all, replace
*****

//merging other datasets
merge 1:1 pc11_district_id month using \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\mobility/unlock_colors, keepusing(strictness)
rename strictness zone_color
drop _merge
save monthly_all, replace

foreach mo in 06 07 {
clear
use \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\mobility/containment_&_quarantine
gen date = date("2020`mo'01'", "YMD")
format date %td
gen month = mofd(date)
format month %tm
keep pc11_state_id month containment_days interstate_quarantine

sort pc11_state_id month
merge 1:m pc11_state_id month using monthly_all
drop if _merge ==1
drop _merge
save monthly_all, replace
}

merge 1:1 pc11_district_id month using \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\mobility/monthly_mobility, keepusing(av_mobility grocery_pharm_av residential_av workplace_av)
drop _merge

merge m:1 pc11_district_id using \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\raw/2011_Dist_1, keepusing(_ID)
drop _merge

merge 1:1 pc11_district_id month using district-wise_cases_deaths, keepusing(rising_cases)
drop if _merge!=3
gen contained_cases =rising_cases*containment_days
drop _merge rising_cases light_perK2 light_perK2_19 light_perCapita_19 containment_days
drop if pc11_district_id==0
duplicates drop
sort pc11_state_id pc11_district_id month
order pc11_state_id pc11_district_id month
save monthly_all, replace
*****/

/*visualize
cd \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\general
use monthly_all, clear

label define months 721"Feb" 722"Mar" 723"Apr" 724"May" 725"Jun" 726"Jul" 727"Aug" 728"Sep" 729"Oct" 730"Nov" 731"Dec"
label values month months
label define colors 1"Green" 2"Orange" 3"Red"
label values zone_color colors

cd \\rschfs1x\userrs\a-e\bp257_RS\Desktop\data\general/visuals
sort pc11_state_id month
by pc11_state_id month: egen mobilityxstate = mean(av_mobility)
xtline mobilityxstate, t(month) i(pc11_state_id ) overlay yline(0, lp(dot) lc(black)) legend(off) ytitle("% Change in Mobility") xtitle("Month") title("State Changes in Mobility 2020") scheme(s1color)
graph export state_mobility.png, replace
graph box av_mobility, over(zone_color) ytitle("% Change in Mobility") title("Changes in Mobility by Lockdown Strickness") scheme(s1color)
graph export mo5_mobility_xzone.png, replace
graph box residential_av, over(zone_color) ytitle("% Increase in Time at Residence") title("Changes in Time at Home by Lockdown Strickness") scheme(s1color)
graph export mo5_residence_xzone.png, replace
graph box workplace_av, over(zone_color) ytitle("% Change in Trips to Work") title("Changes in Workplace Visitation by Lockdown Strickness") scheme(s1color)
graph export mo5_work_xzone.png, replace
graph box av_mobility, over(month) nooutsides ytitle("% Change in Mobility") title("Changes in Mobility by Month") scheme(s1color)
graph export mobility_xmonth.png, replace
graph box workplace_av, over(month) nooutsides ytitle("% Change in Trips to Work") title("Changes in Workplace Visitation by Month") scheme(s1color)
graph export work_xmonth.png, replace
tw (sc av_mobility contained_cases) (lfit av_mobility contained_cases), ytitle("% Change in Mobility") xtitle("Case Count * Minimal Containment Period (Case*Days)") title("Change in Mobility as Containment Increases") scheme(s1color)
graph export mobility_xcasedays.png, replace
*****/
//make a table of regression coefs?
