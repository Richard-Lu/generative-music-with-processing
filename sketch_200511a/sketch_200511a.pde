import beads.*;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Random;
import java.util.HashSet;
import javafx.stage.FileChooser;
import javafx.stage.Stage;
//audio context
AudioContext ac;

FFT fft ;
PowerSpectrum ps;
ShortFrameSegmenter sfs;
Random r = new Random();
int sampleNumbers;
int currentLoop = 0;
SamplePlayer[] player;
SamplePlayer[] tester;
musicController[] musicList;
LoadButton lb = new LoadButton();
final static List<visualObjects> ObjectList = new CopyOnWriteArrayList<visualObjects>();
ControllButton b1  = new ControllButton();
Boolean boolClick = false;
Boolean boolDrag = false;
int maxLoopLength = 500;
int minLoopLength = 400;
int LoopLength;
int maxLength = 7000;
int minLength = 6000;
int margin;
int previous;
long timeStep = 0;
float vol = 1.0;
File[] listOfFiles;
PImage lensBubble;
Bubble[] bubbles;
ArrayList<Integer> list = new ArrayList<Integer>();
Boolean testPhrase = false;
testButton tb = new testButton();
boolean[] selectedMusic;
void setup(){
  size(1000,1000);
  noStroke();
  colorMode(HSB);
  ac = new AudioContext();
  
  lensBubble = loadImage("bubble.png");
  //music database
  File dir = new File(sketchPath("")+"/data/MFA");
  
  //set up an array of samplePlayer and samplePlayer controller
  player= new SamplePlayer[dir.listFiles().length];
  
  musicList = new musicController[dir.listFiles().length];
  LoopLength  = r.nextInt(maxLoopLength) % (maxLoopLength - minLoopLength + 1) + minLoopLength;
  //read in the music samples and set up sample controller
  if(dir.isDirectory()) {
    sampleNumbers = dir.listFiles().length;
    selectedMusic = new boolean[sampleNumbers];
    bubbles = new Bubble[sampleNumbers];
    margin = (height-150)/sampleNumbers;
      listOfFiles = dir.listFiles();
     for (int i = 0; i < listOfFiles.length; i++) {
                if (listOfFiles[i].isFile()) {
                      player[i] = new SamplePlayer(ac, SampleManager.sample(listOfFiles[i].getAbsolutePath()));
                      
                      //GranularSamplePlayer gsp = new GranularSamplePlayer(ac,SampleManager.sample(listOfFiles[i].getAbsolutePath()));
                      selectedMusic[i] = true;
                      musicList[i] = new musicController(player[i],i);
                      
                }
     }
  }
  //the number of samples in the music database
  
  sfs = new ShortFrameSegmenter(ac);
  sfs.addInput(ac.out);
  FFT fft = new FFT();
  sfs.addListener(fft);
  ps = new PowerSpectrum();
  fft.addListener(ps);
  ac.out.addDependent(sfs);
}

void draw(){
      System.out.println( ac.getTimeStep());
      //System.out.println(musicList[4].getVolume());
     
     
     //play a new piece of music each iteration 
    if((ac.getTimeStep()+timeStep)/LoopLength-currentLoop == 1)
    {
        int randA = r.nextInt(sampleNumbers);
        if(noMusicSelected()==false){
          while(musicList[randA].checkSelected()==false){
            randA = r.nextInt(sampleNumbers);
          }
          musicList[previous].isPlaying = false;
          musicList[randA].playMusic();
          currentLoop++;
        }
        else{
          currentLoop++;
        }
    }
    
    clear();
    
    //draw three buttons
    push();
    b1.drawButton();
    tb.drawButton();
    lb.drawButton();
    pop();
    
    //draw lines, the number of lines is based on the number of music samples
    push();
    for(int lineNumber = 0;lineNumber<sampleNumbers;lineNumber++)
    {
      stroke(126);
      if(musicList[lineNumber].checkSelected()==true)
      {
        line(0,lineNumber*margin+margin,width,lineNumber*margin+margin);
        musicList[lineNumber].b.collide();
        if(musicList[lineNumber].b.isBreak==true)
          musicList[lineNumber].b.recreateBubble();
        else
          musicList[lineNumber].b.move();
        musicList[lineNumber].b.show();
      }
      musicList[lineNumber].drawButton();
      

    }
    pop();
    
    //draw object that created by music controller
    for (visualObjects i : ObjectList) {
      push();
      i.move();
      i.update();
      pop();
    }
    //System.out.println(currentLoop);
}
////////////////////////////////////////////////////////////////////////////////////////////////
//check whether there is no music selected
///////////////////////////////////////////////////////////////////////////////////////////////
boolean noMusicSelected(){
  for(int i = 0;i<selectedMusic.length;i++){
     if(selectedMusic[i]==true)
       return false;
  }
  return true;
  
}
////////////////////////////////////////////////////////////////////////////////////////////////
//for every music sample, I created a music controller object to controll it
////////////////////////////////////////////////////////////////////////////////////////////////
class musicController{
//sampleplayer and index  
  SamplePlayer music;
  
