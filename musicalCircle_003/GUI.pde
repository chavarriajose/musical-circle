/**
 * GUI for Musical Circle.
 *
 * SCALE and ROOT buttons pick the notes, the OCTAVES range sets
 * which octaves play, and the SPEED knob sets how fast the particles move.
 *
 * Each row of controls has a label band on top (one cell) and the
 * controls below (two cells), with guide lines between the bands.
 */

RadioButton scaleButtons;
RadioButton rootButtons;
Range octaveRange;
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
int row2Label = 4;  // ROOT, OCTAVES labels
int row2 = 5;       // ROOT buttons, OCTAVES range (two cells tall)
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

  // OCTAVES: one range with a low and a high handle, 0 to 7.
  // Each handle is one cell, and each octave step is one cell,
  // so whole octaves line up with the grid.
  octaveRange = cp5.addRange("OCTAVES")
               .setBroadcast(false)
               .setPosition(gridX(19), gridY(row2))
               .setSize(boxSizeX*9, boxSizeX*2)
               .setHandleSize(boxSizeX)
               .setRange(0,7)
               .setRangeValues(lowestOctave, highestOctave)
               .setDecimalPrecision(0)
               .setColorBackground(backgroundColor)
               .setColorActive(activeColor)
               .setColorForeground(foregroundColor)
               .setBroadcast(true)
               ;
  octaveRange.getCaptionLabel().setVisible(false);

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

// The OCTAVES range sends its low and high values here.
// They are rounded to whole octaves, and the particles are
// only rebuilt when one of them actually changes.
void controlEvent(ControlEvent theEvent){
  if (theEvent.isFrom("OCTAVES")){
    int low = round(octaveRange.getLowValue());
    int high = round(octaveRange.getHighValue());
    if (low != lowestOctave || high != highestOctave){
      lowestOctave = low;
      highestOctave = high;
      makeParticles();
    }
  }
}

// controlP5 can't snap a Range to whole numbers, so once the mouse is
// released, move the handles to the octaves that are playing.
void snapOctaveRange(){
  if (mousePressed) return;
  if (octaveRange.getLowValue() != lowestOctave || octaveRange.getHighValue() != highestOctave){
    octaveRange.setBroadcast(false);
    octaveRange.setRangeValues(lowestOctave, highestOctave);
    octaveRange.setBroadcast(true);
  }
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
  text("OCTAVES", gridX(19), gridY(row2)-8);
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
