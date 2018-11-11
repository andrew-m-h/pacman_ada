with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Settings; use Settings;

package Scatter_Timer is

   Mode_Time : constant Time_Span := 40 * Render_Time;

   protected Scatter_Timer_Object is
      procedure Scatter_Timeout (Event : in out Timing_Event);
   private
      M : Ghost_Mode := Scatter;
   end Scatter_Timer_Object;

   Scatter_Event : Timing_Event;
end Scatter_Timer;
