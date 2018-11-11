with Ghost_Pack;

package body Scatter_Timer is

   --------------------------
   -- Scatter_Timer_Object --
   --------------------------

   protected body Scatter_Timer_Object is

      ---------------------
      -- Scatter_Timeout --
      ---------------------

      procedure Scatter_Timeout (Event : in out Timing_Event) is
         pragma Unreferenced (Event);

         G : constant Ghost_Pack.Ghost_Array := Ghost_Pack.Ghost_Tasks;
      begin
         case M is
            when Scatter =>
               M := Chase;
            when Chase =>
               M := Scatter;
         end case;

         for C in Ghost loop
            G (C).all.Set_Mode (M);
         end loop;

         Set_Handler (Event   => Scatter_Event,
                      In_Time => Mode_Time,
                      Handler => Scatter_Timer_Object.Scatter_Timeout'Access);
      end Scatter_Timeout;

   end Scatter_Timer_Object;

begin
   Set_Handler (Event   => Scatter_Event,
                In_Time => Mode_Time,
                Handler => Scatter_Timer_Object.Scatter_Timeout'Access);
end Scatter_Timer;
