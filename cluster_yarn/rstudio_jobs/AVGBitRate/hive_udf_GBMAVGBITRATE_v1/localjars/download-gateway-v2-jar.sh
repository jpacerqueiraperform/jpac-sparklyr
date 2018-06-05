#!/usr/bin/env bash
scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v2-avg-bitrate/h2o-genmodel.jar .
scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v2-avg-bitrate/gbm_grid1_model_17.java .
mv  gbm_grid1_model_17.java GBMAvgBitRateMo17.loc1.java
sed "s,gbm_grid1_model_17,GBMAvgBitRateMo17,g"  GBMAvgBitRateMo17.loc1.java > GBMAvgBitRateMo17.loc2.java
# 
sed "s,import,package ai.h2o.hive.udf; import,1" GBMAvgBitRateMo17.loc2.java > GBMAvgBitRateMo17.java
#
cp GBMAvgBitRateMo17.java ../src/main/java/ai/h2o/hive/udf/GBMAvgBitRateMo17.java
rm GBMAvgBitRateMo17.loc*.java 
