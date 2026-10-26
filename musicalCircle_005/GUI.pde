/**
 * GUI for Musical Circle.
 *
 * SCALE and ROOT buttons pick the notes, the SPEED knob sets how fast
 * the particles move, and the ring around the circle turns each
 * octave on or off.
 *
 * Each row of controls has a label band on top (one cell) and the
 * controls below, with guide lines between the bands.
 */

RadioButton scaleButtons;
RadioButton rootButtons;
Knob knobSpeed;

// Colors
color activeColor = color(60,230,110);
color foregroundColor = color(20,170,70);
color backgroundColor = color(10,80,35);

int boxSizeX = 25;  // Size of one grid cell
int buttonSpacing = 5; // Gap between buttons in a row

// Top of each band, in grid cells below the top margin
int titleRow = 0;   // Title
int row1Label = 1;  // SCALE, SPEED labels
int row1 = 2;       // SCALE buttons, SPEED knob (two cells tall)
int row2Label = 4;  // ROOT label
int row2 = 5;       // ROOT buttons (one cell tall)
int controlsEnd = 6; // Bottom of the controls, the circle starts here

// OCTAVES ring: the notes already sit around the circle by pitch, so each
// octave is a piece of the circle. The ring is split into those pieces,
// and each piece turns its octave on or off.
float ringRadius = circleRadius*1.6; // Just outside the farthest particles
boolean[] ringOn = new boolean[8]; // What the ring shows, can change while dragging
boolean painting = false;          // True while the mouse is pressed on the ring
boolean paintState;                // On or off, set by the first piece clicked

// Screen position of a grid cell
int gridX(int cell){ return margin + boxSizeX*cell; }
int gridY(int cell){ return margin + boxSizeX*cell; }

void setGUI(){
  // SCALE: chromatic or one of the seven modes
  scaleButtons = addButtonRow("SCALE", scaleNames, gridX(0), gridY(row1), boxSizeX*3-buttonSpacing, boxSizeX*2);

  // ROOT: the note the scale starts from
  rootButtons = addButtonRow("ROOT", noteNames, gridX(0), gridY(row2), 30, boxSizeX);

  scaleButtons.activate(currentScale);
  rootButtons.activate(root);

  arrayCopy(octaveOn, ringOn);

  // SPEED: 0-100, the middle (50) is the original speed
  knobSpeed = cp5.addKnob("SPEED")
               .setRange(0,100)
               .setValue(50)
               .setColorBackground(backgroundColor)
               .setColorActive(activeColor)
               .setColorForeground(foregroundColor)
               .setPosition(gridX(26), gridY(row1))
               .setRadius(boxSizeX)
               ;
  knobSpeed.getCaptionLabel().setVisible(false);
}

// A row of buttons where only one can be selected
RadioButton addButtonRow(String name, String[] labels, int x, int y, int buttonWidth, int buttonHeight){
  RadioButton r = cp5.addRadioButton(name)
         .setPosition(x, y)
         .setSize(buttonWidth, buttonHeight)
         .setColorBackground(backgroundColor)
         .setColorForeground(foregroundColor)
         .setColorActive(activeColor)
         .setColorLabel(color(255))
         .setItemsPerRow(labels.length)
         .setSpacingColumn(buttonSpacing)
         .setNoneSelectedAllowed(false)
         ;
  // Item names must be unique in controlP5, so add the row name
  for (int index = 0; index < labels.length; index++){
    r.addItem(name + "_" + labels[index], index);
  }
  // Show the short label, placed inside the button
  for (int index = 0; index < labels.length; index++){
    Toggle t = r.getItem(index);
    t.setCaptionLabel(labels[index]);
    t.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  }
  return r;
}

// controlP5 calls a function with the same name as each controller

// SCALE buttons: rebuild the particles for the new scale
void SCALE(int a){
  if (a < 0) return;
  currentScale = a;
  makeParticles();
}

// ROOT buttons: swap in the notes of the new root without restarting
void ROOT(int a){
  if (a < 0) return;
  root = a;
  updateParticles();
}

// SPEED knob: 0 is 10 times slower, 100 is 10 times faster.
// The scale is exponential so small speeds are easy to set.
void SPEED(float theValue){
  speed = 0.0002 * pow(10, (theValue-50)/50);
}

