with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Settings; use Settings;

package Scatter_Timer is

   Schedule : constant array (Positive range <>) of Time_Span :=
     (Seconds (7), Seconds (20), Seconds (7), Seconds (20),
      Seconds (5), Seconds (20), Seconds (5));

   protected Scatter_Timer_Object is
      procedure Scatter_Timeout (Event : in out Timing_Event);
   private
      M : Ghost_Mode := Scatter;
      Ix : Positive := Positive'First;
   end Scatter_Timer_Object;

private

   Scatter_Event : Timing_Event;
end Scatter_Timer;
