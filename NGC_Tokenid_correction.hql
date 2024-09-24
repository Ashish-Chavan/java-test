use HAASBAP0097_05545;
set mapred.job.queue.name=NONP.HAASBAP0097_05545;

drop table NAD_ONLINE_GOLD_CREATE_TMP_2024052219;

create external table NAD_ONLINE_GOLD_CREATE_TMP_2024052308(tokenid string,requesterurl string,createtype string,bronzekey string,parentkey string,uprn string,usrn string,organisationname string,saostartnumber string,saostartsuffix string,saoendnumber string,saoendsuffix string,saotext string,paostartnumber string,paostartsuffix string,paoendnumber string,paoendsuffix string,paotext string,streetdescriptor string,localityname string,townname string,postcode string,easting string,northing string,latitude string,longitude string,w3w string,districtcode string,exchangecode string,siteclassificationcode string,code_1141 string,streettypecode string,logicalstatuscode string,rpc string,nad_key string,status string,create_timestamp string,modify_timestamp string,lpi_summary_organisation string,lpi_summary_subpremisesname string,lpi_summary_subpremisesnumber string,lpi_summary_premisesname string,lpi_summary_premisesnumber string,lpi_summary_thoroughfare string,lpi_summary_locality string,lpi_summary_town string,lpi_summary_postcode string,csssubpremises string,csspremisesname string,cssthoroughfareno string,cssthoroughfarename string,csslocality string,cssposttown string,csscounty string,csspostcode string,or_friendly_organisation string,or_friendly_subpremise string,or_friendly_buildingname string,or_friendly_thoroughfarenumber string,or_friendly_thoroughfarename string,or_friendly_locality string,or_friendly_posttown string,or_friendly_postcode string,or_friendly_postincode string,or_friendly_postoutcode string,or_friendly_county string,or_friendly_dependentthoroughfarename string,or_friendly_doubledependentlocality string,or_friendly_pobox string,paf_organisation string,paf_subpremise string,paf_buildingname string,paf_thoroughfarenumber string,paf_thoroughfarename string,paf_locality string,paf_posttown string,paf_postcode string,paf_postincode string,paf_postoutcode string,paf_county string,paf_dependentthoroughfarename string,paf_doubledependentlocality string,paf_pobox string,network string,location string,access_g string,copper string,p2pfibre string,fttp_greenfield string,fttp_brownfield string,copper_restriction string,p2pfibre_restriction string,fttp_greenfield_restriction string,fttp_brownfield_restriction string,multi_classification_flag string,postal_flag string,source string,address_structure string,address_status string,fail_level string,address_quality string,best_address_line1 string,best_address_line2 string,best_address_line3 string,best_address_line4 string,new_key string)
row format delimited
fields terminated by ','
location '/user/HAASBAP0097_05545/nad/or_nad/NGC_Tokenid_correction/NAD_ONLINE_GOLD_CREATE_TMP_2024052308';

select count(distinct tokenid) from NAD_ONLINE_GOLD_CREATE_TMP_2024052308; -- distinct tokens 7230
select count(distinct tokenid) from NAD_ONLINE_GOLD_CREATE_TMP_2024052308 where createtype != 'UPRN'; -- distinct tokens 349

drop table ngc_analysed_2024052219;-- 357
create table ngc_analysed_2024052308 as 
select A.*, B.*,if(C.nad_key is not null, 'Y', 'N') as in_baabp
from
(select tokenid, concat_ws(',',collect_set(nad_key)) as new_key, collect_list(status)  as status, concat_ws(',',collect_set(createtype)) as createtype, count(*) as cnt
from NAD_ONLINE_GOLD_CREATE_TMP_2024052308
where createtype != 'UPRN'
group by tokenid) A
left outer join 
(select cir_key, tr_sub_premise_key 
from sna_repository_ext 
where cir_type='NGC')B
on A.tokenid = B.cir_key
left outer join
baabp_unique_addr_new C
on (B.tr_sub_premise_key=C.nad_key); 



drop table ngc_uprn_analysed_2024052219; --6932
create table ngc_uprn_analysed_2024052308 as
select A.*, B.*,if(C.nad_key is not null, 'Y', 'N') as in_baabp,D.nad_key as baabp_key
from
(select tokenid, concat_ws(',',collect_set(nad_key)) as new_key, max(uprn) as uprn, collect_list(status)  as status, concat_ws(',',collect_set(createtype)) as createtype, count(*) as cnt
from NAD_ONLINE_GOLD_CREATE_TMP_2024052308
where createtype = 'UPRN'
group by tokenid) A
left outer join 
(select cir_key, tr_sub_premise_key 
from sna_repository_ext 
where cir_type='NGC')B
on A.tokenid = B.cir_key
left outer join
baabp_unique_addr_new C
on (B.tr_sub_premise_key=C.nad_key)
left outer join
baabp_unique_addr_new D
on (A.uprn=D.uprn);
