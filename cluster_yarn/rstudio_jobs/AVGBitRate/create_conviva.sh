rm conviva11.csv
rm conviva12.csv
hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/11.csv | head -n 5000 >> conviva11.csv
hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/12.csv | head -n 5000 >> conviva12.csv
sed -i "s,\",,g" conviva1*.csv
hdfs dfs -copyFromLocal -f conviva11.csv
hdfs dfs -copyFromLocal -f conviva12.csv
# rm conviva-sample.csv
# hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/11.csv | head -n 1250 >> conviva-sample.csv
# hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/11.csv | tail -n 1250 >> conviva-sample.csv
# hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/12.csv | head -n 1251 | tail -n 1250 >> conviva-sample.csv
# hdfs dfs -cat hdfs://bda-ns//data/raw/ott_dazn/conviva_logs/12.csv | tail -n 1250 >> conviva-sample.csv
# sed -i "s,\",,g" conviva-sample.csv
# hdfs dfs -copyFromLocal -f conviva-sample.csv
