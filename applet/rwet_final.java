import processing.core.*; 
import processing.xml.*; 

import themidibus.*; 
import processing.serial.*; 
import java.io.IOException; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class rwet_final extends PApplet {

 //Import the library



Serial serial;  // Create object from Serial class
int[] serialValues = new int[6];
String[] serialStringValues = new String[6];
String serialString;

MidiBus midi;
int midiOffset; // how much to subtract from the midi pitch to get our movie index

ArrayList activeTitles;

Movie[][] genres;
int genreIndex;
int movieIndex;

// we're going to have a precision issue if the value is only 0 - 1024
// normalize
int timeIndex;
int timeMin;
int timeMax;
float normalTime;

String currentText;

int fontSize = 1;

TextToSpeech talker;

public void setup() {
  size(1400, 600);
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
  timeMin = 0;
  timeMax = 1024;
  normalTime = 0.0f;

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

}


public void draw() {
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
  normalTime = random(1);
}


public void keyPressed() {
  // these will eventually be replaced with
  // serial and midi inputs

  // if the key is [1-5], set the genre
  if ((keyCode >= 49) && (keyCode <= 53)) {
    genreIndex = keyCode - 49;

  }

  // if the key is [a-z], grab a subtitle
  if ((keyCode >= 65) && (keyCode <= 90)) {
    movieIndex = keyCode - 65;
    addText(genreIndex, movieIndex, normalTime);
  }
}


// adds text to the display list
public void addText(int _genreIndex, int _movieIndex, float _normalTime) {
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

  println("Time on the board: " + timeOnTheBoard);

  tempSubtitle.duration += timeOnTheBoard;


  // add it to the display list
  activeTitles.add(tempSubtitle.copy());

  // speak it
  if(random(1) < .5f) {
    talker.say(tempSubtitle.title, "Alex", 180);        
  }
  else {
    talker.say(tempSubtitle.title, "Victoria", 180);                
  }
}


// Creates a list of movie objects from a directory of subtitle files.
public Movie[] loadMoviesFromDir(String path) {
  String[] filenames = listFileNames(path);	

  Movie[] movies = new Movie[filenames.length];
  for (int i = 0; i < filenames.length; i++) {
    movies[i] = new Movie(path + "/" + filenames[i]);
  }

  return movies;
}


// This function returns all the files in a directory as an array of Strings
// tk hidden file issue
public String[] listFileNames(String dir) {
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



public void noteOn(int channel, int pitch, int velocity) {
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

public void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println("Note Off:");
  println("Pitch:"+pitch);
}


public void serialEvent(Serial p) { 
  println("serial in");
  serialString = trim(p.readString()); 
  serialStringValues = serialString.split(",");
  
  if (serialStringValues.length == 6) {
    for (int i = 0; i < 6; i++) {
      serialValues[i] = parseInt(serialStringValues[i]);
    }
  }
  
  println(serialValues);
}


/**
 * Text to Speech
 * 
 * Author: Denis Meyer (CallToPower)
 */


/**
 * Text to Speech Class
 */
public class TextToSpeech {

  /* The Mac OS X-Text to Speech-Voices */
  private String[] voices = {
    // male (5/25)
    "Bruce", "Fred", "Junior", "Ralph",
    "Alex",
    // female (5/25)
    "Agnes", "Vickie", "Victoria", "Princess",
    "Kathy",
    // others (15/25)
    "Hysterical", "Cellos", "Trinoids", "Boing", "Deranged",
    "Whisper", "Zarvox", "Good News", "Albert", "Albert",
    "Bells", "Bahh", "Pipe Organ", "Bubbles", "Bad News"   };

  /**
   * 	 * Main-Function (for small Tests)
   * 	 * 
   * 	 * @param args
   * 	 *            Command Line Arguments
   	 */
//  public void main(String[] args) {
//
//  }

  /**
   * 	 * Tests if test is a Voice
   * 	 * 
   * 	 * @param voiceToTest
   * 	 *            Voice to test
   * 	 * @return true if test is a Voice, false else
   	 */
  public boolean isVoice(String voiceToTest) {
    for(int i = 0; i < voices.length; i++) {
      if (voiceToTest.equals(voices[i])) {
        return true;
      }
    }
    return false;
  }

  /**
   * 	 * Returns the Voice-Array
   * 	 * 
   * 	 * @return The Array with the Voices
   	 */
  public String[] getVoices() {
    return voices;
  }

  /**
   * 	 * Returns a Voice
   * 	 * 
   * 	 * @param index
   * 	 *            The Voice at Index index
   * 	 * @return A Voice
   	 */
  public String getVoice(int index) {
    if ((index > 0) && (index < voices.length)) {
      return voices[index];
    }
    return voices[0];
  }

  /**
   * 	 * Text to Speech
   * 	 * 
   * 	 * @param text
   * 	 *            Text to say
   * 	 * @param voice
   * 	 *            Voice
   	 */
  public void say(String text, String voice, int speed) {
    if ((text != null) && (voice != null) && (isVoice(voice))) {
      try {
        Runtime.getRuntime().exec(
        new String[] { 
          "say", "-v", voice, "[[rate " + speed + "]]" + text         }
        );
      } 
      catch (IOException e) {
        System.err.println("IOException");
      }
    } 
    else {
      System.err.println("Exception");
    }
  }
}

class Movie {
  int duration;
  int timeStart;
  int timeEnd;
	String title;
  Subtitle[] subtitles;


	// constructor
  Movie(String file) {
    // load the subtitles
    String[] lines = loadStrings(file);

		// extract the title from the file
		String[] fileComponents = file.split("/");
		String fileName = fileComponents[fileComponents.length - 1];
		title = fileName.substring(0, fileName.length() - 4);

		// build the subtitle list
    subtitles = new Subtitle[lines.length];
    for (int i = 0; i < lines.length; i++) {
      // split on tabs
      String[] elements = lines[i].split("\t");

      // load into a new object
      subtitles[i] = new Subtitle(PApplet.parseInt(elements[0]), PApplet.parseInt(elements[1]), elements[2]);
    }

		timeStart = subtitles[0].timeStart;
		timeEnd = subtitles[subtitles.length - 1].timeStart;		

  }


	public Subtitle getSubtitleAtTime(float _normalTime) {
		// normal time is a float from 0 to 1
		int targetTime = round(map(_normalTime, 0.0f, 1.0f, (float)timeStart, (float)timeEnd));
		
		//println("Normal Time is " + _normalTime);
		//println("Target Time is " + targetTime);		
		
		// start from a  more efficient place than the beginning?
		for (int i = 0; i < subtitles.length; i++) {
			if(subtitles[i].timeStart >= targetTime) {
				return subtitles[i];
			}
		}
		
		println("no match wtf");
		return subtitles[0];
	}

}
class Subtitle {  
  int timeStart;
  int timeEnd;
  int duration;
  String title;
  int timeAdded;


  Subtitle(int _timeStart, int _timeEnd, String _title) {
    timeStart = _timeStart;
    timeEnd = _timeEnd;
    title = _title;
    duration = timeEnd - timeStart;
		timeAdded = millis(); // we only really care about this for display
  }


	// returns a copy of the subtitle, useful when adding to draw lists
	public Subtitle copy() {
		return new Subtitle(timeStart, timeEnd, title);
	}
	
	public int getTimeLeft() {
		return (duration * 1000) - (millis() - timeAdded);
	}


  public void startTimer() {
    timeAdded = millis();
  }
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "rwet_final" });
  }
}
