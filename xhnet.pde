// Code in Processing www.processing.org
final int EDGE=32;    // image edge size
final int DENSITY=2;  // neural network density
final int DEPTH=5;    // neural network depth
final int MUTATIONS=25;   // number of items to mutate during optimization
final float PRECISION=25f;// mutation strength  
final int THREADS=4;      // number of training threads
final int VECLEN=EDGE*EDGE*4;
volatile boolean shouldRun;  // All threads see this in a correct mutual way.
boolean teach;
float[] work=new float[VECLEN];
float[][] imgVectors;
java.util.Vector<Thread> threadList=new java.util.Vector<Thread>(); // active threads
XHNet10 parent=new XHNet10(VECLEN, DENSITY, DEPTH);  // neural network
float parentCost=Float.POSITIVE_INFINITY;

void setup() {
  size(300, 300);
  frameRate(3);
  File[] list=listFiles("data/");
  imgVectors=new float[list.length][VECLEN];
  float rsc=1f/127.5f;
  for (int i=0; i<list.length; i++) {
    PImage img=loadImage(list[i].toString());
    int pos=0;
    for (int y=0; y<EDGE; y++) {
      for (int x=0; x<EDGE; x++) {
        int c=img.get(x, y);
        float r=rsc*((c & 255)-127.5f);
        float g=rsc*(((c>>8) & 255)-127.5f);
        float b=rsc*(((c>>16) & 255)-127.5f);
        float av=0.3333333f*(r+g+b);
        imgVectors[i][pos++]=r;
        imgVectors[i][pos++]=g;
        imgVectors[i][pos++]=b;
        imgVectors[i][pos++]=av;
      }
    }
  }
}  

void displayVector(float[] vec) {
  int pos=0;
  for (int y=0; y<EDGE; y++) {
    for (int x=0; x<EDGE; x++) {
      int r=constrain(round(vec[pos++]*127.5f+127.5f), 0, 255);
      int g=constrain(round(vec[pos++]*127.5f+127.5f), 0, 255);
      int b=constrain(round(vec[pos++]*127.5f+127.5f), 0, 255);
      pos++;
      int c=r | (g<<8) | (b<<16) | 0xff000000;
      for (int i=0; i<8; i++) {
        for (int j=0; j<8; j++) {
          set(j+x*8+22, i+y*8+44, c);
        }
      }
    }
  }
}  

synchronized void updateParent(XHNet10 child, float childCost) {
  if (childCost<parentCost) {
    parentCost=childCost;  // should really wrap with synchronize, because another thread looks at it
    arrayCopy(child.weights, parent.weights);// but no real harm can happen
  } else {
    arrayCopy(parent.weights, child.weights);
  }
  for (int i=0; i<MUTATIONS; i++) {
    int r=int(random(child.weights.length));
    float v=child.weights[r];
    float m=2f*exp(-random(PRECISION));
    if (random(-1f, 1f)<0f) m=-m;
    m+=v;
    if (m<-1f) m=v;
    if (m>1f) m=v;
    child.weights[r]=m;
  }
}  

void threadTrain() {
  threadList.addElement(Thread.currentThread());
  XHNet10 child=new XHNet10(VECLEN, DENSITY, DEPTH);
  float[] res=new float[VECLEN];
  while (shouldRun) {
    float childCost=0f;
    for (int i=0; i<imgVectors.length; i++) {
      child.recall(res, imgVectors[i]);
      for (int j=0; j<VECLEN; j++) {
        float d=res[j]-imgVectors[i][j];
        childCost+=d*d;
      }
    }
    updateParent(child, childCost);
  }
}  

void threadRecall() {
  threadList.addElement(Thread.currentThread());
  int count=0;
  while (shouldRun) {
    parent.recall(work, imgVectors[count++]);
    if (count==imgVectors.length) count=0;
    try { 
      Thread.sleep(2000);
    }
    catch(Exception rte) {
    }
  }
}  

