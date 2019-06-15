// Bit hack fast appoximate 1/x
void setup(){
  background(0);
  size(500,500);
  stroke(255,0,0);  // red
  for(int i=1;i<500;i++){
    point(i,499-499*1f/i);
  }
  stroke(0,255,0);  // green
  for(int i=1;i<500;i++){
    float f=i;
    int j=Float.floatToRawIntBits(f);
//    j=0x7f000000-j;  More accurate for x=1 (eg. 1/1 should=1
    j=0x7EEEEEEE-j;  
    float inv=Float.intBitsToFloat(j);
    point(i,499-499*inv);
  }
}
