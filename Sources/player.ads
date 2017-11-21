with Settings; use Settings;
with Ada.Real_Time; use Ada.Real_Time;

package Player is

   pragma Elaborate_Body;

   Keypress_Poll_Interval : constant Time_Span := Render_Time;
   Keypress_Poll_Delay : Time := System_Start;

private

   task Player_Task is
      pragma Priority (8);
   end Player_Task;

end Player;
