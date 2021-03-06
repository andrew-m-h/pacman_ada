with Settings; use Settings;
-- @summary
-- Pacman Maze Definitions.
-- @description
-- Provides Maze Type definition which models a pacman maze
-- including Junctions and initial conditions.
package Maze_Pack is

   -- Possible contents of one Cell
   -- @value None When a cell is empty
   -- @value Dot When a cell contains a normal edible dot
   -- @value Pill When a cell contains a Super Pill (turning ghosts into zombies)
   type Cell_Contents is (None, Dot, Pill);

   -- A Cell describes 1 character on the board
   -- @field Up Can move from this cell to the one above
   -- @field Down Can move from this cell to one below
   -- @field Left Can move from this cell to one left
   -- @field Right Can move from this cell to one to right
   -- @field Contents What does this cell contain
   type Maze_Cell is record
      Up, Down, Left, Right : Boolean := False;
      Contents : Cell_Contents := None;
   end record;

   -- A board is a 2 dimensional  array of cells
   type Maze_Cells is array (Board_Width, Board_Height) of Maze_Cell;

   -- Type Used for initial Ghost Positions
   type Ghost_Locations is array (Ghost) of Coordinates;

   -- Describes the board as an array of Row's represented by strings
   type Maze_String is array (Board_Height) of String (Board_Width);

   -- Holds all necessary information about a maze read from file
   -- @field Cells The board encoded as Maze_Cell types interpreted from the Ascii board
   -- @field Maze_Str 2d array of the actual characters which make up the maze
   -- @field Initial_Ghost_Pos the positions of the ghosts for this maze
   -- @field Initial_Player_Pos The position of the player at the start for this maze
   -- @field Maze_Width The width of the maze (in characters)
   -- @field Maze_Height The height of the maze (in characters)
   type Maze is record
      Cells : Maze_Cells := (others => (others =>
                               (Contents => None,
                                others => False)));
      Maze_Str : Maze_String := (others => (others => ' '));
      Initial_Ghost_Pos : Ghost_Locations;
      Initial_Player_Pos : Coordinates;
      Maze_Width : Board_Width;
      Maze_Height : Board_Height;
   end record;

   -- Read a Maze from a given file
   -- @param Filename File to read maze from
   -- @param M Resulting maze will be initialised
   procedure Read_Maze (Filename : String; M : out Maze);

   Parse_Error : exception;
   File_Error : exception;
private
   -- Determine if a charcter is one which forms a boundary for the maze ('|', '+' etc)
   -- @param Ch The character to be determined
   function Is_Border_Char (Ch : Character) return Boolean;

   -- Map characters to Cell_Contents types
   -- @param Ch The character to be mapped to a cell_contents value
   function Get_Contents (Ch : Character) return Cell_Contents;
end Maze_Pack;
