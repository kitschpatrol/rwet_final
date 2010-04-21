ArrayList activeTitles;

Movie[][] genres;
int genreIndex;
int movieIndex;

// we're going to have a precision issue if the value is only 0 - 1024
// normalize
int timeIndex;
int timeMax;
float normalTime;

String currentText;

int fontSize = 1;

void setup() {
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
	timeMax = 1024;
	normalTime = 0.0;
}


void draw() {
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
		println(textWidth(currentText));

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


void keyPressed() {
	// these will eventually be replaced with
	// serial and midi inputs

	// if the key is [1-5], set the genre
	if ((keyCode >= 49) && (keyCode <= 53)) {
		genreIndex = keyCode - 49;
		println(genreIndex);
	}

	// if the key is [a-z], grab a subtitle
	if ((keyCode >= 65) && (keyCode <= 90)) {
		movieIndex = keyCode - 65;
		addText(genreIndex, movieIndex, normalTime);
	}
}


// adds text to the display list
void addText(int _genreIndex, int _movieIndex, float _normalTime) {
	// grab the movie
	Movie tempMovie = genres[_genreIndex][_movieIndex];
	
	// find the closest subtitle
	Subtitle tempSubtitle = tempMovie.getSubtitleAtTime(_normalTime);
	
	// add it to the display list
	activeTitles.add(tempSubtitle.copy());
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