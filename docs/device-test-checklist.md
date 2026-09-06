# Device test checklist

Run on a physical Android phone before every upload to the Play Console. Ten
minutes; each line is a real regression that shipped once.

1. Cold start with no data: home shows only "New game", no "Continue".
2. New game → Easy: the board renders, tapping a cell then a number fills it.
3. A clashing number turns the cell red and increments "Mistakes".
4. Erase clears the selected cell and the red highlight.
5. Hint: the first one fills a cell for free; the second shows the
   "no hints left" message (chapter 7 replaces it with the ad offer).
6. Press the system back button mid-game: home shows "Continue"; continuing
   restores the grid and the elapsed time keeps counting from where it was.
7. Put the app in the background for one minute and return: the clock did not
   run while hidden.
8. Finish a puzzle: the dialog shows time, mistakes and hints; "Play again"
   starts a new one of the same difficulty; "Home" goes back and "Continue"
   is gone.
9. Statistics show the completed game and the best time.
10. Settings → Português: every screen switches language, including the
    dialog titles; restart the app and the choice persists.
11. Privacy policy → "Open full policy" opens the browser.
12. Rotate the phone on the game screen: nothing is cut off.
