with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Settings; use Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package Fruit_Pack is
   pragma Elaborate_Body;

   -- Record describing a 'fruit time' (when a fruit should appear, for how long and its point value)
   -- @field Start_Time The time at which the fruit should appear
   -- @field Duration For how long the fruit should remain on the board
   -- @field Value The score the player will get should the fruit be eaten
   type Fruit_Time is record
      Start_Time : Time;
      Duration   : Time_Span;
      Value      : Score;
   end record;

   Schedule : constant array (Positive range <>) of Fruit_Time :=
     ((System_Start, Seconds (7), 1), (System_Start + Seconds (7), Seconds (3), 2));

   Fruit_Symbol : constant Attributed_Character := (Ch    => '%',
                                                    Color => 2,
                                                    Attr  => (others => False));

   -- Protected object used to set the modes of each ghost upon a timer signal.
   protected Fruit_Timer_Object is
      procedure Fruit_Timeout (Event : in out Timing_Event);
   private
      Fruit_Running : Boolean := False;
      Ix : Positive := Positive'First;
   end Fruit_Timer_Object;

private

   Fruit_Event : Timing_Event;

end Fruit_Pack;