// The note where an octave boundary sits, halfway between a B and the next C.
// Boundary 0 is just before A0, boundary 8 is just after B7.
float boundaryNote(int b){
  if (b == 0) return 20.5;
  if (b == 8) return 107.5;
  return 12*(b+1) - 0.5;
}

// Angle on the circle of a note, the same mapping as the markers
float noteAngle(float note){
  return radians(map(note, 21, 108, 0, 360));
}

// The note at the mouse's angle around the circle
float noteAtMouse(){
  float a = atan2(mouseY-centerY, mouseX-centerX);
  return map((degrees(a)+360) % 360, 0, 360, 21, 108);
}

// The octave under the mouse, or -1 if the mouse is not on the ring
int octaveAtMouse(){
  if (!mouseOnRing()) return -1;
  float note = noteAtMouse();
  for (int o = 0; o < 8; o++){
    if (note >= boundaryNote(o) && note < boundaryNote(o+1)) return o;
  }
  return -1;
}

boolean mouseOnRing(){
  float d = dist(mouseX, mouseY, centerX, centerY);
  return d > ringRadius-20 && d < ringRadius+20;
}

// Press on a piece: flip that octave. Dragging from there sets every
// piece it passes over to the same state, so you can turn several on or off.
void mousePressed(){
  int o = octaveAtMouse();
  if (o < 0) return;
  painting = true;
  paintState = !ringOn[o];
  ringOn[o] = paintState;
}

void mouseDragged(){
  if (!painting) return;
  int o = octaveAtMouse();
  if (o >= 0) ringOn[o] = paintState;
}

// Release: play the octaves that are on. With all of them off, nothing plays.
void mouseReleased(){
  if (!painting) return;
  painting = false;
  boolean changed = false;
  for (int o = 0; o < 8; o++){
    if (ringOn[o] != octaveOn[o]) changed = true;
  }
  if (changed){
    arrayCopy(ringOn, octaveOn);
    updateParticles();
  }
}

// Draw the ring: one piece per octave, octaves that are on bright,
// the one under the mouse a bit lighter, and its number outside
void drawOctaveRing(){
  pushMatrix();
  translate(centerX, centerY);
  int hovered = painting ? -1 : octaveAtMouse();
  float gap = radians(0.8); // Small gap so the octaves read as separate pieces
  textSize(8);
  textAlign(CENTER, CENTER);
  for (int o = 0; o < 8; o++){
    if (o == hovered) stroke(ringOn[o] ? foregroundColor : color(30,120,60));
    else if (ringOn[o]) stroke(activeColor);
    else stroke(backgroundColor);
    strokeWeight(8);
    noFill();
    arc(0, 0, ringRadius*2, ringRadius*2, noteAngle(boundaryNote(o))+gap, noteAngle(boundaryNote(o+1))-gap);

    // Octave number in the middle of its piece
    float mid = noteAngle((boundaryNote(o) + boundaryNote(o+1))/2);
    fill(ringOn[o] ? 255 : 120);
    text("" + o, cos(mid)*(ringRadius+14), sin(mid)*(ringRadius+14));
  }
  popMatrix();
}

// Title and labels, each label in the band above its controls
void displayText(){
  textAlign(LEFT);
  fill(255);
  textSize(20);
  text("MUSICAL_CIRCLE", gridX(0), gridY(titleRow+1)-5);
  textSize(8);
  text("SCALE", gridX(0), gridY(row1)-8);
  textAlign(CENTER);
  text("SPEED", gridX(26)+boxSizeX, gridY(row1)-8); // Centered over the knob
  textAlign(LEFT);
  text("ROOT", gridX(0), gridY(row2)-8);
}

// Background guide lines: borders, and the top and bottom of every band
void displayGrid(){
  stroke(80);
  strokeWeight(0.5);
  // Border lines
  line(margin, 0, margin, height);
  line(width-margin, 0, width-margin, height);
  line(0, margin, width, margin);
  line(0, height-margin, width, height-margin);

  // Top and bottom of every band
  int[] rows = {titleRow+1, row1Label+1, row1+2, row2Label+1, row2+1};
  for (int r : rows){
    line(0, gridY(r), width, gridY(r));
  }

  // Left side of the SPEED knob, through its label and knob bands
  line(gridX(26), gridY(row1Label), gridX(26), gridY(row1+2));
}
