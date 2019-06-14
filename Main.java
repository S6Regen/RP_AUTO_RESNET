import javax.swing.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.io.*;
// Remind me never to use Java again, it's boilerplate code hell.
public class Main {

  static BufferedImage buffer;
  static JButton trainBtn;
  static JButton recallBtn;
  static JLabel costLb;
  static JLabel imgLb;
  static Thread t;
  static float parentCost=Float.POSITIVE_INFINITY;
  static RPN parent=new RPN(4096,3,5);
  static RPN child=new RPN(4096,3,5);
  static int count;
  static float[][] img;
  static float[] work=new float[4096];
  
  public static void main(String[] args){   
     DataInputStream dis=new DataInputStream(Main.class.getResourceAsStream("imgdata.dat")); // load image data
     try{
       count=Integer.reverseBytes(dis.readInt());  //ugg
       img=new float[count][4096];
       for(int i=0;i<count;i++){
         for(int j=0;j<4096;j++){
           img[i][j]=Float.intBitsToFloat(Integer.reverseBytes(dis.readInt()));  
         } 
       }     
       dis.close();
     }catch(Exception e){
       System.out.println("Can't read imgdata.dat file. It should be in the same folder as Main.class");
     }   
     JFrame f=new JFrame("RP Neural");  // Set up gui
     f.setLayout(null);
     f.setBounds(100,100,273,355);    
     trainBtn=new JButton("Train");
     trainBtn.setBounds(5,271,100,30);
     f.add(trainBtn);
     recallBtn=new JButton("Recall");
     recallBtn.setBounds(156,271,100,30);
     f.add(recallBtn);
     JLabel costTxt=new JLabel("Cost:");
     costTxt.setBounds(5,303,50,30);
     f.add(costTxt);
     costLb=new JLabel("___");
     costLb.setBounds(55,303,200,30);
     f.add(costLb);   
     buffer=new BufferedImage(256,256,BufferedImage.TYPE_INT_RGB);
     imgLb=new JLabel(new ImageIcon(buffer));
     imgLb.setBounds(5,5,256,256);
     f.add(imgLb);
     f.setVisible(true);
     ActionListener aL=new ActionListener() {
       public void actionPerformed(ActionEvent e) {
         if(e.getSource()==trainBtn){
           if(t==null){
             t=new Thread(){
               public void run(){
                 while(!Thread.interrupted()){
                   int n=parent.weights.length;
                   System.arraycopy(parent.weights,0,child.weights,0,n); //copy parent to child
                   for(int i=0;i<25;i++){  // do some mutations
                      int r=(int)(n*Math.random());  // random location in weights to mutate.
                      float m=(float)Math.exp(-20*Math.random()); // mutation
                      if(Math.random()<0.5) m=-m;    //  random sign flip
                      float v=child.weights[r]+m;
                      if((v>1f) || (v<-1f)) continue;  // if out of bounds leave unchanged
                      child.weights[r]=v;
                   }   // end child mutations
                   float childCost=0f;
                   for(int i=0;i<count;i++){  // find the cost of the child
                     child.recall(work,img[i]);
                     for(int j=0;j<work.length;j++){
                       float e=work[j]-img[i][j];
                       childCost+=e*e;
                     }    
                   }  
                   if(childCost<parentCost){ //child is better than parent
                     System.arraycopy(child.weights,0,parent.weights,0,n);
                     synchronized(Main.class){
                       parentCost=childCost;     
                     }
                   }  
                 }
               }
             };
             recallBtn.setEnabled(false);
             trainBtn.setText("Stop Training");
             t.start();
           }else{
             t.interrupt();
             try{
             t.join();
             }catch(Exception f){};
             t=null;
             recallBtn.setEnabled(true);
             trainBtn.setText("Train");
           }  
         }else{ // else it must be the recall button
           if(t==null){
              t=new Thread(){
               public void run(){
                 int ct=0;
                 while(!Thread.interrupted()){
                   parent.recall(work,img[ct++]);
                   if(ct>=count) ct=0;
                   try{
                     Thread.sleep(2000);
                   }catch(Exception re){
                     break;
                   }  
                 }
               }
              };
              trainBtn.setEnabled(false);
              recallBtn.setText("Stop Recall");
              t.start();       
           }else{
             t.interrupt();
             try{
               t.join();
             }catch(Exception f){};
             t=null;
             trainBtn.setEnabled(true);
             recallBtn.setText("Recall");
           }   
         }  
       }
     };
     trainBtn.addActionListener(aL);
     recallBtn.addActionListener(aL);
     Timer time=new Timer(400,new ActionListener(){
       public void actionPerformed(ActionEvent e) {
         synchronized(Main.class){
           costLb.setText(Float.toString(parentCost)); 
         }
         int idx=0;
         for(int i=0;i<256;i+=8){
           for(int j=0;j<256;j+=8){
             int r=Math.max(Math.min(Math.round(127.5f*work[idx++]+127.5f),255),0);
             int g=Math.max(Math.min(Math.round(127.5f*work[idx++]+127.5f),255),0);
             int b=Math.max(Math.min(Math.round(127.5f*work[idx++]+127.5f),255),0);
             idx++;
             int clr=b|(g<<8)|(r<<16);
             for(int x=j;x<j+8;x++){
               for(int y=i;y<i+8;y++){
                 buffer.setRGB(x,y,clr);
               }
             }  
           }
         }  
         imgLb.repaint();
       }  
     });
     time.start();
  }  
  