void threadNoise() {
  threadList.addElement(Thread.currentThread());
  while (shouldRun) {
    for (int i=0; i<VECLEN; i++) {
      work[i]=random(-1f, 1f);
    }
    parent.recall(work, work);
    try { 
      Thread.sleep(2000);
    }
    catch(Exception rne) {
    }
  }
}  

void keyPressed() {
  if ((key=='s' || key=='S') && shouldRun) {
    shouldRun=false;
    teach=false;
    try {
      for (Thread t : threadList) t.join();
    }
    catch(Exception te) {
    }
    threadList.clear();
  }  
  if ((key=='t' || key=='T') && !shouldRun) {
    shouldRun=true;
    teach=true;
    for (int i=0; i<THREADS; i++) thread("threadTrain");
  } 
  if ((key=='r' || key=='R') && !shouldRun) {
    shouldRun=true;
    thread("threadRecall");
  } 
  if ((key=='n' || key=='N') && !shouldRun) {
    shouldRun=true;
    thread("threadNoise");
  }
}

void draw() {
  background(0);
  text("Train 'T',  Recall 'R',  Recall Noise 'N', Stop 'S'", 2, 20);
  text("Cost: "+parentCost, 2, 40);
  if (shouldRun && !teach) displayVector(work);
}

class XHNet10 {
  int vecLen;
  int density;
  int depth;
  float layerScale;
  float[] weights;
  float[] workA;
  float[] workB;

  // vecLen must be an int power of 2 (2,4,8,16,32,64...)
  XHNet10(int vecLen, int density, int depth) {
    this.vecLen=vecLen;
    this.density=density;
    this.depth=depth;
    layerScale=2f/sqrt(vecLen*density);
    weights=new float[3*vecLen*density*depth];
    workA=new float[vecLen];
    workB=new float[vecLen];  
    for (int i=0; i<weights.length; i++) {
      weights[i]=random(-1f, 1f);
    }
  }

  void recall(float[] result, float[] input) {
    adjust(workA, input, layerScale/vecLen);  //Normalize
    signFlip(workA, 123456);  // Hash based random sign flip
    whtRaw(workA);           // +WHT = Random Projection
    int wtIndex=0;
    int i=0;       // depth counter
    while (true) { // depth loop
      zero(result);
      for (int j=0; j<density; j++) {  // density loop

        for (int k=0; k<vecLen; k++) {     // premultiply by weights
          workB[k]=workA[k]*weights[wtIndex++];
        }  
        whtRaw(workB); // premultiply + Walsh Hadamard transform = Spinner projection
        for (int k=0; k<vecLen; k++) { // switch slope at zero activation function
          if (workB[k]<0f) {                          
            result[k]+=workB[k]*weights[wtIndex];    // Slope A
          } else {
            result[k]+=workB[k]*weights[wtIndex+1];  // Or Slope B
          }  
          wtIndex+=2;
        }
      }  // density loop end
      i++;
      if (i==depth) break;  // depth loop end
      scale(workA, result, layerScale);
    }  // depth loop continue
    signFlip(result, 654321);
    whtRaw(result); // Final random projection helps if density is low
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

  // recomputable random sign flip of the elements of vec 
  void signFlip(float[] vec, int h) {
    for (int i=0; i<vec.length; i++) {
      h*=0x9E3779B9;
      h+=0x6A09E667;
      // Faster than -  if(h<0) vec[i]=-vec[i];
      vec[i]=Float.intBitsToFloat((h&0x80000000)^Float.floatToRawIntBits(vec[i]));
    }
  }

  void adjust(float[] x, float[] y, float scale) {
    float sum = 0f;
    int n=x.length;
    for (int i = 0; i < n; i++) {
      sum += y[i] * y[i];
    }
    float adj = scale/ (float) Math.sqrt((sum/n) + 1e-20f);
    scale(x, y, adj);
  }  

  void scale(float[] res, float[] x, float scale) {
    for (int i=0, n=res.length; i<n; i++) {
      res[i]=x[i]*scale;
    }
  }

  void zero(float[] x) {
    for (int i=0, n=x.length; i<n; i++) x[i]=0f;
  }
}  
