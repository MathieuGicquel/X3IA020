#!/usr/bin/python
from org.apache.pig.scripting import *
import sys

input_file = "gs://public_lddm_data/page_links_en.nt.bz2"
n_iteration = 3
output_folder = "gs://x3ia020-bucket/out"

init_output_folder = output_folder + "/pagerank_data_0"


INIT = Pig.compile("""
A = LOAD '""" + input_file + """' using PigStorage(' ') as (url:chararray, p:chararray, link:chararray);
B = GROUP A by url;                                                                                  
C = foreach B generate group as url, 1 as pagerank, A.link as links;                                 
STORE C into '"""+  init_output_folder + """';
""")

UPDATE = Pig.compile("""
-- PR(A) = (1-d) + d (PR(T1)/C(T1) + ... + PR(Tn)/C(Tn))
previous_pagerank = 
    LOAD '$docs_in' 
    USING PigStorage('\t') 
    AS ( url: chararray, pagerank: float, links:{ link: ( url: chararray ) } );
outbound_pagerank =  
    FOREACH previous_pagerank 
    GENERATE 
        pagerank / COUNT ( links ) AS pagerank, 
        FLATTEN ( links ) AS to_url;
new_pagerank = 
    FOREACH 
        ( COGROUP outbound_pagerank BY to_url, previous_pagerank BY url INNER )
    GENERATE 
        group AS url, 
        ( 1 - $d ) + $d * SUM ( outbound_pagerank.pagerank ) AS pagerank, 
        FLATTEN ( previous_pagerank.links ) AS links;
        
STORE new_pagerank 
    INTO '$docs_out' 
    USING PigStorage('\t');
""")

params = { 'd': '0.85', 'docs_in': input_file}

stats = INIT.bind(params).runSingle()
if not stats.isSuccessful():
      raise 'failed initialization'

for i in range(n_iteration):
   out = output_folder + "/pagerank_data_" + str(i + 1)
   print("out =", out)
   params["docs_out"] = out
   Pig.fs("rmr " + out)
   stats = UPDATE.bind(params).runSingle()
   if not stats.isSuccessful():
      raise 'failed'
   params["docs_in"] = out
   

