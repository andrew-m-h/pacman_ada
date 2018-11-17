with Board_Pack; use Board_Pack;

package body Fruit_Pack is

   ------------------------
   -- Fruit_Timer_Object --
   ------------------------

   protected body Fruit_Timer_Object is

      -------------------
      -- Fruit_Timeout --
      -------------------

      procedure Fruit_Timeout (Event : in out Timing_Event) is
         pragma Unreferenced (Event);
         F : constant Board_Pack.Fruit_Type := (Ch => Fruit_Symbol,
                                                Timeout => Schedule (Ix).Duration,
                                                Value => Schedule (Ix).Value,
                                                Pos => (18, 23)
                                               );
      begin
         pragma Warnings (Off);
         Board.Place_Fruit (F);
         pragma Warnings (On);

         if Ix < Schedule'Length then
            Ix := Positive'Succ (Ix);

            Set_Handler (Event   => Fruit_Event,
                         At_Time => Schedule (Ix).Start_Time,
                         Handler => Fruit_Timer_Object.Fruit_Timeout'Access);
         end if;
      end Fruit_Timeout;

   end Fruit_Timer_Object;

   E : Timing_Event;

begin
   Fruit_Timer_Object.Fruit_Timeout (E);
end Fruit_Pack;
