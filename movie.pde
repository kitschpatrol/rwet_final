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
      subtitles[i] = new Subtitle(int(elements[0]), int(elements[1]), elements[2]);
    }

    timeStart = subtitles[0].timeStart;
    timeEnd = subtitles[subtitles.length - 1].timeStart;		

  }


  Subtitle getSubtitleAtTime(float _normalTime) {
    // normal time is a float from 0 to 1
    int targetTime = round(map(_normalTime, 0.0, 1.0, (float)timeStart, (float)timeEnd));

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

