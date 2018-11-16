pragma Task_Dispatching_Policy (FIFO_Within_Priorities);
pragma Queuing_Policy (Priority_Queuing);
pragma Locking_Policy (Ceiling_Locking);

with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Board_Pack;
with System;

with Ghost_Pack; pragma Unreferenced (Ghost_Pack);
with Player; pragma Unreferenced (Player);
with Scatter_Timer; pragma Unreferenced (Scatter_Timer);

with Settings; use Settings;
with Ada.Real_Time; use Ada.Real_Time;

procedure Main is
   pragma Priority (System.Priority'First);

   Fruit_Symbol : constant Attributed_Character := (Ch    => '%',
                                                    Color => 2,
                                                    Attr  => (others => False));

   F : constant Board_Pack.Fruit_Type := (Ch => Fruit_Symbol,
                                          Timeout => Render_Time * 200,
                                          Value => Score'First,
                                          Pos => (18, 23)
                                         );
begin

   Board_Pack.Board.Place_Fruit (F);

exception
   when System_Failure => null;
end Main;
