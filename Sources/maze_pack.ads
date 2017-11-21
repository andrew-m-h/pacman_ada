with Settings; use Settings;

package Maze_Pack is

   type Cell_Contents is (None, Dot, Pill);

   type Maze_Cell is record
      Up, Down, Left, Right : Boolean := False;
      Contents : Cell_Contents := None;
   end record;

   type Maze_Cells is array (Board_Width, Board_Height) of Maze_Cell;

   type Ghost_Locations is array (Ghost) of Coordinates;

   type Maze_String is array (Board_Height) of String (Board_Width);

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

   procedure Read_Maze (Filename : String; M : out Maze);

   Parse_Error : exception;

private

   function Is_Border_Char (Ch : Character) return Boolean;
   function Get_Contents (Ch : Character) return Cell_Contents;
end Maze_Pack;
