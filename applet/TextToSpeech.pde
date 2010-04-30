/**
 * Text to Speech
 * 
 * Author: Denis Meyer (CallToPower)
 */
import java.io.IOException;

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