  int musicIndex;
  Glide volume = new Glide(ac,vol);
  Gain gain = new Gain(ac, 1,volume);
  Boolean selected;
  Boolean isPlaying = false;
  float buttonX;
  float buttonY;
  Bubble b;
  //initialize the music controller
  musicController(SamplePlayer s1,int num){
    //once created, it will load the music into the sample player
    music = s1;
    
    musicIndex = num;
    
    music.setKillOnEnd(false);
    
    buttonY = musicIndex*margin+margin+10;
    buttonX = 50;
    selected = selectedMusic[musicIndex];
    b = new Bubble(musicIndex);
    bubbles[musicIndex] = b;
    music.setEndListener(new Bead() {
      public void messageReceived(Bead message) {
        isPlaying = false;
      }
    });
  }
  
  //add a new event to audio context
  void playMusic(){
    previous = musicIndex;
    isPlaying = true;
     music.reset();
     ac.out.removeAllConnections(this.gain);
     Bead timeDelay = new Bead() {
          @Override
          protected void messageReceived(Bead message) {
             volume = new Glide(ac,vol);
             gain = new Gain(ac, 1,volume);
             gain.addInput(music);
             ObjectList.add(new visualObjects(musicIndex));
             ac.out.addInput(gain);
          }
      };
      int randC = r.nextInt(300);
      DelayTrigger delayTrigger = new DelayTrigger(ac, randC, timeDelay);
      ac.out.addDependent(delayTrigger);    
        
  }
  

  //this method is used to change the volumn of sample player.
  void volumeControl(float a){
    volume.setValue(a);
  }
  
  
  
  void drawButton(){
    rect(buttonX,buttonY,20,20);
      if(selected==true){
        push();
        stroke(0);
        strokeWeight(2);
        line(buttonX,buttonY+10,buttonX+10,buttonY+20);
        line(buttonX+10,buttonY+20,buttonX+20,buttonY);
        pop();
      }
  }
  void checkClicked(float inputX,float inputY){
    if(inputX>buttonX&&inputX<buttonX+20&&inputY>buttonY&&inputY<buttonY+20){
      selected = (selected==false);
      selectedMusic[musicIndex]=selected;
    }
    else
      b.breakBubble();
  }
  
  boolean checkSelected(){
    return selected;
  }
  
