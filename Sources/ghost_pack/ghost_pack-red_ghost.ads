private package Ghost_Pack.Red_Ghost is

   task type Red_Ghost_Type is new Ghost_Interface with
      pragma Priority (4);
      overriding entry Set_State (S : Ghost_State);
      overriding entry Set_Position (P : Coordinates);
      overriding entry Which_Ghost (G : out Ghost);
   end Red_Ghost_Type;
   Red_Ghost_Task : aliased Red_Ghost_Type;

   Zombie_Handler : Zombie_Handler_Type;

   Zombie_Timer : Timing_Event;

   Handler : constant Timing_Event_Handler := Zombie_Handler.Handler'Access;

end Ghost_Pack.Red_Ghost;
