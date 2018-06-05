ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBMAvgBitRateM17lib/v2.0/h2o-genmodel.jar;
ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBMAvgBitRateM17lib/v2.0/ScoreDataUDFGBMAVGM17-1.0-SNAPSHOT.jar;
CREATE TEMPORARY FUNCTION scoredatavg AS 'ai.h2o.hive.udf.ScoreDataUDFGBMAVGM17';
USE default;
SHOW TABLES;
DROP TABLE IF EXISTS conviva_avgbitrate_pred;
SELECT asset, deviceos, country, state, city, asn, isp, start_time_unix_time,startup_time_ms, playing_time_ms, buffering_time_ms, interrupts, startup_error, sessiontags, ipaddress, cdn, browser, convivasessionid, streamurl, errorlist, percentage_complete, average_bitrate_kbps,
 scoredatavg(asn, start_time_unix_time, startup_time_ms, playing_time_ms, buffering_time_ms, interrupts, startup_error, percentage_complete) 
 as predict_average_bitrate_kbps FROM conviva_avgbitrate LIMIT 20;
