with Settings; use Settings;
with Ada.Real_Time; use Ada.Real_Time;

package Player is

   pragma Elaborate_Body;

   -- How often to sample for keypresses using the non-blocking
   -- Get_Keystroke function.
   Keypress_Poll_Interval : constant Time_Span := Render_Time / 4;

private

   task Player_Task is
      pragma Priority (8);
   end Player_Task;

end Player;
