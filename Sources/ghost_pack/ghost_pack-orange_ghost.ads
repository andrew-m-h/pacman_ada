with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ghost_Pack.Util; use Ghost_Pack.Util;

private package Ghost_Pack.Orange_Ghost is

   task type Orange_Ghost_Type is new Ghost_Interface with
      pragma Priority (6);
      overriding entry Set_State (S : Ghost_State);
      overriding entry Set_Position (P : Coordinates);
      overriding entry Which_Ghost (G : out Ghost);
      overriding entry Set_Mode (M : Ghost_Mode);
   end Orange_Ghost_Type;

   Orange_Ghost_Task : aliased Orange_Ghost_Type;

   Zombie_Handler : Zombie_Handler_Type;

   Zombie_Timer : Timing_Event;

   Handler : constant Timing_Event_Handler := Zombie_Handler.Handler'Access;

   Generator : Random_Direction.Generator;

end Ghost_Pack.Orange_Ghost;
