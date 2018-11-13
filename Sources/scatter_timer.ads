with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Settings; use Settings;

-- @summary
-- Gives the timing functionality for Scatter vs Chase in the ghosts
-- @description
-- The Schedule determines the length of each phase, and after the final phase
-- is complete, the ghosts stay on Chase mode.
-- This package should be included by Main and provides a concrete timer
-- to do the mode changes.
package Scatter_Timer is

   -- The schedule of the Scatter - Chase modes for each ghost.
   Schedule : constant array (Positive range <>) of Time_Span :=
     (Seconds (7), Seconds (20), Seconds (7), Seconds (20),
      Seconds (5), Seconds (20), Seconds (5));

   -- Protected object used to set the modes of each ghost upon a timer signal.
   protected Scatter_Timer_Object is
      procedure Scatter_Timeout (Event : in out Timing_Event);
   private
      M : Ghost_Mode := Scatter;
      Ix : Positive := Positive'First;
   end Scatter_Timer_Object;

private

   Scatter_Event : Timing_Event;

end Scatter_Timer;
