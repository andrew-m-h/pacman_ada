with Settings; use Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Real_Time; use Ada.Real_Time;
with Maze_Pack; use type Maze_Pack.Cell_Contents;

-- @summary
-- Provide an interface for interacting synchronously with the screen.
-- @description
-- The protected object 'Board' shall mediate interactions from all task entities
-- within the system and running on the highest task priority, shall write
-- the board to the screen every 'Render_Time'

package Board_Pack is

   -- Record describing the state of the player 'Pac Man' character on the board
   -- @field Pos The position of the player on the board
   -- @field Current_Direction The current heading of the player
   -- @field Next_Direction The direction to move when it next becomes a valid move.
   -- When a direction key is pressed, the 'Next_Direction' is set to the appropriate value,
   -- this will not be acted on until the direction is a valid move, at which point, Current_Direction
   -- will be set to the value of the Next_Direction and the pacman will change direction accordingly.
   type Player_Data is record
      Pos : Coordinates;
      Current_Direction : Direction := Left;
      Next_Direction : Direction := Left;
   end record;

   -- Record describing the state of the Ghosts
   -- @field Pos The position of a ghost on the board
   -- @field Current_Direction The current heading of the ghost
   -- @field Symbol How the ghost is represented on the board
   type Ghost_Data is record
      Pos : Coordinates;
      Current_Direction : Direction := Left;
      State : Ghost_State := Alive;
      Symbol : Attributed_Character;
   end record;

   -- Type holding the data for all of the ghosts on the board
   type Ghosts_Data is array (Ghost) of Ghost_Data;

   -- Record describing a 'fruit'
   -- @field Ch The character used to represent the fruit on the board
   -- @field Timeout How long the fruit will be on the board for.
   -- @field Value The score the player will get should the fruit be eaten
   -- @field Pos The position of fruit on the board
   type Fruit_Type is record
      Ch : Attributed_Character;
      Timeout : Time_Span;
      Value : Score := Score'First;
      Pos : Coordinates;
   end record;

   -- The current state of the board is described by this enumeration
   -- @value Uninitalised This is the initial value of the board state.
   -- It is unset upon successful completion of the board procedure Initialse
   -- @value Initialised This is the normal execution mode of the board
   -- @value  Failure This is set when an unrecoverable failure has occurred and
   -- all entities calling the object are to be notified by raising a System_Failure
   -- exception.
   type Board_State is (Uninitialised, Initialised, Failure);

   -- Allow for the oscillating size of the player token
   subtype Token_Size is Boolean;
   Small : constant Token_Size := Token_Size'First;
   Large : constant Token_Size := not Small;

   -- Protected object providing synchronous access to the board to be shown on screen
   protected Board is
      -- Execute various screen setup procedures.
      -- Should be called once before any other procedures are called
      entry Initialise;

      -- Specify the player position on the board
      entry Set_Player_Pos (Pos : Coordinates);
      -- Specify a move made by the player (through the keyboard)
      entry Make_Player_Move (Dir : Direction);

      -- Set the ghost position on the baord for a specific ghost
      entry Set_Ghost_Pos (Ghost) (Pos : Coordinates);
      -- Make a move for a specific ghost on the board
      entry Make_Ghost_Move (Ghost) (Dir : Direction);
      -- Change the state of a specific ghost
      entry Set_Ghost_State (Ghost) (S : Ghost_State);
      -- A failure occured somewhere, tell the board
      procedure Set_Failure;

      -- Write the current state of the board to the screen.
      entry Render;

      -- Retrieve the position of the player on the board
      function Get_Player_Pos return Coordinates;
      -- Retrieve the current direction of the player
      function Get_Player_Heading return Direction;

      -- Retrieve the Position of a ghost on the board
      function Get_Ghost_Pos (G : Ghost) return Coordinates;
      -- Retrieve the state of a ghost
      function Get_Ghost_State (G : Ghost) return Ghost_State;
      -- Return a description of the cell currently occupied by ghost G
      function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell;
      -- Return the internal state error state of the board.
      function Get_State return Board_State;

      -- Return the window used to display the board
      function Win return Window;

      -- place a fruit on the board (involves setting up fruit timeout)
      entry Place_Fruit (F : Fruit_Type);
      -- Remove a fruit from board due to a timeout.
      -- Called from a Timing_Event object
      procedure Fruit_Timeout (Event : in out Timing_Event);
   private
      procedure Check_Collision;

      Player : Player_Data;
      Player_Size : Token_Size := Large;
      Ghosts : Ghosts_Data;
      Fruit  : Fruit_Type;
      Fruit_Valid : Boolean := False;
      W : Window := Standard_Window;
      M : Maze_Pack.Maze;
      State : Board_State := Uninitialised;
   end Board;

private

   task Render is
      pragma Priority (10);
   end Render;

   Use_Colour : Boolean;

   type Symbol_Colour is (Player_Colour, Red_Ghost,
                          Blue_Ghost, Orange_Ghost,
                          Pink_Ghost, Zombie_Ghost,
                          Border_Element, Ghost_Error);
   Colour_Pairs : constant array (Symbol_Colour) of Redefinable_Color_Pair :=
     (Player_Colour => 1, Red_Ghost => 2,
      Blue_Ghost => 3, Orange_Ghost => 4,
      Pink_Ghost => 5, Zombie_Ghost => 6,
      Border_Element => 7, Ghost_Error => 8
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

   Ghost_Symbol : constant Attributed_Character := (Ch => 'A',
                                                    Color => Color_Pair'First,
                                                    Attr => (others => False)
                                                   );

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

   Ghosts_Data_Initial : constant Ghosts_Data :=
     (Settings.Red => (Pos => (X => 2, Y => 2),
                       Current_Direction => Left,
                       State => Alive,
                       Symbol => Ghost_Symbol),
      Settings.Blue => (Pos => (X => 28, Y => 10),
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

   Fruit_Timeout_Handler : constant Timing_Event_Handler := Board.Fruit_Timeout'Access;

   Fruit_Timer : Timing_Event;

end Board_Pack;
