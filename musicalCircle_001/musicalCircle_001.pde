/**
 * Musical Circle
 * by Jose Chavarria, 2021.
 * Comments written with the help of AI.
 *
 * This is an open source project.
 *
 * A chromatic phase-music system, similar to a Whitney Music Box.
 *
 * 87 particles are arranged around a circle, one for each piano key
 * (MIDI notes 21 to 107). Each particle only moves back and forth along
 * a straight line from the center, and all of them cover the same
 * distance. What changes is where each one is in its sine wave: the
 * phase advances at a rate set by the note number, so the particles
 * drift apart and some seem faster than others.
 *
 * Whenever a particle crosses the base circle it plays its note through
 * MIDI. The sound comes from how these offset particles meet the circle:
 * they scatter into rhythms, and every so often groups of them line up
 * again and play together as evenly spaced chords (whole-tone scales,
 * diminished and augmented chords, octaves), until all 87 notes
 * meet again in one full chromatic cluster.
 *
 * Requires The MidiBus library and a virtual MIDI port called
 * "loopMIDI Port" (e.g. loopMIDI on Windows) connected to a synth or DAW.
 */

import themidibus.*; // Import the MidiBus library

MidiBus myBus; // The MidiBus used to send notes

ArrayList<Particle> particlesList;
int numParticles;

// How fast the particles oscillate. Small changes have a big effect.
float speed = 0.0002;

void setup(){
  size(800, 800, P3D);
  background(0);
  particlesList = new ArrayList<Particle>();
  numParticles = 87; // One particle per piano key

  makeParticles();

  // Print the available MIDI devices to the console, then open
  // the output port (no input, -1) to send notes to.
  MidiBus.list();
  myBus = new MidiBus(this, -1, "loopMIDI Port");
}

// Create one particle per note, starting at MIDI note 21 (lowest A on a piano).
void makeParticles(){
  for (int index = 0; index < numParticles; index++){
    Particle newParticle = new Particle(index+21);
    particlesList.add(newParticle);
  }
}

void draw(){
  // Draw a translucent black rectangle instead of clearing the background,
  // so the moving particles leave fading trails.
  noStroke();
  fill(0,50);
  rect(0,0,width,height);

  // Move the origin to the center of the window
  pushMatrix();
  translate(width/2, height/2);

  for(Particle thisParticle : particlesList){
    // Move the particle and draw it
    thisParticle.update();
    stroke(255,100);
    strokeWeight(thisParticle.rad);
    point(thisParticle.pos.x, thisParticle.pos.y);

    // Draw the fixed marker for this note on the base circle (radius 150).
    // The note number is mapped to an angle, so the notes go once around.
    stroke(255,100);
    float posX = cos(1*radians(map(thisParticle.id,21,108, 0, 360)))*150;
    float posY = sin(1*radians(map(thisParticle.id,21,108, 0, 360)))*150;
    // Highlight the marker in red while its note is playing
    if (thisParticle.notePressed == true){
      strokeWeight(15);
      stroke(255,0,0,100);
    }
    else{
      strokeWeight(5);
    }
    point(posX, posY);
  }
  popMatrix();

  // Uncomment to control the speed with the mouse
  //speed = map(mouseX, 0, width, 0.00005, 0.01);
}
