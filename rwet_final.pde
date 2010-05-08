import themidibus.*; //Import the library
import processing.serial.*;
import processing.net.*;

Client socketClient;
String data;

Serial serial;  // Create object from Serial class
int[] serialValues = new int[6];
String[] serialStringValues = new String[6];
String serialString;
int pedalValue;
int button0;
int button1;
int button2;
int button3;
int button4;

MidiBus midi;
int midiOffset; // how much to subtract from the midi pitch to get our movie index

ArrayList activeTitles;

Movie[][] genres;
int genreIndex;
int movieIndex;

// we're going to have a precision issue if the value is only 0 - 1024
// normalize
int timeIndex;
int timeMin = 1024;
int timeMax = 0;
float normalTime;


boolean drawInProcessing = false;
String currentText;

int fontSize = 1;

TextToSpeech talker;

void setup() {
  if(drawInProcessing) {
    size(1400, 600);
  }
  else {
    size(100, 100);      
  }
  smooth();

  PFont font = createFont("Courier New.ttf", 16);
  textFont(font, 16);
  textMode(MODEL);
  hint(ENABLE_NATIVE_FONTS);

  activeTitles = new ArrayList();

  // Load the movies, stuff the genres
  genres = new Movie[5][];
  genres[0] = loadMoviesFromDir(sketchPath + "/data/action"); // Action
  genres[1] = loadMoviesFromDir(sketchPath + "/data/comedy"); // Comedy
  genres[2] = loadMoviesFromDir(sketchPath + "/data/horror"); // Horror	
  genres[3] = loadMoviesFromDir(sketchPath + "/data/rom_com"); // Rom Com
  genres[4] = loadMoviesFromDir(sketchPath + "/data/scifi"); // Scifi

  // The volume pot...
  timeIndex = 0;
  normalTime = 0.0;

  talker = new TextToSpeech();
  //talker.say("starting the sub", "Alex", 10);

  // set up the midi keyboard
  MidiBus.list();
  midi = new MidiBus(this, 0, "Java Sound Synthesizer"); 
  midiOffset = 36;

  // set up the serial
  String portName = Serial.list()[0];
  println(portName);
  serial = new Serial(this, portName, 57600);
  serial.bufferUntil(10);

  // set up the socket client to dump in a terminal

}


void draw() {
  if(drawInProcessing) {

    background(100);



    currentText = "";

    // prune the dead ones
    for (int i = activeTitles.size() - 1; i >= 0; i--) {
      Subtitle tempTitle = (Subtitle)activeTitles.get(i);

      if ((millis() - tempTitle.timeAdded) >= (tempTitle.duration * 1000)) {
        activeTitles.remove(i);
        // skip the rest
        continue;
      }

      currentText = tempTitle.title + " " + currentText;
    }

    // draw the text

      // or draw it in rows
    // text(currentText, 0, 0, width, height);

    // grow the text if need be	
    if(currentText.length() > 0) {
      textSize(fontSize);

      // grow the text if need be (changing while to if will animate)
      while (textWidth(currentText) < width) {
        textSize(++fontSize);
      }

      // shrink the text if need be
      while (textWidth(currentText) > width) {
        textSize(--fontSize);	

        // avoid 0 point glitch
        if(fontSize == 0) {
          fontSize = 1;
          textSize(fontSize);
          break;
        }
      }	

      textAlign(RIGHT, CENTER);
      text(currentText, width, height / 2);
    }

    // monitor the current text, send to terminal?
    // if(frameCount % 30 == 0) println(currentText);

    // temporarily use random bullshit for normal time
    //normalTime = random(1);

  }



}


void keyPressed() {
  // these will eventually be replaced with
  // serial and midi inputs

  // if the key is [1-5], set the genre
  if ((keyCode >= 49) && (keyCode <= 53)) {
    setGenre(keyCode - 49);
  }

  // if the key is [a-z], grab a subtitle
  if ((keyCode >= 65) && (keyCode <= 89)) {
    movieIndex = keyCode - 65;
    addText(genreIndex, movieIndex, normalTime);
  }
}


// adds text to the display list, and spits to the socket server
void addText(int _genreIndex, int _movieIndex, float _normalTime) {
  // grab the movie
  Movie tempMovie = genres[_genreIndex][_movieIndex];

  // find the closest subtitle
  Subtitle tempSubtitle = tempMovie.getSubtitleAtTime(_normalTime);

  // add the duration of the existing elements 
  // time left++
  int timeOnTheBoard = 0;
  for (int i = 0; i < activeTitles.size(); i++) {
    timeOnTheBoard += ((Subtitle)activeTitles.get(i)).getTimeLeft();
  }

  //println("Time on the board: " + timeOnTheBoard);

  tempSubtitle.duration += timeOnTheBoard;


  // add it to the display list
  
  if(drawInProcessing) {
    activeTitles.add(tempSubtitle.copy());
  }

  // send it to the command line, do this with respect to time? let the lines flow
  // metrononically and only print text if it happens to show up for that
  // particular time slot?
  // reconnecting each time is obscene... but pipe errors?
  socketClient = new Client(this, "127.0.0.1", 9999);  
  socketClient.write(tempSubtitle.title + "\n");
  socketClient.stop();

  // speak it
  if(random(1) < .5) {
    talker.say(tempSubtitle.title, "Alex", 250);        
  }
  else {
    talker.say(tempSubtitle.title, "Victoria", 250);                
  }
}


// Creates a list of movie objects from a directory of subtitle files.
Movie[] loadMoviesFromDir(String path) {
  String[] filenames = listFileNames(path);	

  Movie[] movies = new Movie[filenames.length];
  for (int i = 0; i < filenames.length; i++) {
    movies[i] = new Movie(path + "/" + filenames[i]);
  }

  return movies;
}


// This function returns all the files in a directory as an array of Strings
// tk hidden file issue
String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } 
  else {
    // If it's not a directory
    return null;
  }
}



void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  movieIndex = pitch - midiOffset;

  println("Movie index: " + movieIndex);

  if((movieIndex >= 0) && (movieIndex <= 24)) {
    addText(genreIndex, movieIndex, normalTime);
  }
  else {
    println("out of range");
  }


  println("Note On:");
  println("Pitch:"+pitch);

  println("------------");
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println("Note Off:");
  println("Pitch:"+pitch);
}


void serialEvent(Serial p) { 
  serialString = trim(p.readString()); 
  serialStringValues = serialString.split(",");

  if (serialStringValues.length == 6) {
    for (int i = 0; i < 6; i++) {
      serialValues[i] = parseInt(serialStringValues[i]);
    }
  }

  pedalValue = serialValues[0];

  // set the min and max for the pedal
  if(pedalValue < timeMin) timeMin = pedalValue;
  if(pedalValue > timeMax) timeMax = pedalValue;

  // set the time from the pedal
  normalTime = map(serialValues[0], timeMin, timeMax,  1, 0);

  //println("Pedal:" + serialValues[0] + " Time: " + normalTime + " Min: " + timeMin + " Max: " + timeMax);

  // set the genre from the buttons
  button0 = serialValues[1];
  button1 = serialValues[2];
  button2 = serialValues[3];
  button3 = serialValues[4];
  button4 = serialValues[5];

  if(button0 == 1) setGenre(0);
  if(button1 == 1) setGenre(1);
  if(button2 == 1) setGenre(2);
  if(button3 == 1) setGenre(3);
  if(button4 == 1) setGenre(4);  


}

void setGenre(int newIndex) {
  println("changing to genre " + newIndex);
  genreIndex = newIndex;
}



