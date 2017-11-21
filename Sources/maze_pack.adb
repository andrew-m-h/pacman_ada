with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;

package body Maze_Pack is

   package Dim_IO is new Ada.Text_IO.Integer_IO (Board_Dimension);

   ---------------
   -- Read_Maze --
   ---------------

   procedure Read_Maze (Filename : String; M : out Maze) is
      File : File_Type;
      Ch : Character;
   begin
      Open (File => File,
            Mode => In_File,
            Name => Filename);

      -- Get Width and Height
      Dim_IO.Get (File, M.Maze_Width);
      Get (File, Ch);
      Assert (Ch = 'x', "Parse Error: Board Width");
      Dim_IO.Get (File, M.Maze_Height);

      -- Get Player Position
      Dim_IO.Get (File, M.Initial_Player_Pos (X));
      Get (File, Ch);
      Assert (Ch = ',', "Parse Error: Player Position");
      Dim_IO.Get (File, M.Initial_Player_Pos (Y));

      -- Get Initial Ghost Position
      declare
         Dim_X, Dim_Y : Board_Dimension;
      begin
         Dim_IO.Get (File, Dim_X);
         Get (File, Ch);
         Assert (Ch = ',', "Parse Error: Ghost Position");
         Dim_IO.Get (File, Dim_Y);

         for G in Ghost loop
            M.Initial_Ghost_Pos (G)(X) := Dim_X;
            M.Initial_Ghost_Pos (G)(Y) := Dim_Y;
         end loop;
      end;

      Skip_Line (File);
      declare
         Last : Natural;
      begin
         for Y in Board_Height'First .. M.Maze_Height loop
            Get_Line (File => File,
                      Item => M.Maze_Str (Y),
                      Last => Last);
         end loop;
      end;

      for Y in Board_Height'First .. M.Maze_Height loop
         for X in Board_Width'First .. M.Maze_Width loop
            M.Cells (X, Y) := (Up => (if Y > Board_Height'First then
                                         not Is_Border_Char (M.Maze_Str (Y - 1)(X))
                                      else False),
                               Down => (if Y < M.Maze_Height then
                                          not Is_Border_Char (M.Maze_Str (Y + 1)(X))
                                        else False),
                               Left => (if X > Board_Width'First then
                                          not Is_Border_Char (M.Maze_Str (Y) (X - 1))
                                        else False),
                               Right => (if X < M.Maze_Width then
                                           not Is_Border_Char (M.Maze_Str (Y) (X + 1))
                                         else False),
                               Contents => Get_Contents (M.Maze_Str (Y) (X))
                              );
         end loop;
      end loop;

   end Read_Maze;

   function Is_Border_Char (Ch : Character) return Boolean is
   begin
      case Ch is
         when '-' => return True;
         when '+' => return True;
         when '|' => return True;
         when '=' => return True;
         when others => return False;
      end case;
   end Is_Border_Char;

   function Get_Contents (Ch : Character) return Cell_Contents is
   begin
      case Ch is
         when '.' => return Dot;
         when 'o' => return Pill;
         when others => return None;
      end case;
   end Get_Contents;
end Maze_Pack;
