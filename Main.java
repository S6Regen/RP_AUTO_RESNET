import javax.swing.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;

public class Main {

  static BufferedImage buffer;
  static JButton trainBtn;
  static JButton recallBtn;
  static JLabel costLb;
  
  public static void main(String[] args){    
    
     JFrame f=new JFrame("RP Neural");
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
     JLabel imgLb=new JLabel(new ImageIcon(buffer));
     imgLb.setBounds(5,5,256,256);
     f.add(imgLb);
     f.setVisible(true);
     ActionListener aL=new ActionListener() {
       public void actionPerformed(ActionEvent e) {
        System.out.println(e);
       }
     };
     trainBtn.addActionListener(aL);
     recallBtn.addActionListener(aL);
  }  
  
  class RPN {
    
    RPN(int vecLen,int density,int depth){
    
    }
    
    recall(float[] result,float[] input){
     
    }
    
  }  
 
  static void wht(float[] vec) {
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
    float sc = 1f / (float) Math.sqrt(n);
    for (i = 0; i < n; i++) {
      vec[i] *= sc;
    }
  }

  static void signFlip(float[] vec, long h) {
    h = h * 2862933555777941757L + 3037000493L;
    for (int i = 0; i < vec.length; i++) {
      h = h * 2862933555777941757L + 3037000493L;
      int x = (int) (h >>> 32) & 0x80000000;  // select sign flag bit
      vec[i] = Float.intBitsToFloat(x ^ Float.floatToRawIntBits(vec[i]));  // xor top bit
    }
  }

  //  Fast random projection.  
  static void fastRP(float[] vec, long h) {
    signFlip(vec, h);
    wht(vec);
  }
  
  
}  