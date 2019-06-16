/**
 * Arctangent Bit Hack Version Improved
 * 
 * Move the mouse to change the direction of the eyes. 
 * The atan2() function computes the angle from each eye 
 * to the cursor. 
 */
 
Eye e1, e2, e3;

void setup() {
  size(640, 360);
  noStroke();
  e1 = new Eye( 250,  16, 120);
  e2 = new Eye( 164, 185,  80);  
  e3 = new Eye( 420, 230, 220);
}

void draw() {
  background(102);
  
  e1.update(mouseX, mouseY);
  e2.update(mouseX, mouseY);
  e3.update(mouseX, mouseY);

  e1.display();
  e2.display();
  e3.display();
}

class Eye {
  int x, y;
  int size;
  float angle = 0.0;
  
  Eye(int tx, int ty, int ts) {
    x = tx;
    y = ty;
    size = ts;
 }

  void update(int mx, int my) {
    angle = arctan2BH(my-y, mx-x);  // Using hack
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    fill(255);
    ellipse(0, 0, size, size);
    rotate(angle);
    fill(153, 204, 0);
    ellipse(size/4, 0, size/2, size/2);
    popMatrix();
  }
}

float arctan2BH(float y, float x){
   float absY=Float.intBitsToFloat(Float.floatToRawIntBits(y) & 0x7fffffff);
   float absX=Float.intBitsToFloat(Float.floatToRawIntBits(x) & 0x7fffffff);
   float angle=min(absX,absY)*Float.intBitsToFloat(0x7EEEEEEE-Float.floatToRawIntBits(max(absX,absY)));
   angle*=Float.intBitsToFloat(0x7EEEEEEE-Float.floatToRawIntBits(1+0.28*angle*angle));
   if(absY>absX) angle=HALF_PI-angle;
   if(x<0) angle=PI-angle;
   if(y<0) angle=-angle;
   return angle;
}
