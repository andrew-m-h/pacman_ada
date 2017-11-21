with Ghost_Pack.Red_Ghost;
with Ghost_Pack.Blue_Ghost;
with Ghost_Pack.Orange_Ghost;
with Ghost_Pack.Pink_Ghost;

package body Ghost_Pack is

   function Ghost_Tasks return Ghost_Array is ((Red => Ghost_Pack.Red_Ghost.Red_Ghost_Task'Access,
                                                Blue => Ghost_Pack.Blue_Ghost.Blue_Ghost_Task'Access,
                                                Orange => Ghost_Pack.Orange_Ghost.Orange_Ghost_Task'Access,
                                                Pink => Ghost_Pack.Pink_Ghost.Pink_Ghost_Task'Access
                                               ));

   protected body Zombie_Handler_Type is
      procedure Check (Happened : out Boolean) is
      begin
         Happened := Timeout_Occurred;
         Timeout_Occurred := False;
      end Check;

      procedure Handler (Event : in out Timing_Event) is
         pragma Unreferenced (Event);
      begin
         Timeout_Occurred := True;
      end Handler;
   end Zombie_Handler_Type;

   function Distance_Square (A, B : Coordinates) return Natural is
      DX : constant Integer := Integer (A (X)) - Integer (B (X));
      DY : constant Integer := Integer (A (Y)) - Integer (B (Y));
   begin
      return Natural (abs (DX * DX + DY * DY));
   end Distance_Square;

end Ghost_Pack;