 static class RPN {
     int vecLen;
     int density;
     int depth;
     float sc;
     float[] weights;
     float[] workA;
     float[] workB;
    
    RPN(int vecLen,int density,int depth){
       this.vecLen=vecLen;
       this.density=density;
       this.depth=depth;
       sc=1f/(float)Math.sqrt(vecLen);
       weights=new float[3*vecLen*density*depth];
       workA=new float[vecLen];
       workB=new float[vecLen];  
       for(int i=0;i<weights.length;i++){
         weights[i]=2f*(float)Math.random()-1f;
       }
    }
    
    void recall(float[] result,float[] input){
      adjust(workA,input,sc);  //Normalize
      int wtIndex=0;
      int i=0;     // depth counter
      while(true){ // depth loop
        zero(result);
        for(int j=0;j<density;j++){  // density loop
          for(int k=0;k<vecLen;k++){     // multiply by weights
            workB[k]=workA[k]*weights[wtIndex++]; 
          }  
          whtRaw(workB); // Weight premultiply + Walsh Hadamard transform = Spinner projection
          for(int k=0;k<vecLen;k++){ // zero switched slope activation function
            if(workB[k]<0f){                           // switch slope at zero according to sign
              result[k]+=workB[k]*weights[wtIndex];    // Slope A
            }else{
              result[k]+=workB[k]*weights[wtIndex+1];  // Or Slope B
            }  
            wtIndex+=2;
          }
        }  // density loop end
        i++;
        if(i==depth) break;  // depth loop end
        adjust(workA,result,sc);  // Normalize
      }  // depth loop continue   
    }
    
// Fast Walsh Hadamard transform with no scaling    
    void whtRaw(float[] vec) {
      int i, j, hs = 1, n = vec.length;
      while (hs < n) {
        i = 0;
        while (i < n) {
          j = i + hs;
          while (i < j) {
            float a = vec[i];
            float b = vec[i + hs];
            vec[i] = a + b;
            vec[i + hs] = a - b;
            i += 1;
          }
          i += hs;
        }
        hs += hs;
      } 
    }
    
    void adjust(float[] x,float[] y,float scale){
      float sum = 0f;
      int n=x.length;
      for (int i = 0; i < n; i++) {
        sum += y[i] * y[i];
      }
      float adj = scale/ (float) Math.sqrt((sum/n) + 1e-20f);
      for(int i=0;i<n;i++){
        x[i]=y[i]*adj;
      }
    }  
     
    void zero(float[] x){
      for(int i=0,n=x.length;i<n;i++) x[i]=0f;
    }
    
  }  
}