/**
 * GUI for Musical Circle.
 *
 * SCALE and ROOT buttons pick the notes, the OCT LOW and OCT HIGH knobs
 * set which octaves play, and the SPEED knob sets how fast the particles move.
 *
 * Each row of controls has a label band on top (one cell) and the
 * controls below (two cells), with guide lines between the bands.
 */

RadioButton scaleButtons;
RadioButton rootButtons;
Knob knobLow;
Knob knobHigh;
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
int row2Label = 4;  // ROOT, OCT LOW, OCT HIGH labels
int row2 = 5;       // ROOT buttons, octave knobs (two cells tall)
int controlsEnd = 7; // Bottom of the controls, the circle starts here

// Screen position of a grid cell
int gridX(int cell){ return margin + boxSizeX*cell; }
int gridY(int cell){ return margin + boxSizeX*cell; }

void setGUI(){
  // SCALE: chromatic or one of the seven modes
  scaleButtons = addButtonRow("SCALE", scaleNames, gridX(0), gridY(row1), boxSizeX*3-buttonSpacing);

  // ROOT: the note the scale starts from
  rootButtons = addButtonRow("ROOT", noteNames, gridX(0), gridY(row2), 30);

  scaleButtons.activate(currentScale);
  rootButtons.activate(root);

  // OCT LOW / OCT HIGH: knobs that click between the 8 octaves (0-7).
  // They sit under the SPEED knob, lined up with the right border.
  knobLow = addOctaveKnob("LOW", lowestOctave, gridX(23));
  knobHigh = addOctaveKnob("HIGH", highestOctave, gridX(26));

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

// A knob from 0 to 7 that snaps to whole octaves.
// 7 tick marks split the knob into 7 steps, which gives 8 positions.
Knob addOctaveKnob(String name, int value, int x){
  Knob k = cp5.addKnob(name)
               .setBroadcast(false)
               .setRange(0,7)
               .setNumberOfTickMarks(7)
               .snapToTickMarks(true)
               .setValue(value)
               .setDecimalPrecision(0)
               .setColorBackground(backgroundColor)
               .setColorActive(activeColor)
               .setColorForeground(foregroundColor)
               .setPosition(x, gridY(row2))
               .setRadius(boxSizeX)
               .setBroadcast(true)
               ;
  k.getCaptionLabel().setVisible(false);
  return k;
}

// A row of buttons where only one can be selected, two cells tall
RadioButton addButtonRow(String name, String[] labels, int x, int y, int buttonWidth){
  RadioButton r = cp5.addRadioButton(name)
         .setPosition(x, y)
         .setSize(buttonWidth, boxSizeX*2)
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

// ROOT buttons: rebuild the particles for the new root
void ROOT(int a){
  if (a < 0) return;
  root = a;
  makeParticles();
}

// SPEED knob: 0 is 10 times slower, 100 is 10 times faster.
// The scale is exponential so small speeds are easy to set.
void SPEED(float theValue){
  speed = 0.0002 * pow(10, (theValue-50)/50);
}

// OCT LOW knob: if it goes above OCT HIGH, OCT HIGH turns with it
void LOW(float theValue){
  int octave = round(theValue);
  if (octave == lowestOctave) return;
  lowestOctave = octave;
  if (highestOctave < lowestOctave){
    highestOctave = lowestOctave;
    knobHigh.setValue(highestOctave);
  }
  makeParticles();
}

// OCT HIGH knob: if it goes below OCT LOW, OCT LOW turns with it
void HIGH(float theValue){
  int octave = round(theValue);
  if (octave == highestOctave) return;
  highestOctave = octave;
  if (lowestOctave > highestOctave){
    lowestOctave = highestOctave;
    knobLow.setValue(lowestOctave);
  }
  makeParticles();
}

// Title and labels, each label in the band above its controls
void displayText(){
  textAlign(LEFT);
  fill(255);
  textSize(20);
  text("MUSICAL_CIRCLE", gridX(0), gridY(titleRow+1)-5);
  textSize(8);
  text("SCALE", gridX(0), gridY(row1)-8);
  text("SPEED", gridX(26), gridY(row1)-8);
  text("ROOT", gridX(0), gridY(row2)-8);
  text("OCT LOW", gridX(23), gridY(row2)-8);
  text("OCT HIGH", gridX(26), gridY(row2)-8);
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
  int[] rows = {titleRow+1, row1Label+1, row1+2, row2Label+1, row2+2};
  for (int r : rows){
    line(0, gridY(r), width, gridY(r));
  }
}
