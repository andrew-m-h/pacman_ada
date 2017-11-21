with Settings; use Settings;
with Maze_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package Board_Abstract is
   
   type Fruit_Type is record
      Ch : Attributed_Character;
      Timeout : Time_Span;
      Pos : Coordinates;
   end record;

   type Board_Type is protected interface;
   
   procedure Set_Player_Pos (B : in out Board_Type;
                             Pos : Coordinates) is Abstract;
   procedure Make_Player_Move (B : in out Board_Type;
                               Dir : Direction) is abstract;
   
   procedure Set_Ghost_Pos (B : in out Board_Type;
                            G : Ghost;
                            Pos : Coordinates) is abstract;
   procedure Make_Ghost_Move (B : in out Board_Type;
                              G : Ghost;
                              Dir : Direction) is abstract;
   procedure Set_Ghost_State (B : in out Board_Type;
                              G : Ghost;
                              S : Ghost_State) is abstract;
   
   function Get_Player_Pos return Coordinates is abstract;

   function Get_Ghost_Pos (G : Ghost) return Coordinates is abstract;
   function Get_Ghost_State (G : Ghost) return Ghost_State is abstract;
   function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell is abstract;
   
   function Win return Window is abstract;
   
   
   procedure Place_Fruit (B : in out Board_Type;
                          F : Fruit_Type) is abstract;

   type Board_Access is access all Board_Type'Class;
   
end Board_Abstract;
