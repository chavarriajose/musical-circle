// A Particle represents one musical note. It sits at a fixed angle around
// the circle and moves in and out from the center, playing its note
// every time it passes through the base circle.

class Particle{
  PVector pos;      // Current position, relative to the center
  float circle;     // Current distance from the center
  int id;           // MIDI note number, also sets the angle and speed
  float rad;        // Size of the particle when drawn
  int circleBase;   // Radius of the base circle where notes are triggered
  boolean notePressed; // True while the note is playing
  int channel;      // MIDI channel
  int pitch;        // MIDI note to play
  int velocity;     // How hard the note is played (0-127)

  Particle(int nID){
    id = nID;

    pos = new PVector(0,0);

    circleBase = circleRadius;
    rad = 2;
    notePressed = false;
    channel = 0;
    pitch = id;
    velocity = 127;
  }

  // Distance from the center at the current phase. Every particle uses the
  // same shared phase, multiplied by id so higher notes move faster and
  // the particles fall in and out of sync.
  void move(){
    circle = circleBase + (circleBase*0.5)*sin(phase*id);

    // Convert the distance and the note's angle to x, y coordinates
    pos.x = circle*cos(1*radians(map(id,21,108, 0, 360)));
    pos.y = circle*sin(1*radians(map(id,21,108, 0, 360)));
  }

  boolean onBaseCircle(){
    // The window is 1/15 of the radius (10px on the original 150px circle),
    // so the timing stays the same at any size
    float window = circleBase/15.0;
    return circle < circleBase+window && circle > circleBase-window;
  }

  // Place a particle that is added while the others are already moving.
  // If it starts on the base circle it counts as already played, so it
  // waits for its next crossing instead of playing out of time.
  void join(){
    move();
    notePressed = onBaseCircle();
  }

  void update(){
    move();

    // Near the base circle: play the note once (note on)
    if (onBaseCircle()){
      if (notePressed == false){
        notePressed = true;
        myBus.sendNoteOn(channel, pitch, velocity);
      }
    }
    // Away from the base circle: release the note (note off)
    else{
      if (notePressed == true){
        notePressed = false;
        myBus.sendNoteOff(channel, pitch, velocity);
      }
    }
  }
}
