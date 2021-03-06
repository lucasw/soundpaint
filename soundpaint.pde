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

import java.util.Date;

import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.analysis.FFT;

Minim              minim;
MultiChannelBuffer sampleBuffer;

AudioOutput        output;
final int NUM_SAMPLES = 10;
Sampler[]            sampler = new Sampler[NUM_SAMPLES];
Sampler val_sampler;

final int NUM = 256;
float[] vals = new float[NUM];
// index into the vals for individual value manipulation 
int val_ind = 0;
//float[] fft_pow = new float[NUM];
//float[] fft_phase = new float[NUM];
int spect_ind = 0;

MultiChannelBuffer[] valBuffer = new MultiChannelBuffer[NUM_SAMPLES];

final int y_max = 256;

public class FFTb extends FFT
{
  protected float[] phase;

  public FFTb(int timeSize, float sampleRate)
  { 
    super(timeSize, sampleRate);
  }

  protected void allocateArrays()
  {
    super.allocateArrays();
    phase = new float[timeSize / 2 + 1];
  }

  protected void fillSpectrum()
  {
    super.fillSpectrum();
    
    float unwrap = 0;
    float pmin = 1e6;
    float pmax = -1e6;
    for (int i = 0; i < phase.length; i++) 
    {
      phase[i] = (float) Math.atan2(imag[i], real[i]) + unwrap;
      
      if (phase[i] > pmax) pmax = phase[i];
      if (phase[i] < pmin) pmin = phase[i];
      
      //println("phase " + str(i) + " " + str(phase[i]));
      // unwrap
      /*
      if (i > 0) {
        if ( (phase[i] - phase[i-1]) > (TWO_PI - 1.2) ) {
           println("unwrap " + str(i) + " " + str(phase[i]) + " " + str(phase[i-1]));
           unwrap -= TWO_PI;
           phase[i] -= TWO_PI;
        }
        if ( (phase[i-1] - phase[i]) > (TWO_PI - 1.2) ) {
           println("unwrap " + str(i) + " " + str(phase[i]) + " " + str(phase[i-1]));
           unwrap += TWO_PI;
           phase[i] += TWO_PI;
        }

      } // unwrap
      */
    } // phase loop
    //println("phase " + str(pmin) + " " + str(pmax));
  } // fillSpectrum
 
  /*
   *  This is the new function all the other functions 
   *  are in service of- get the phase from the fft 
   */
  public float getPhase(int i)
  {
    if (i < 0) i = 0;
    if (i > phase.length - 1) i = phase.length - 1;
    return phase[i];
  }

  public void setPhase(int i, float new_phase)
  {
    if (i < 0) i = 0;
    if (i > phase.length - 1) i = phase.length - 1;
    
    phase[i] = new_phase;
    real[i] = spectrum[i] * cos(new_phase);
    imag[i] = spectrum[i] * sin(new_phase);

    if (i != 0 && i != timeSize / 2)
    {
      real[timeSize - i] = real[i];
      imag[timeSize - i] = -imag[i];
    }

  }
}

FFTb fft = new FFTb(vals.length, 22100);

void setup()
{
  size(1280, 720); //, P3D);
  
  // create Minim and an AudioOutput
  minim  = new Minim(this);
  output = minim.getLineOut();
  
  // construct a new MultiChannelBuffer with 2 channels and 1024 sample frames.
  // in our particular case, it doesn't really matter what we choose for these
  // two values because loadFileIntoBuffer will reconfigure the buffer 
  // to match the channel count and length of the file.
  sampleBuffer     = new MultiChannelBuffer( 1, 1024 );
 
  for (int i = 0; i < NUM_SAMPLES; i++) {
    valBuffer[i] = new MultiChannelBuffer( vals.length * (i+1) * 7, 1 );
  }
  println("max buffer size " + str(valBuffer[NUM_SAMPLES-1].getBufferSize()) );

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

  frameRate(10);
}


int ind = 0;
boolean recording = false;
boolean vals_changed = false;
boolean new_ifft = false;
float min = 0;
float max = 0;
boolean old_mouse_pressed = false;
int old_mouse_x= 0;
int old_mouse_y = 0;
final int x_spectrum_min = NUM + 50;
final int x_spectrum_max = x_spectrum_min + NUM/2; 
final int x_phase_min = x_spectrum_max + 50;
final int x_phase_max = x_phase_min + NUM/2; 
final float fft_sc = 10.0;
final float fft_off = 170.0;

