#!/usr/bin/env bash
scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v3-udf-pojo/h2o-genmodel.jar .
scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v3-udf-pojo/gbm_grid1_model_17.java .
mv  gbm_grid1_model_17.java GBMModel17.loc.java
sed "s,gbm_grid1_model_17,GBMModel17,g"  GBMModel17.loc.java > GBMModel17.loc2.java
# 
# sed -i -e "1i\package ai.h2o.hive.udf; " GBMModel17.loc2.java > GBMModel17.java
# sed "s,import,package ai.h2o.hive.udf; import,1" GBMModel17.loc2.java > GBMModel17.java
#
cp GBMModel17.java ../src/main/java/ai/h2o/hive/udf/GBMModel17.java
rm GBMModel17.loc.java
