import javax.swing.*;
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
     costLb=new JLabel("Hi");
     costLb.setBounds(55,303,200,30);
     f.add(costLb);   
     buffer=new BufferedImage(256,256,BufferedImage.TYPE_INT_RGB);
     JLabel imgLb=new JLabel(new ImageIcon(buffer));
     imgLb.setBounds(5,5,256,256);
     f.add(imgLb);
     f.setVisible(true);
  }  
 
}  