void changeBand(int mouse_x, float mouse_y) {
  int ind = mouse_x - x_spectrum_min;
  float fft_pow_new = exp(( y_max - fft_off - mouse_y) / fft_sc);
  //fft_pow[ind] = fft_pow_new;

  //println("new fft pow " + str(ind) + " " + str(fft_pow_new)) ;
  fft.setBand(ind, fft_pow_new);
}

void changePhase(int mouse_x, float mouse_y) {
  int ind = mouse_x - x_phase_min;
  //float fft_pow_new = exp(( y_max - fft_off - mouse_y) / fft_sc);

  float fft_phase_new = (y_max - 100.0 - mouse_y)/10.0;

  //println("new fft phase " + str(ind) + " " + str(fft_phase_new)) ;
  fft.setPhase(ind, fft_phase_new);
}

// called once every time the mouse moves and a mouse button is pressed
ArrayList mouse_xy = new ArrayList();
void mouseDragged() {
  
  mouse_xy.add(new PVector(mouseX, mouseY));
}

void draw() {
  background(0);
  strokeWeight(1.0);
  stroke(10, 255, 20);
  
  final float sc = 30;
  // use the mix buffer to draw the waveforms.
  for (int i = 0; i < output.bufferSize() - 1; i++)
  {
    float x1 = map(i,   0, output.bufferSize(), 0, width);
    //float x2 = map(i+1, 0, output.bufferSize(), 0, width);
    line(x1, y_max + (height - y_max)/2,  
         x1, y_max + (height - y_max)/2 - output.left.get(i) * sc);
  }
 
  // draw the time waveform
  noFill();
  stroke(255);
  rect(0, 0, vals.length, y_max);
  stroke(255,0,0);
  for (int i = 0; i < vals.length; i++) {
    //line( (i-1), vals[i-1], i, vals[i] ); 
    line( i, y_max/2, i, vals[i] + y_max/2); 
  }
  // draw the currently selected sample
  stroke(255,100,100);
  line( val_ind, y_max/2, val_ind, vals[val_ind] + y_max/2); 


  //final float fft_sc = 0.25;
  // draw the fft
  final float phase_sc = 5.0;
  { 
    noStroke();
    fill(32);
    rect(x_phase_min, y_max/2 - 2 * TWO_PI * phase_sc, 
        vals.length/2, 4 * TWO_PI * phase_sc);
    fill(64);
    rect(x_phase_min, y_max/2 - TWO_PI * phase_sc, 
        vals.length/2, 2 * TWO_PI * phase_sc);

    noFill();
      stroke(255);
      rect(x_spectrum_min, 0, vals.length/2, y_max);
      rect(x_phase_min, 0, vals.length/2, y_max);
  

      for (int i = 0; i < vals.length/2; i++) {
        if (i == spect_ind) 
          stroke(155, 100, 110);
        else
          stroke(255, 200, 0);
        //fft_pow[i] = fft.getBand(i);
        //fft_pow[fft_pow.length - i - 1] = fft_pow[i];

        //fft_phase[i] = fft.getBand(i);
        //fft_phase[fft_phase.length - i - 1] = fft_phase[i];

        // pix_y = y_max - (fft_off + fft_sc * log(fft_pow[i])) ;
        // pix_y = y_max - fft_off - fft_sc * log(fft_pow[i]) ;
        // fft_sc * log(fft_pow[i]) = y_max - fft_off - pix_y
        // fft_pow[i] = exp(( y_max - fft_off - pix_y) / fft_sc)
        line( x_spectrum_min + i, y_max, 
              x_spectrum_min + i, 
              y_max - (fft_off + fft_sc * log(fft.getBand(i))) ); 
              //x_off + i, y_max - (fft_sc * (fft_pow[i])) ); 
  
        // pix_y = y_max - 100 - 10* phase
        // phase =( y_max - 100 - pix_y)/10

        // TBD unwrap the phase
      
        stroke(100, 50, 0);
        line( 
              x_phase_min + i, y_max/2 - (phase_sc * (fft.getPhase(i) + 2*TWO_PI)), 
              x_phase_min + i, y_max/2 - (phase_sc * (fft.getPhase(i) - 2*TWO_PI)) );

        stroke(165, 100, 0);
        line( 
              x_phase_min + i, y_max/2 - (phase_sc * (fft.getPhase(i) + TWO_PI)), 
              x_phase_min + i, y_max/2 - (phase_sc * (fft.getPhase(i) - TWO_PI)) );

        if (i == spect_ind) 
          stroke(155, 100, 110);
        else
          stroke(255, 200, 0);
        line( x_phase_min + i, y_max/2, 
              x_phase_min + i, y_max/2 - (phase_sc * fft.getPhase(i) ) ); 
      }
  }

  int mouse_x = (int) mouseX;
  int mouse_y = mouseY;

  // mouse in 
  // if ( mousePressed ) {
  while (mouse_xy.size() > 0) {
    //println("mouse_xy size " + str(mouse_xy.size())); 
    mouse_x = (int) ((PVector) (mouse_xy.get(0))).x;
    mouse_y = (int) ((PVector) (mouse_xy.get(0))).y;
    mouse_xy.remove(0);

    // in time signal area
    if ( ( mouse_x < vals.length ) &&
        ( mouse_x >= 0 ) && 
        ( mouse_y < y_max) ) {

      //if (abs(mouse_x - old_mouse_x) < 10) {
      if (old_mouse_pressed &&
          ( old_mouse_x < vals.length ) &&
          ( old_mouse_x >= 0 ) ) {

        // TBD replace this with a function that takes the mouse_xy vector
        // and returns a vector with all the intermediate positions
        float y_accum = (float) old_mouse_y;
        float y_step = (float)(mouse_y - old_mouse_y)/(float)abs(mouse_x - old_mouse_x);
        for (int i = min(mouse_x, old_mouse_x); i < max(mouse_x, old_mouse_x); i++) {
          vals[i] = y_accum - y_max/2;
          y_accum += y_step;
          vals_changed = true;
        }
      } else {
        vals[mouse_x] = mouse_y - y_max/2;
      }

      if (mouse_y > max) max = mouse_y;
      if (mouse_y < min) min = mouse_y;

    }

    // in fft power area
    if (( mouse_x < x_spectrum_max ) &&
        ( mouse_x >= x_spectrum_min ) && 
        ( mouse_y < y_max) ) {

      if (old_mouse_pressed &&
          ( old_mouse_x < x_spectrum_max ) &&
          ( old_mouse_x >= x_spectrum_min ) ) {

        float y_accum = (float) old_mouse_y;
        float y_step = (float)(mouse_y - old_mouse_y)/(float)abs(mouse_x - old_mouse_x);
        for (int i = min(mouse_x, old_mouse_x); i < max(mouse_x, old_mouse_x); i++) {
          changeBand(i, y_accum); 
          y_accum += y_step;
        }
      } else {
        changeBand(mouse_x, mouse_y); 
      }
       
      vals_changed = true;
      new_ifft = true;
    }

    // in fft phase area
    if (( mouse_x < x_phase_max ) &&
        ( mouse_x >= x_phase_min ) && 
        ( mouse_y < y_max) ) {

      if (old_mouse_pressed &&
         ( mouse_x <  x_phase_max ) &&
         ( mouse_x >= x_phase_min ) ) { 

        float y_accum = (float) old_mouse_y;
        float y_step = (float)(mouse_y - old_mouse_y)/(float)abs(mouse_x - old_mouse_x);
        for (int i = min(mouse_x, old_mouse_x); i < max(mouse_x, old_mouse_x); i++) {
          changePhase(i, y_accum); 
          y_accum += y_step;
        }
      } else {
        changePhase(mouse_x, mouse_y); 
      }

      vals_changed = true;
      new_ifft = true;
    }
  
    old_mouse_x = mouse_x;
    old_mouse_y = mouse_y;
  } // mousePressed

  old_mouse_x = mouse_x;
  old_mouse_y = mouse_y;
  
  if ((!mousePressed && old_mouse_pressed)) {

    if (vals_changed) {
      recording = true;
      vals_changed = false;
    }

  }
  
  old_mouse_pressed = mousePressed;

  // TBD only do this every n updates or less?
  // update all the samples based on the currently drawn waveform
  if (recording) {
    if (new_ifft) {
      fft.inverse(vals);
      new_ifft = false;
    }
    fill(0,255,0);
    rect(10,10, 20,20);
    for (int i = 0; i < valBuffer[NUM_SAMPLES-1].getBufferSize(); i++) {
      //float v = ( ( (float) vals[i % vals.length] - min ) /
      //    ( max - min ) ) * 2.0 - 1.0;
      float v = ( ( vals[i % vals.length] ) /
          ( (float)y_max/2 ) );
      
      for (int j = 0; j < valBuffer.length; j++) {
        if (i < valBuffer[j].getBufferSize()) 
          valBuffer[j].setSample( 0, i, v );
      }
    }
   
    for (int i = 0; i < sampler.length; i++) {
      float rate = 2000 + 7000 * ((float)i + 1);
      //println( "rate " + str(rate) );
      sampler[i] = new Sampler( valBuffer[i], rate, 1 ); // 4000.0 * (i + 1) * (i + 1), 1 );

      // and finally, connect to the output so we can hear it
      sampler[i].patch( output );
    }
    min = 0;
    max = 0;

    /// fft
    fft.forward(vals);

    recording = false;
  }

}


