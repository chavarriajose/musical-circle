/**
 * Musical Circle 002 - Scale Modes
 * by Jose Chavarria. Original sketch 2021, scale mode version 2026.
 * Written and commented with the help of AI.
 *
 * This is an open source project.
 *
 * A phase-music system, similar to a Whitney Music Box. This version adds
 * scale modes to the original Musical Circle.
 *
 * The fixed markers around the circle still show all 87 piano keys, but
 * moving particles are only created for the notes of the selected scale.
 * Each particle moves back and forth along a straight line from the center.
 * They all cover the same distance, but their phase advances at a rate set
 * by the note number, so they drift apart. Whenever a particle crosses the
 * base circle it plays its note through MIDI.
 *
 * Changing the scale or the root rebuilds the particles, so the pattern
 * starts again with all the scale notes playing together.
 *
 * Controls:
 *   1-7          Ionian, Dorian, Phrygian, Lydian, Mixolydian, Aeolian, Locrian
 *   0            Chromatic (all notes, like the original)
 *   LEFT / RIGHT Change the root note
 *
 * Requires The MidiBus library and a virtual MIDI port called
 * "loopMIDI Port" (e.g. loopMIDI on Windows) connected to a synth or DAW.
 */

import themidibus.*; // Import the MidiBus library

MidiBus myBus; // The MidiBus used to send notes

ArrayList<Particle> particlesList;

// The piano range: MIDI notes 21 (A0) to 107 (B7)
int lowestNote = 21;
int numNotes = 87;

// Particle for each MIDI note, or null if the note is not in the scale
Particle[] particleForNote = new Particle[128];

// Each scale is a list of semitones above the root
String[] scaleNames = {"Chromatic", "Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"};
int[][] scales = {
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, // Chromatic
  {0, 2, 4, 5, 7, 9, 11},                 // Ionian
  {0, 2, 3, 5, 7, 9, 10},                 // Dorian
  {0, 1, 3, 5, 7, 8, 10},                 // Phrygian
  {0, 2, 4, 6, 7, 9, 11},                 // Lydian
  {0, 2, 4, 5, 7, 9, 10},                 // Mixolydian
  {0, 2, 3, 5, 7, 8, 10},                 // Aeolian
  {0, 1, 3, 5, 6, 8, 10}                  // Locrian
};
String[] noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

int currentScale = 1; // Start in Ionian
int root = 0;         // Start in C

// How fast the particles oscillate. Small changes have a big effect.
float speed = 0.0002;

void setup(){
  size(800, 800, P3D);
  background(0);
  particlesList = new ArrayList<Particle>();

  // Print the available MIDI devices to the console, then open
  // the output port (no input, -1) to send notes to.
  MidiBus.list();
  myBus = new MidiBus(this, -1, "loopMIDI Port");

  makeParticles();
}

// Check if a MIDI note belongs to the current scale and root
boolean inScale(int note){
  int degree = ((note - root) % 12 + 12) % 12; // Semitones above the root
  for (int interval : scales[currentScale]){
    if (interval == degree) return true;
  }
  return false;
}

// Create one particle for each piano note that is in the current scale
void makeParticles(){
  // Release any notes still playing before replacing the particles
  for (Particle p : particlesList){
    if (p.notePressed) myBus.sendNoteOff(p.channel, p.pitch, p.velocity);
  }
  particlesList.clear();
  particleForNote = new Particle[128];

  for (int note = lowestNote; note < lowestNote + numNotes; note++){
    if (inScale(note)){
      Particle newParticle = new Particle(note);
      particlesList.add(newParticle);
      particleForNote[note] = newParticle;
    }
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

  // Move each particle and draw it
  for(Particle thisParticle : particlesList){
    thisParticle.update();
    stroke(255,100);
    strokeWeight(thisParticle.rad);
    point(thisParticle.pos.x, thisParticle.pos.y);
  }

  // Draw the fixed markers for all piano notes on the base circle (radius 150).
  // The note number is mapped to an angle, so the notes go once around.
  for (int note = lowestNote; note < lowestNote + numNotes; note++){
    float posX = cos(1*radians(map(note,21,108, 0, 360)))*150;
    float posY = sin(1*radians(map(note,21,108, 0, 360)))*150;
    // Highlight the marker in red while its note is playing
    Particle p = particleForNote[note];
    if (p != null && p.notePressed == true){
      strokeWeight(15);
      stroke(255,0,0,100);
    }
    else{
      strokeWeight(5);
      stroke(255,100);
    }
    point(posX, posY);
  }
  popMatrix();

  // Show the current scale
  fill(255);
  textSize(16);
  text(noteNames[root] + " " + scaleNames[currentScale], 20, 30);

  // Uncomment to control the speed with the mouse
  //speed = map(mouseX, 0, width, 0.00005, 0.01);
}

void keyPressed(){
  // Number keys pick the scale: 0 is chromatic, 1-7 are the modes
  if (key >= '0' && key <= '7'){
    currentScale = key - '0';
    makeParticles();
  }
  // Arrow keys move the root up or down by a semitone
  else if (keyCode == RIGHT){
    root = (root + 1) % 12;
    makeParticles();
  }
  else if (keyCode == LEFT){
    root = (root + 11) % 12;
    makeParticles();
  }
}
