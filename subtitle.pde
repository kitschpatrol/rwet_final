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
	Subtitle copy() {
		return new Subtitle(timeStart, timeEnd, title);
	}


  void startTimer() {
    timeAdded = millis();
  }
}