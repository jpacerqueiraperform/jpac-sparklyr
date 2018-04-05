rf -rf *.class
echo "Compile"
javac -cp h2o-genmodel.jar -J-Xms2g -J-XX:MaxPermSize=128m GLM_model_Oracle_1503482486923_1.java main.java
echo "Run Sample"
java -cp .:h2o-genmodel.jar main
