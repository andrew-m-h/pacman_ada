with Settings; use Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Real_Time; use Ada.Real_Time;
with Maze_Pack; use type Maze_Pack.Cell_Contents;
with Writer_Pack; use Writer_Pack;

-- @summary
-- Provide an interface for interacting synchronously with the screen.
-- @description
-- The protected object 'Board' shall mediate interactions from all task entities
-- within the system and running on the highest task priority, shall write
-- the board to the screen every 'Render_Time'

package Board_Pack is
   pragma Elaborate_Body;

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
   -- @field State State describing if ghosts are either alive, dead or zombified
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
      Value : Score := 1;
      Pos : Coordinates;
   end record;

   -- The current state of the board is described by this enumeration
   -- @value Uninitialised This is the initial value of the board state.
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
      -- @param Pos Position of the player
      entry Set_Player_Pos (Pos : Coordinates);
      -- Specify a move made by the player (through the keyboard)
      -- @param Dir Direction the player shall move (if valid)
      entry Make_Player_Move (Dir : Direction);

      -- Set the ghost position on the baord for a specific ghost
      -- @param Pos Position to set the ghost to
      entry Set_Ghost_Pos (Ghost) (Pos : Coordinates);
      -- Make a move for a specific ghost on the board
      -- @param Dir Direction the ghosts shall move (if valid)
      entry Make_Ghost_Move (Ghost) (Dir : Direction);
      -- Change the state of a specific ghost
      -- @param S The state of the ghosts
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
      -- @param G Ghost whose position is to be returned
      function Get_Ghost_Pos (G : Ghost) return Coordinates;
      -- Retrieve the state of a ghost
      -- @param G Ghost whose state is to be returned
      function Get_Ghost_State (G : Ghost) return Ghost_State;
      -- Return a description of the cell currently occupied by ghost G
      -- @param G Ghost whose cell state is to be returned
      function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell;
      -- Return the internal state error state of the board.
      function Get_State return Board_State;

      -- Return the window used to display the board
      function Win return Window;

      -- place a fruit on the board (involves setting up fruit timeout)
      -- @param F Fruite to be placed
      entry Place_Fruit (F : Fruit_Type);
      -- Remove a fruit from board due to a timeout.
      -- Called from a Timing_Event object
      -- @param Event Timing event which caused the timeout
      procedure Fruit_Timeout (Event : in out Timing_Event);
   private
      procedure Check_Collision;
      -- reset since player ate all pills
      procedure Restart_Board;
      -- reset since player died (but didn't eat all pills)
      procedure Reset_Board;

      Player : Player_Data;
      Player_Score : Score := Score'First;
      Player_Size : Token_Size := Large;
      Ghosts : Ghosts_Data;
      Fruit  : Fruit_Type;
      Fruit_Valid : Boolean := False;
      W : Window := Standard_Window;
      M : Maze_Pack.Maze;
      State : Board_State := Uninitialised;
      -- The render cycle can be 'paused' until
      -- Pause_Countdown = 0
      Pause_Countdown : Natural := Natural'First;
      Callbacks : Scores.Score_Callbacks
        := (others => (Action => Scores.Nothing,
                       Pos => (Board_Width'First, Board_Height'First),
                       Str => (others => ' '),
                       Length => Natural'First
                      ));
   end Board;

private

   task Render is
      pragma Priority (10);
   end Render;

   Use_Colour : Boolean := Boolean'Invalid_Value;

   -- Type representing the symbol colours
   -- These are mapped to Redefinable_Color_Pairs which allow easy setting of colours
   -- @value Player_Colour Colour of the player Icon (yellow if possible)
   -- @value Red_Ghost Colour of the red ghost (red if possible)
   -- @value Blue_Ghost Colour of the blue ghost (blue if possible)
   -- @value Orange_Ghost Colour of the orange ghost (orange if possible)
   -- @value Pink_Ghost Colour of the pink ghost (pink if possible)
   -- @value Zombie_Ghost Colour of the zombie ghosts (dark blue if possible)
   -- @value Border_Element Colour of the borders of the maze
   -- @value Ghost_Error Colour of the ghosts when an error has occurred
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

   -- A call to adacurses Init_Color (americanized spelling) which adds bounds checking
   -- on the RGB_Colour values. These are allowed to be 2 bytes long, but are only valid in
   -- the range 0 .. 1000.
   -- @param Colour The colour_number to assign the new colour to
   -- @param R Red RGB value
   -- @param G Green RGB value
   -- @param B Blue RGB value
   procedure Init_Colour (Colour : Color_Number;
                          R      : RGB_Colour;
                          G      : RGB_Colour;
                          B      : RGB_Colour)
     with Inline;

   -- Symbols used by the program to represent various items
   Ghost_Symbol : constant Attributed_Character := (Ch => 'A',
                                                    Color => Color_Pair'First,
                                                    Attr => (others => False)
                                                   );
   Ghost_Dead : constant Attributed_Character   := (Ch => '"',
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
   Death : constant Attributed_Character := (Ch => '*',
                                             Color => Colour_Pairs (Player_Colour),
                                             Attr => (others => False)
                                            );
   -- Initial settings for the ghosts
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
      Settings.Orange => (Pos => (X => 10, Y => 29),
                 Current_Direction => Down,
                 State => Alive,
                 Symbol => Ghost_Symbol)
     );

   Fruit_Timeout_Handler : constant Timing_Event_Handler := Board.Fruit_Timeout'Access;

   Fruit_Timer : Timing_Event;

   Wt : Writer;

   Player_Dead : exception;

end Board_Pack;
