import beads.*;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Random;

AudioContext ac;
static Envelope volumeControl;
Random r = new Random();
int sampleNumbers;
int currentLoop = 0;
SamplePlayer[] player;
musicController[] musicList;
final static List<visualObjects> ObjectList = new CopyOnWriteArrayList<visualObjects>();
ControllButton b1  = new ControllButton();
Boolean boolClick = false;
Boolean boolDrag = false;
int LoopLength = 400;
int maxLength = 7000;
int minLength = 6000;
long timeStep = 0;



void setup(){
  size(1000,1000);
  noStroke();
  colorMode(HSB);
  ac = new AudioContext();
  File dir = new File("D:/MFA/MFA");
  player= new SamplePlayer[dir.listFiles().length];
  musicList = new musicController[dir.listFiles().length];
  if(dir.isDirectory()) {
      File[] listOfFiles = dir.listFiles();
     for (int i = 0; i < listOfFiles.length; i++) {
                if (listOfFiles[i].isFile()) {
                      player[i] = new SamplePlayer(ac, SampleManager.sample(listOfFiles[i].getAbsolutePath()));
                      musicList[i] = new musicController(player[i],i);
                }
     }
  }
  sampleNumbers = dir.listFiles().length;
}

void draw(){
     System.out.println(ac.getTimeStep());
    if((ac.getTimeStep()+timeStep)/LoopLength-currentLoop == 1)
    {
        int randA = r.nextInt(sampleNumbers);
        musicList[randA].playMusic();
        currentLoop++;
    }

    clear();
    push();
    b1.iniateButton();
    pop();
    push();
    for(int lineNumber = 0;lineNumber<15;lineNumber++)
    {
      stroke(126);
      line(0,lineNumber*60+60,width,lineNumber*60+60);
    }
    pop();
    for (visualObjects i : ObjectList) {
      push();
      i.move();
      i.update();
      pop();
    }
    //System.out.println(currentLoop);
}
////////////////////////////////////////////////////////////////////////////////////////////////
//for every music sample, I created a music controller object to controll it
////////////////////////////////////////////////////////////////////////////////////////////////
class musicController{
//sampleplayer and index  
  SamplePlayer music;
  int musicIndex;
  
  musicController(SamplePlayer s,int num){
    //once created, it will load the music into the sample player
    music = s;
    musicIndex = num;
    music.setKillOnEnd(false);
  }
  
  void playMusic(){
     music.reset();
     Bead timeDelay = new Bead() {
          @Override
          protected void messageReceived(Bead message) {
            volumeControl = new Envelope(ac,2);
            Gain gain = new Gain(ac, 1,volumeControl);
            
            
            int randB  = r.nextInt(maxLength) % (maxLength - minLength + 1) + minLength;
            gain.addInput(music);
            ObjectList.add(new visualObjects(musicIndex));
            volumeControl.addSegment(0, randB, new KillTrigger(gain));
            ac.out.addInput(gain);
          }
        };
        int randC = r.nextInt(300);
        DelayTrigger delayTrigger = new DelayTrigger(ac, randC, timeDelay);
        ac.out.addDependent(delayTrigger);
  }
  

  //this method is used to change the volumn of sample player.
  void volumnControll(){
    
    
  }
  
}
///////////////////////////////////////////////////////////////////////////
class visualObjects{
  
  private color filledColor;
  float startX = 0;
  float startY ;
  float c,opacity;
  float k =0;
  float endPoint = 4;
  visualObjects(int i){
     int randR = r.nextInt(255);
     startY = i*60+60;
     filledColor = color(randR,255,255);
    }
 
  
  void move(){
    //we need to stop the visualization of this object at one point to reduce the work load
    if(k<endPoint){
      push();
      //the wave showed in the screen is made up of 600 small circles with different opacities
      for(c=0;c<600;c++)
      {
        fill(filledColor,opacity=pow((300-abs(300-c))/300,9)*99);
        circle(k*c,startY,opacity/9);
      }
      pop();
    }
  }
  
  void update(){
    if(boolClick==true)
    k+=0.01;
    else
    k+=0;
  }
  
}


class ControllButton{
  float startX;
  float startY;
  float volumnX;
  float volumnY;
  float len = 30;
  color buttonColor = color(80,255,255);
  ControllButton(){
    startX = 900;
    startY = 900;
  }
  void iniateButton(){
    fill(buttonColor);
    rect(startX,startY,len,len);
  }
  
  void move(float pa,float a){
    startX = startX+a-pa;
    rect(startX,startY,30,30);
  }
  
  void checkPressed(float a, float b){
    
    
  }
  void click(float a, float b){
    if(a>=startX&&a<=(startX+len)&&b>=startY&&b<=(startY+len)){
      if(boolClick==false)
        musicStart();
      else if(boolClick==true)
        musicPause();
    }
  }
  void updateVolumn(float a,float b){
    //boolClick = false;
  }
  void musicPause(){
    ac.stop();
    boolClick = false;
  }
  
  void musicStart(){
    timeStep = ac.getTimeStep()%LoopLength;  
    ac.start();
    boolClick=true;
    currentLoop = 0;
  }
  
}
//this is used to check whether the button is clicked at a specific position
void mousePressed() 
{
  b1.checkPressed(mouseX,mouseY);
}
//event that release the mouse
void mouseReleased(){
  b1.updateVolumn(mouseX,mouseY);
}
void mouseClicked(){
  b1.click(mouseX,mouseY);
}
