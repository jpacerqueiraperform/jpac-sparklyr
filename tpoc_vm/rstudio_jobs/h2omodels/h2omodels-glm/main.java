import java.io.*;
import hex.genmodel.easy.RowData;
import hex.genmodel.MojoModel;
import hex.genmodel.algos.glm.*; 
import hex.genmodel.easy.RowData;
import hex.genmodel.easy.EasyPredictModelWrapper;
import hex.genmodel.easy.prediction.*;

//GlmMultinomialMojoModel

public class main {
  public static void main(String[] args) throws Exception {
    EasyPredictModelWrapper model = new EasyPredictModelWrapper(GlmMojoModel.load("GLM_model_Oracle_1503482486923_1.zip"));

    RowData row1 = new RowData();
    row1.put("cyl", "6");
    row1.put("wt", "2.862");

    RegressionModelPrediction p1 = model.predictRegression(row1);

    System.out.println(" - ");
    System.out.println("This Wizard software, has predicted that  a car with  cyl=6,wt=2.862 does mpg=" + p1.value);
    
    System.out.println(" - ");

    RowData row2 = new RowData();
    row2.put("cyl", "8");
    row2.put("wt", "3.165");

    RegressionModelPrediction p2 = model.predictRegression(row2);

    System.out.println(" - ");
    System.out.println("This Wizard software, has predicted that  a car with  cyl=8,wt=3.165 does mpg=" + p2.value);
    
    System.out.println(" - ");
  }
}
