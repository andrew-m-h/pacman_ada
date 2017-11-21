with Settings; use Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Real_Time; use Ada.Real_Time;
with Maze_Pack;

package Board_Pack is
   pragma Elaborate_Body;

   type Token_Size is (Small, Large);

   type Player_Data is record
      Pos : Coordinates := Coordinates_Zero;
      Current_Direction : Direction := Left;
      Next_Direction : Direction := Left;
      Size : Token_Size := Token_Size'Last;
   end record;

   type Ghost_Data is record
      Pos : Coordinates := Coordinates_Zero;
      Current_Direction : Direction := Left;
      State : Ghost_State := Alive;
      Symbol : Attributed_Character;
   end record;

   Ghost_Symbol : constant Attributed_Character := (Ch => 'A',
                                                    Color => Color_Pair'First,
                                                    Attr => (others => False)
                                                   );

   type Ghosts_Data is array (Ghost) of Ghost_Data;
   Ghosts_Data_Initial : constant Ghosts_Data :=
     (Settings.Red => (Pos => (X => 2, Y => 2),
                       Current_Direction => Left,
                       State => Alive,
                       Symbol => Ghost_Symbol),
      Settings.Blue => (Pos => (X => 30, Y => 10),
                        Current_Direction => Right,
                        State => Alive,
                        Symbol => Ghost_Symbol),
      Settings.Pink => (Pos => (X => 28, Y => 30),
               Current_Direction => Up,
               State => Alive,
               Symbol => Ghost_Symbol),
      Settings.Orange => (Pos => (X => 10, Y => 28),
                 Current_Direction => Down,
                 State => Alive,
                 Symbol => Ghost_Symbol)
     );

   type Fruit_Type is record
      Ch : Attributed_Character;
      Timeout : Time_Span;
      Pos : Coordinates;
   end record;

   protected Board is
      procedure Initialise;

      procedure Set_Player_Pos (Pos : Coordinates);
      procedure Make_Player_Move (Dir : Direction);

      entry Set_Ghost_Pos (Ghost) (Pos : Coordinates);
      entry Make_Ghost_Move (G : Ghost;
                                 Dir : Direction);
      entry Set_Ghost_State (Ghost) (S : Ghost_State);

      entry Render;

      function Get_Player_Pos return Coordinates;

      function Get_Ghost_Pos (G : Ghost) return Coordinates;
      function Get_Ghost_State (G : Ghost) return Ghost_State;
      function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell;

      function Win return Window;

      procedure Place_Fruit (F : Fruit_Type);
      procedure Fruit_Timeout (Event : in out Timing_Event);
   private
      Player : Player_Data;
      Ghosts : Ghosts_Data := Ghosts_Data_Initial;
      Fruit  : Fruit_Type;
      Fruit_Valid : Boolean := False;
      W : Window;
      M : Maze_Pack.Maze;
   end Board;

private

   function Switch (T : Token_Size) return Token_Size
     with Inline_Always;

   task Render is
      pragma Priority (10);
   end Render;

   Use_Colour : Boolean;

   type Symbol_Colour is (Player_Colour, Red_Ghost,
                          Blue_Ghost, Orange_Ghost,
                          Pink_Ghost, Zombie_Ghost,
                          Border_Element);
   Colour_Pairs : constant array (Symbol_Colour) of Redefinable_Color_Pair :=
     (Player_Colour => 1, Red_Ghost => 2,
      Blue_Ghost => 3, Orange_Ghost => 4,
      Pink_Ghost => 5, Zombie_Ghost => 6,
      Border_Element => 7
     );

   Zombie_Colour : constant Color_Number := 239;
   Orange_Ghost_Colour : constant Color_Number := 129;
   Pink_Ghost_Colour : constant Color_Number := 63;
   Blue_Ghost_Colour : constant Color_Number := 174;

   subtype RGB_Colour is RGB_Value range 0 .. 1000;
   procedure Init_Colour (Colour : Color_Number;
                          R      : RGB_Colour;
                          G      : RGB_Colour;
                          B      : RGB_Colour)
     with Inline_Always;

   Pipe : constant Attributed_Character := (Ch => '|',
                                            Color => Color_Pair'First,
                                            Attr => (others => False)
                                           );
   Bar : constant Attributed_Character := (Ch => '-',
                                           Color => Color_Pair'First,
                                           Attr => (others => False)
                                          );
   Pacman_Large : constant Attributed_Character := (Ch => 'C',
                                                    Color => Colour_Pairs (Player_Colour),
                                                    Attr => (others => False)
                                                   );
   Pacman_Small : constant Attributed_Character := (Ch => 'c',
                                                    Color => Colour_Pairs (Player_Colour),
                                                    Attr => (others => False)
                                                   );
   Space : constant Attributed_Character := (Ch => ' ',
                                             Color => Color_Pair'First,
                                             Attr => (others => False)
                                            );
   Dot : constant Attributed_Character := (Ch => '.',
                                           Color => Color_Pair'First,
                                           Attr => (others => False)
                                          );
   Pill : constant Attributed_Character := (Ch => 'o',
                                            Color => Color_Pair'First,
                                            Attr => (others => False)
                                           );

   Fruit_Timeout_Handler : constant Timing_Event_Handler := Board.Fruit_Timeout'Access;

   Fruit_Timer : Timing_Event;

end Board_Pack;
