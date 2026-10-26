// A Particle represents one musical note. It sits at a fixed angle around
// the circle and moves in and out from the center, playing its note
// every time it passes through the base circle.

class Particle{
  PVector pos;      // Current position, relative to the center
  float circle;     // Current distance from the center
  float freq;       // Phase of the oscillation, grows every frame
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

    circleBase = 150;
    rad = 2;
    notePressed = false;
    channel = 0;
    pitch = id;
    velocity = 127;
  }

  void update(){
    // Oscillate around the base circle. Multiplying by id makes higher
    // notes move faster, so the particles fall in and out of sync.
    circle = circleBase + (circleBase*0.5)*sin(freq*id);

    // Near the base circle: play the note once (note on)
    if (circle < circleBase+10 && circle > circleBase-10){
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

    // Convert the distance and the note's angle to x, y coordinates
    pos.x = circle*cos(1*radians(map(id,21,108, 0, 360)));
    pos.y = circle*sin(1*radians(map(id,21,108, 0, 360)));

    // Advance the oscillation
    freq += speed;
  }
}
