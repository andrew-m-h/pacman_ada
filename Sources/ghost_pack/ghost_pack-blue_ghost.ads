private package Ghost_Pack.Blue_Ghost is

   task type Blue_Ghost_Type is new Ghost_Interface with
      pragma Priority (5);
      overriding entry Set_State (S : Ghost_State);
      overriding entry Set_Position (P : Coordinates);
      overriding entry Which_Ghost (G : out Ghost);
      overriding entry Set_Mode (M : Ghost_Mode);
   end Blue_Ghost_Type;

   Blue_Ghost_Task : aliased Blue_Ghost_Type;

   Zombie_Handler : Zombie_Handler_Type;

   Zombie_Timer : Timing_Event;

   Handler : constant Timing_Event_Handler := Zombie_Handler.Handler'Access;

   Generator : Random_Direction.Generator;
end Ghost_Pack.Blue_Ghost;
