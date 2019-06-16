// Bit hack fast appoximate 1/sqr(x)
void setup(){
  background(0);
  size(500,500);
  stroke(255,0,0);  // red
  for(int i=1;i<500;i++){
    point(i,499-499*1f/sqrt(i));
  }
  stroke(0,255,0);  // green
  for(int i=1;i<500;i++){
    float f=i;
    int j=Float.floatToRawIntBits(f);
    j=0x5F375A86 - (j>>>1);
    float invsqrt=Float.intBitsToFloat(j);
    point(i,499-499*invsqrt);
  }
}
