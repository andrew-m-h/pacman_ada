with Settings; use Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Maze_Pack; use Maze_Pack;

package Board_Pack_Scores is

   type Score_Action is (Write, Wipe, Nothing);

   type Score_Callback is record
      Action : Score_Action;
      Pos : Coordinates;
      Str : String (1 .. 10);
      Length : Natural;
   end record;

   type Score_Callback_Entry is (Score_Red, Score_Blue, Score_Orange, Score_Pink, Score_Fruit);

   type Score_Callbacks is array (Score_Callback_Entry) of Score_Callback;

   procedure Check_Writes (W : Window; Callbacks : in out Score_Callbacks);
   procedure Check_Wipes (W : Window; M : Maze; Callbacks : in out Score_Callbacks);

end Board_Pack_Scores;