  void testMusic(){
    
    previous = musicIndex;
    isPlaying = true;
     music.reset();
     ac.out.removeAllConnections(this.gain);
     Bead timeDelay = new Bead() {
          @Override
          protected void messageReceived(Bead message) {
             volume = new Glide(ac,vol);
             gain = new Gain(ac, 1,volume);
             gain.addInput(music);
             ObjectList.add(new visualObjects(musicIndex));
             ac.out.addInput(gain);
          }
      };
      int randC = r.nextInt(300);
      DelayTrigger delayTrigger = new DelayTrigger(ac, randC, timeDelay);
      ac.out.addDependent(delayTrigger);  
    
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
  int e = 3;
  
  int randR;
  int musicIndex;
  float volume;
  visualObjects(int i){
      randR= r.nextInt(255);
     startY = i*margin+margin;
     musicIndex = i;
    }
 
  
  void move(){
    //we need to stop the visualization of this object at one point to reduce the work load
    if(k<endPoint){
      push();
      
      filledColor = color(randR,255,255);
      //the wave showed in the screen is made up of 600 small circles with different opacities
      for(c=0;c<600;c++)
      {
        fill(filledColor,opacity=pow((300-abs(300-c))/300,9)*99);
        circle(k*c,startY+10*sin(k*c*PI/50),100/9);
      }
     e = e*-1;
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
/////////////////////////////////////////////////////////////////////
class Bubble{
  float positionX;
  float positionY;
  float initd  = margin*2;
  float d = initd;
  float friction = 0.7;
  float elas = 0.05;
  float velocityX = r.nextFloat();
  float velocityY = r.nextFloat();
  float velocity = sqrt(velocityX*velocityX+velocityY*velocityY);
  int id;
  Boolean isTouch = false;
  Boolean isBreak = false;
  
  public Bubble(int musicIndex){
    positionX = r.nextInt(width-100);
    positionY = musicIndex*margin+margin;
    id= musicIndex;
  }
  
  void show(){
    
    if(isTouch==false){
      image(lensBubble,positionX-d/2,positionY-d/2,d,d);
      
      
      
    }
    else if(isTouch==true){
      push();
      tint(120, 255, 255, 1000);
      image(lensBubble,positionX-d/2,positionY-d/2,d,d);
      pop();
    }
    
  }
  
  void move(){
    float X = mouseX;
    float Y = mouseY;
    float distance = sqrt((X-positionX)*(X-positionX)+(Y-positionY)*(Y-positionY));
    isTouch = distance<d/2 ? true : false;
    float[] features = ps.getFeatures();
 
    if (features != null) {
 
        float bass = 0;
        for (int i = 5; i < 15; ++i) {
 
            bass += features[i];
        }
        bass /= (float)(5);
        
        if(bass>10)
        bass = 10;
        //System.out.println(bass);
        if(!isTouch){
          
          if(musicList[id].isPlaying)
          {
            velocityX=(bass/10+abs(velocityX))*(velocityX/abs(velocityX));
            velocityY=(bass/10+abs(velocityY))*(velocityY/abs(velocityY));
            
          }
          positionX += velocityX;
          positionY += velocityY;
          if(positionX+d>width){
            positionX = width-d;
            velocityX = -velocityX;
          }
          else if (positionX - d<0){
            positionX = d;
            velocityX = -velocityX;
          }
          if(positionY>height){
            positionY = height;
            velocityY = -velocityY; 
          }
          else if(positionY<0){
            positionY = 0;
            velocityY = -velocityY; 
          }
            
          velocityX*=friction;
          velocityY*=friction;
        }
        else if(isTouch){
          velocityX*=friction;
          velocityY*=friction;
        }
          
 
    }
  }
  
  void breakBubble(){
    if(isBreak==false){
      float X = mouseX;
      float Y = mouseY;
      float distance = sqrt((X-positionX)*(X-positionX)+(Y-positionY)*(Y-positionY));
      if(distance<initd/2){
        d = 0;
        isBreak = true;
        musicList[id].testMusic();
      }
    }
  }
  
  void recreateBubble(){
    d = d+initd/LoopLength;
    if(d>=initd)
      isBreak = false;
    
  }
  
  void collide(){
    for(int i = id+1; i<sampleNumbers;i++){
      if(musicList[i].checkSelected()==true){
        float dx = musicList[i].b.positionX-positionX;
        float dy = musicList[i].b.positionY-positionY;
        float distance = sqrt(dx*dx + dy*dy);
        float minDist = musicList[i].b.d/2+d/2;
        if(distance<minDist){
          float angle = atan2(dy, dx);
          float targetX = positionX + cos(angle) * minDist;
          float targetY = positionY + sin(angle) * minDist;
          float ax = (targetX - musicList[i].b.positionX) * elas;
          float ay = (targetY - musicList[i].b.positionY) * elas;
          velocityX -= ax;
          velocityY-= ay;
          musicList[i].b.velocityX += ax;
          musicList[i].b.velocityY += ay;
        }
      }
    }
  }
  
}

/////////////////////////////////////////////////////////////////////

class ControllButton{
  //variables of 3 different buttons
  float startX;
  float startY;
  float stopX;
  float stopY;
  float volumnX;
  float volumnY;
  float barX;
  float barY;
  float len = 30;
  float radius = 15;
  float iconX;
  float iconY;
  color buttonColor = color(200,200,200);
  
  //initiate the position of the buttons
  ControllButton(){
    startX = 900;
    startY = 900;
    stopX = 800;
    stopY = 900;
    volumnX = 700;
    volumnY = 900;
    barX = 600;
    barY = 912;
    iconX = 550;
    iconY = 910;
  }
  
  //draw three buttons that showed on screen
  void drawButton(){
    colorMode(RGB);
    fill(buttonColor);
    rect(startX,startY,len,len);
    rect(stopX,stopY,len,len);
    
    //volume controller button
    rect(barX,barY,100,6);
    fill(255,255,255);
    ellipse(volumnX,volumnY+15,15,15);
    
    //trumpet
    rect(iconX+5,iconY,5,10);
    triangle(iconX+5,iconY+5,iconX+15,iconY-5,iconX+15,iconY+15);
    push();
    fill(255,255,255,vol*600);
    translate(iconX+20,iconY-3);
    rotate(-PI/6);
    rect(0,0,8,3);
    pop();
    push();
    fill(255,255,255,vol*600);
    translate(iconX+22,iconY+10);
    rotate(PI/6);
    rect(0,0,8,3);
    pop();
    push();
    fill(255,255,255,vol*600);
    rect(iconX+20,iconY+3,10,3);
    pop();
    
    //stop button
    rect(stopX+5,stopY+5,len-10,len-10);
    
    //resume and pause button
    if(boolClick==false)
    {
      fill(255,255,255);
      triangle(startX+5,startY+5,startX+5,startY+len-5,startX+len-5,startY+len/2);
    }
    else if(boolClick==true)
    {
      fill(255,255,255);
      rect(startX+5,startY+5,8,20);
      rect(startX+17,startY+5,8,20);
    }
  }
  
  //this is used to control the volume with dragging the small round button
  void move(float pa,float a){
    if(boolDrag == true){
      if(volumnX>=600&&volumnX<=700)
        volumnX = volumnX+a-pa;
      else if(volumnX<600)
       volumnX = 600;
      else if(volumnX>700)
        volumnX = 700;
    }
  }
  
  //check whether the round button is being dragged
  void checkPressed(float a, float b){
    if(a>=(volumnX-radius/2)&&a<=(volumnX+radius/2)&&b>=(volumnY+radius/2)&&b<=(volumnY+3*radius/2))
      boolDrag = true;
  }
  
  //check whether the stop or pause button is correctly clicked
  void click(float a, float b){
    if(a>=startX&&a<=(startX+len)&&b>=startY&&b<=(startY+len)){
      if(boolClick==false)
        musicStart();
      else if(boolClick==true)
        musicPause();
    }
    else if(a>=stopX&&a<=(stopX+len)&&b>=stopY&&b<=(stopY+len)){
      musicStop();
    }
  }
  
  //change the volume of all music controllers
  void updateVolume(){
    vol = (volumnX-600)/200;
    if(vol<0) vol=0;
    else if(vol>1) vol = 1;
    for(int i = 0;i<musicList.length;i++){
      musicList[i].volumeControl(vol);
    }
  }
  
  //pause the music
  void musicPause(){
    ac.stop();
    
    boolClick = false;
  }
  
  
  //start to play the music
  void musicStart(){
    timeStep = ac.getTimeStep()%LoopLength;  
    sfs = new ShortFrameSegmenter(ac);
    sfs.addInput(ac.out);
    FFT fft = new FFT();
    sfs.addListener(fft);
    ps = new PowerSpectrum();
    fft.addListener(ps);
    ac.out.addDependent(sfs);
    ac.start();
    
    boolClick=true;
    currentLoop = 0;
  }
  
  
  //restart the music and change it into a stop condition
  void musicStop(){
    ac.stop();
    ac=new AudioContext();
    //test = new AudioContext();
    boolClick = false;
    ObjectList.clear();
    for(int i=0;i<musicList.length;i++){
      player[i] = new SamplePlayer(ac, SampleManager.sample(listOfFiles[i].getAbsolutePath()));
      musicList[i] = new musicController(player[i],i);
    }
    
  }
}
class testButton{
  int barX;
  int barY;
  int buttonX;
  int buttonY;
  
  public testButton(){
    barX = 200;
    barY = 900;
  }
  
  public void drawButton(){
    for(int i = barX;i<barX+20;i++){
      fill(200);
      circle(i,barY,10);
    }
    fill(255);
    circle(barX,barY,20);
  }
  
  public void clickButton(){
    
  }
  
}
class LoadButton{
  float positionX = 300;
  float positionY = 900;
  float buttonLength = 50;
  float buttonHeight = 20;
 public LoadButton(){
   
 }
 
 void drawButton(){
   rect(positionX,positionY,buttonLength,buttonHeight);
   fill(0);
   text("Load", positionX+buttonLength/4-2, positionY+buttonHeight/4-3,positionX+buttonLength,positionY+buttonHeight);
 }
 
 void clickButton(float x,float y){
   if(x>positionX&&x<positionX+buttonLength&&y>positionY&&y<positionY+buttonHeight){
     selectInput("Select a file to process:", "fileSelected");
   }
 }
  
}

//this is used to check whether the button is clicked at a specific position
void mousePressed() 
{
  b1.checkPressed(mouseX,mouseY);
}
//release the mouse
void mouseReleased(){
  boolDrag = false;
}
//click the mouse
void mouseClicked(){
  b1.click(mouseX,mouseY);
  lb.clickButton(mouseX,mouseY);
  for(musicController m: musicList){
    m.checkClicked(mouseX,mouseY);
  }
}
//drag the mouse
void mouseDragged()
{
  if(boolDrag==true)
  {
    b1.move(pmouseX,mouseX);
    //update volume of audio context 
     b1.updateVolume();
  }
}
