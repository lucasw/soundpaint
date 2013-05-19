/*
   Copyright 2013 Lucas Walter

 --------------------------------------------------------------------
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


import ddf.minim.*;
import ddf.minim.ugens.*;

Minim              minim;
MultiChannelBuffer sampleBuffer;

AudioOutput        output;
Sampler[]            sampler = new Sampler[10];
Sampler val_sampler;

int[] vals = new int[256];
MultiChannelBuffer valBuffer;

final int y_max = 256;

void setup()
{
  size(800, 450); //, P3D);
  
  // create Minim and an AudioOutput
  minim  = new Minim(this);
  output = minim.getLineOut();
  
  // construct a new MultiChannelBuffer with 2 channels and 1024 sample frames.
  // in our particular case, it doesn't really matter what we choose for these
  // two values because loadFileIntoBuffer will reconfigure the buffer 
  // to match the channel count and length of the file.
  sampleBuffer     = new MultiChannelBuffer( 1, 1024 );
  
  valBuffer = new MultiChannelBuffer( vals.length * 60, 1 );
  println("buffer size " + str(valBuffer.getBufferSize()) );

  // we pass the buffer to the method and Minim will reconfigure it to match 
  // the file. if the file doesn't exist, or there is some other problen with 
  // loading it, the function will return 0 as the sample rate.
  float sampleRate = minim.loadFileIntoBuffer( "SD.wav", sampleBuffer );
  
  // make sure the file load worked
  if ( sampleRate > 0 )
  {
    // double the size of the buffer to give ourselves some silence to play with
    int originalBufferSize = sampleBuffer.getBufferSize();
    sampleBuffer.setBufferSize( originalBufferSize * 2 );
    
    // go through first half of the buffer, which contains the original sample,
    // and add a delayed version of each sample at some random position.
    // we happen to know that the source file is only one channel
    // but in general you'd want to iterate over all channels when doing something like this
    float min = 0;
    float max = 0;
    for( int s = 0; s < originalBufferSize; ++s )
    {
      float sampleValue = sampleBuffer.getSample( 0, s );
      
      if (sampleValue < min) min = sampleValue;
      if (sampleValue > max) max = sampleValue;
      /*
      int   delayIndex  = s + int( random( 0, originalBufferSize ) );
      float destValue   = sampleBuffer.getSample( 0, delayIndex ); 
      sampleBuffer.setSample( 0, // channel
                              delayIndex, // sample frame to set
                              sampleValue + destValue // the value to set
                            );
    */
    }
    println("min max " + str(min) + " " + str(max));
    
    for (int i = 0; i < sampler.length; i++) {
      // create a sampler that will use our buffer to generate audio.
      // we must provide the sample rate of the audio and the number of voices. 
      sampler[i] = new Sampler( sampleBuffer, sampleRate*(i*0.5 + 0.25), 1 );
    
      // and finally, connect to the output so we can hear it
      sampler[i].patch( output );
    }
  }

  frameRate(20);
}

int ind = 0;
boolean recording = false;
float min = 0;
float max = 0;
boolean old_mouse_pressed = false;
int old_mouse_x= 0;
int old_mouse_y = 0;

void draw() {
  background(0);
  stroke(10, 255, 20);
  
  final float sc = 30;
  // use the mix buffer to draw the waveforms.
  for (int i = 0; i < output.bufferSize() - 1; i++)
  {
    float x1 = map(i,   0, output.bufferSize(), 0, width);
    float x2 = map(i+1, 0, output.bufferSize(), 0, width);
    line(x1, y_max +       sc - output.left.get(i)   *sc,  
         x2, y_max +       sc - output.left.get(i+1) *sc);
    line(x1, y_max + 100 + sc - output.right.get(i)  *sc, 
         x2, y_max + 100 + sc - output.right.get(i+1)*sc);
  }
 
  // draw the waveform
  noFill();
  stroke(255);
  rect(0, 0, vals.length, y_max);
  stroke(255,0,0);
  for (int i = 1; i < vals.length; i++) {
    line( (i-1), vals[i-1], i, vals[i] ); 
  }
 
  int mouse_x = (int) mouseX; 
  if ( mousePressed &&
    ( mouse_x < vals.length ) &&
    ( mouse_x >= 0 ) && 
    ( mouseY < y_max) ) {
    
    //if (abs(mouse_x - old_mouse_x) < 10) {
    if (old_mouse_pressed &&
    ( old_mouse_x < vals.length ) &&
    ( old_mouse_x >= 0 ) ) {
    
      for (int i = min(mouse_x, old_mouse_x); i < max(mouse_x, old_mouse_x); i++) {
        vals[i] = mouseY;
      }
    } else {
      vals[mouse_x] = mouseY;
    }

    if (mouseY > max) max = mouseY;
    if (mouseY < min) min = mouseY;
  
  }
  old_mouse_x = mouse_x;
  //old_mouse_y = mouse_y;

  //if (!mousePressed && old_mouse_pressed) //ind >= vals.length) 
    old_mouse_pressed = mousePressed;

  // update all the samples based on the currently drawn waveform
  if (recording) {
    for (int i = 0; i < valBuffer.getBufferSize(); i++) {
      //float v = ( ( (float) vals[i % vals.length] - min ) /
      //    ( max - min ) ) * 2.0 - 1.0;
      float v = ( ( (float) vals[i % vals.length] ) /
          ( (float)y_max ) ) * 2.0 - 1.0;
      valBuffer.setSample( 0, i, v );
    }
   
    for (int i = 0; i < sampler.length; i++) {
      float rate = 1000 + 10000 * ((float)i + 1);
      println( "rate " + str(rate) );
      sampler[i] = new Sampler( valBuffer, rate, 1 ); // 4000.0 * (i + 1) * (i + 1), 1 );

      // and finally, connect to the output so we can hear it
      sampler[i].patch( output );
    }
    min = 0;
    max = 0;

    recording = false;
  }

}

void keyPressed() 
{
  /*if ( key == ' ' && sampler != null )
  {
    sampler.trigger();
  }*/
  if (key == 'r') {
    recording = true;

  } //

  //if (key == 'a' && val_sampler != null)  val_sampler.trigger();
  
  if (key == 'b') {


  }
  if (key == 'a') sampler[0].trigger();
  if (key == 's') sampler[1].trigger();
  if (key == 'd') sampler[2].trigger();
  if (key == 'f') sampler[3].trigger();
  if (key == 'g') sampler[4].trigger();
  if (key == 'h') sampler[5].trigger();
  if (key == 'j') sampler[6].trigger();
  if (key == 'k') sampler[7].trigger();
  if (key == 'l') sampler[8].trigger();
  if (key == ';') sampler[9].trigger();
}

