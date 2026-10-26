/**
 * Musical Circle 005 - Octave ring toggles
 * by Jose Chavarria. Original sketch 2021, version 5 in 2026.
 * Written and commented with the help of AI.
 *
 * This is an open source project.
 *
 * A phase-music system, similar to a Whitney Music Box.
 *
 * The fixed markers around the circle show all 87 piano keys, but
 * moving particles are only created for the notes of the selected scale
 * and the octaves that are turned on.
 * Each particle moves back and forth along a straight line from the center.
 * They all cover the same distance, but their phase advances at a rate set
 * by the note number, so they drift apart. Whenever a particle crosses the
 * base circle it plays its note through MIDI.
 *
 * Changing the scale rebuilds the particles, so the pattern starts again
 * with all the selected notes playing together. Changing the root or
 * turning octaves on or off doesn't restart anything: new particles appear
 * where they would be if they had been there from the start.
 *
 * Controls (GUI):
 *   SCALE      Chromatic or one of the seven modes
 *   ROOT       The root note of the scale
 *   OCTAVES    Click a piece of the ring around the circle to turn that octave
 *              on or off. Drag across pieces to set several at once.
 *   SPEED      How fast the particles move (the middle is the original speed)
 *
 * Keyboard shortcuts: 0-7 pick the scale, LEFT / RIGHT change the root.
 *
 * Libraries: controlP5, The MidiBus. Sends to a virtual MIDI port called
 * "loopMIDI Port" (e.g. loopMIDI on Windows) connected to a synth or DAW.
 */

import themidibus.*;
import controlP5.*;

ControlP5 cp5;
MidiBus myBus; // The MidiBus used to send notes

ArrayList<Particle> particlesList;

// The piano range: MIDI notes 21 (A0) to 107 (B7)
int lowestNote = 21;
int numNotes = 87;

// Particle for each MIDI note, or null if the note is not in the scale
Particle[] particleForNote = new Particle[128];

// Each scale is a list of semitones above the root
String[] scaleNames = {"CHROMATIC", "IONIAN", "DORIAN", "PHRYGIAN", "LYDIAN", "MIXOLYDIAN", "AEOLIAN", "LOCRIAN"};
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

// Octaves that play, from 0 to 7. MIDI octaves start at C, so octave 0
// on a piano only has A0, A#0 and B0, and octave 7 goes up to B7.
boolean[] octaveOn = {true, true, true, true, true, true, true, true};

// How fast the particles oscillate, set by the SPEED knob
float speed = 0.0002;

// Phase shared by all the particles, grows by speed every frame
float phase = 0;

int margin = 50;

// Center and radius of the base circle. The circle sits in a square
// below the controls, as wide as the space between the side margins.
float centerX, centerY;
int circleRadius = 190;

PFont myFont;

void setup(){
  size(800, 950, P3D); // 150px of controls + a 700px square for the circle + margins
  background(0);
  particlesList = new ArrayList<Particle>();

  myFont = createFont("data/standard 07_58 Regular.ttf", 8);
  textFont(myFont);

  centerX = width/2;
  // Center of the space between the controls and the bottom margin
  float controlsBottom = margin + boxSizeX*controlsEnd;
  centerY = controlsBottom + (height-margin-controlsBottom)/2;

  // Print the available MIDI devices to the console, then open
  // the output port (no input, -1) to send notes to.
  MidiBus.list();
  myBus = new MidiBus(this, -1, "loopMIDI Port");

  cp5 = new ControlP5(this);
  setGUI();

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

// Check if a MIDI note is in one of the octaves that are on
boolean inOctaveRange(int note){
  int octave = note/12 - 1; // MIDI note 60 is C4
  return octaveOn[octave];
}

// Create one particle for each piano note in the current scale and selected octaves.
// Starts the phase again from 0, so all the notes play together.
void makeParticles(){
  // Release any notes still playing before replacing the particles
  for (Particle p : particlesList){
    if (p.notePressed) myBus.sendNoteOff(p.channel, p.pitch, p.velocity);
  }
  particlesList.clear();
  particleForNote = new Particle[128];
  phase = 0;

  for (int note = lowestNote; note < lowestNote + numNotes; note++){
    if (inScale(note) && inOctaveRange(note)){
      Particle newParticle = new Particle(note);
      particlesList.add(newParticle);
      particleForNote[note] = newParticle;
    }
  }
}

// Add or remove particles after the root or the octaves change,
// leaving the rest as they are. New particles join at the current phase.
void updateParticles(){
  for (int note = lowestNote; note < lowestNote + numNotes; note++){
    boolean wanted = inScale(note) && inOctaveRange(note);
    Particle p = particleForNote[note];
    if (wanted && p == null){
      Particle newParticle = new Particle(note);
      newParticle.join();
      particlesList.add(newParticle);
      particleForNote[note] = newParticle;
    }
    else if (!wanted && p != null){
      if (p.notePressed) myBus.sendNoteOff(p.channel, p.pitch, p.velocity);
      particlesList.remove(p);
      particleForNote[note] = null;
    }
  }
}

void draw(){
  // Draw a translucent black rectangle instead of clearing the background,
  // so the moving particles leave fading trails.
  noStroke();
  fill(0,50);
  rect(0,0,width,height);

  displayGrid();
  displayText();

  // Move the origin to the center of the circle
  pushMatrix();
  translate(centerX, centerY);

  // Move each particle and draw it
  for(Particle thisParticle : particlesList){
    thisParticle.update();
    stroke(255,100);
    strokeWeight(thisParticle.rad);
    point(thisParticle.pos.x, thisParticle.pos.y);
  }

  // Advance the shared phase once per frame
  phase += speed;

  // Draw the fixed markers for all piano notes on the base circle.
  // The note number is mapped to an angle, so the notes go once around.
  for (int note = lowestNote; note < lowestNote + numNotes; note++){
    float posX = cos(1*radians(map(note,21,108, 0, 360)))*circleRadius;
    float posY = sin(1*radians(map(note,21,108, 0, 360)))*circleRadius;
    // Highlight the marker while its note is playing
    Particle p = particleForNote[note];
    if (p != null && p.notePressed == true){
      strokeWeight(15);
      stroke(activeColor,150);
    }
    else{
      strokeWeight(5);
      stroke(255,100);
    }
    point(posX, posY);
  }
  popMatrix();

  drawOctaveRing();
}

// Keyboard shortcuts. They also move the GUI buttons, so both stay in sync.
void keyPressed(){
  // Number keys pick the scale: 0 is chromatic, 1-7 are the modes
  if (key >= '0' && key <= '7'){
    int newScale = key - '0';
    scaleButtons.activate(newScale);
    SCALE(newScale);
  }
  // Arrow keys move the root up or down by a semitone
  else if (keyCode == RIGHT || keyCode == LEFT){
    int newRoot = (keyCode == RIGHT) ? (root + 1) % 12 : (root + 11) % 12;
    rootButtons.activate(newRoot);
    ROOT(newRoot);
  }
}
