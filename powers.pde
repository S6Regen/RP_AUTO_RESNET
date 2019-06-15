// Bit hack fast appoximate square root 
void setup(){
  background(0);
  size(500,500);
  stroke(255,0,0);  // red
  for(int i=0;i<500;i++){
    point(i,499-22*sqrt(i));
  }
  stroke(0,255,0);  // green
  for(int i=0;i<500;i++){
    float f=i;
    int j=Float.floatToRawIntBits(f);
    j=(j+(127<<23))>>>1;  // basically average the biased exponent with 127
    float root=Float.intBitsToFloat(j);
    point(i,499-22*root);
  }
  
  
    
  
}
