with Ghost_Pack;

package body Scatter_Timer is

   --------------------------
   -- Scatter_Timer_Object --
   --------------------------

   protected body Scatter_Timer_Object is

      procedure Scatter_Timeout (Event : in out Timing_Event) is
         pragma Unreferenced (Event);

         G : constant Ghost_Pack.Ghost_Array := Ghost_Pack.Ghost_Tasks;
      begin

         for C in Ghost loop
            G (C).all.Set_Mode (M);
         end loop;

         if Ix <= Schedule'Length then
            Set_Handler (Event   => Scatter_Event,
                         In_Time => Schedule (Ix),
                         Handler => Scatter_Timer_Object.Scatter_Timeout'Access);
            Ix := Positive'Succ (Ix);
         end if;

         case M is
            when Scatter =>
               M := Chase;
            when Chase =>
               M := Scatter;
         end case;

      end Scatter_Timeout;

   end Scatter_Timer_Object;

begin
   Scatter_Timer_Object.Scatter_Timeout (Scatter_Event);
end Scatter_Timer;
