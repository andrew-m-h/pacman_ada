with Ghost_Abstract; use Ghost_Abstract;
with Settings; use Settings;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

package Ghost_Pack is

   type Ghost_Array is array (Ghost) of Ghost_Type;

   function Ghost_Tasks return Ghost_Array
     with Inline_Always;

private

   type System_Mode_Type is (Normal_Mode, Safe_Mode);

   Ghost_Render_Timeout : exception;

   Ghost_Deadline : constant Time_Span := Render_Time - Milliseconds (5);
   Ghost_Wait_Time : constant Time_Span := Milliseconds (5);

   protected type Zombie_Handler_Type is

      procedure Check (Happened : out Boolean);

      procedure Handler (Event : in out Timing_Event);

   private
      Timeout_Occurred : Boolean := False;
   end Zombie_Handler_Type;

   Zombie_Time_Out : constant Time_Span := Render_Time * 10;

   function Distance_Square (A, B : Coordinates) return Natural;

end Ghost_Pack;
