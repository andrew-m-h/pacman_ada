pragma Task_Dispatching_Policy (FIFO_Within_Priorities);
pragma Queuing_Policy (Priority_Queuing);
pragma Locking_Policy (Ceiling_Locking);

with System;

with Ghost_Pack; pragma Unreferenced (Ghost_Pack);
with Player; pragma Unreferenced (Player);
with Scatter_Timer; pragma Unreferenced (Scatter_Timer);
with Fruit_Pack; pragma Unreferenced (Fruit_Pack);

with Settings; use Settings;

procedure Main is
   pragma Priority (System.Priority'First);

begin
   null;
exception
   when System_Failure => null;
end Main;