void keyPressed() 
{
  /*if ( key == ' ' && sampler != null )
  {
    sampler.trigger();
  }*/
  //if (key == 'r') {
  //  recording = true;
  //} //

  //if (key == 'a' && val_sampler != null)  val_sampler.trigger();
 
  if (key == 't') {
    for (int i = 0; i < vals.length; i++) {
      vals[i] *= 0.96;
    }
    recording = true;
  }

  if (key == 'y') {
    for (int i = 0; i < vals.length; i++) {
      vals[i] *= 1.03;
    }
    recording = true;
  }

  if (key == 'p') {

    Table table = createTable();
    table.addColumn("val");
  
    for (int i = 0; i < vals.length; i++) {
      TableRow row = table.addRow();
      row.setFloat("val", vals[i]);
    }
    
    // save to disk
    Date dt = new Date();
    long ts = dt.getTime();
    String name = "data/cur_" + ts + ".csv";
    saveTable(table, name);
    println("saved " + name);
  }

  if (key == 'u') {
    float[] vals2 = new float[vals.length];
    // TBD make the filter configurable in another widget
    float[] filt = new float[5];
    filt[0] = 0.05;
    filt[1] = 0.2;
    filt[2] = 0.5;
    filt[3] = 0.2;
    filt[4] = 0.05;
    
    // convolution
    for (int i = 0; i < vals.length; i++) {
      for (int j = 0; j < filt.length; j++) {
        int ind = i - j - (filt.length/2);
        ind = (ind + vals.length) % vals.length;
        vals2[i] += vals[ind] * filt[j];
      }
    }
    vals = vals2;
    recording = true;
  }
  if (key == 'i') {

    float mean_v = 0;
    float max_v = 0;
    float min_v = 1e6;
    for (int i = 0; i < vals.length; i++) {
      mean_v += vals[i];

      if (vals[i] > max_v) max_v = vals[i];
      if (vals[i] < min_v) min_v = vals[i];
    }
    mean_v /= vals.length;

    println("mean val " + str(mean_v));

    for (int i = 0; i < vals.length; i++) {
      vals[i] -= mean_v;

      //vals
    }
    recording = true;
  }

  if (key == 'h') {
    val_ind -= 1;
    val_ind = (val_ind + vals.length) % vals.length;
  }
  if (key == 'l') {
    val_ind += 1;
    val_ind = (val_ind + vals.length) % vals.length;
  }
  if (key == 'j') {
    vals[val_ind] -= 0.1;
    if (vals[val_ind] < 0) vals[val_ind] *= 1.05;
    if (vals[val_ind] > 0) vals[val_ind] *= 0.96;
    recording = true;
  }
  if (key == 'k') {
    vals[val_ind] += 0.091;
    if (vals[val_ind] > 0) vals[val_ind] *= 1.051;
    if (vals[val_ind] < 0) vals[val_ind] *= 0.962;
    recording = true;
  }

  if (key == 's') {
    spect_ind -= 1;
    spect_ind = (spect_ind + NUM/2) % (NUM/2);
  }
  if (key == 'g') {
    spect_ind += 1;
    spect_ind = (spect_ind + NUM/2) % (NUM/2);
  }
  if (key == 'd') {
    float val = fft.getBand(spect_ind);
    fft.setBand(spect_ind, val * 0.85);
    println(val);
    recording = true;
    new_ifft = true;
  }
  if (key == 'f') {
    float val = fft.getBand(spect_ind);
    fft.setBand(spect_ind, (val + 0.0001) * 1.141);
    println(val);
    recording = true;
    new_ifft = true;
  }
  if (key == 'e') {
    float val = fft.getPhase(spect_ind);
    fft.setPhase(spect_ind, val - 0.01);
    println(val);
    recording = true;
    new_ifft = true;
  }
  if (key == 'r') {
    float val = fft.getPhase(spect_ind);
    fft.setPhase(spect_ind, val + 0.0113);
    println(val);
    recording = true;
    new_ifft = true;
  }

  // play different samplerates
  if (key == 'z') sampler[0].trigger();
  if (key == 'x') sampler[1].trigger();
  if (key == 'c') sampler[2].trigger();
  if (key == 'v') sampler[3].trigger();
  if (key == 'b') sampler[4].trigger();
  if (key == 'n') sampler[5].trigger();
  if (key == 'm') sampler[6].trigger();
  if (key == ',') sampler[7].trigger();
  if (key == '.') sampler[8].trigger();
  if (key == '/') sampler[9].trigger();
}

