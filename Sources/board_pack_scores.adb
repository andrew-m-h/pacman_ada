package body Board_Pack_Scores is

   ------------------
   -- Check_Writes --
   ------------------

   procedure Check_Writes (W : Window; Callbacks : in out Score_Callbacks) is
   begin
      for S in Score_Callback_Entry loop
         if Callbacks (S).Action = Write then
            Add (Win    => W,
                 Line   => Line_Position (Callbacks (S).Pos.Y),
                 Column => Column_Position (Callbacks (S).Pos.X),
                 Str    => Callbacks (S).Str,
                 Len    => Callbacks (S).Length);
            Callbacks (S).Action := Wipe;
         end if;
      end loop;
   end Check_Writes;

   function Get_Fill_String (M : Maze; X : Board_Width; Y : Board_Height) return String is
      Str : String := M.Maze_Str (Y)(X .. Board_Width'Last);
   begin
      for I in Natural range 0 .. Board_Width'Last - X loop
         if (M.Maze_Str (Y)(X + I) = '.' or else M.Maze_Str (Y)(X + I) = 'o')
           and then M.Cells (X + I, Y).Contents = Maze_Pack.None
         then
            Str (I + Str'First) := ' ';
         end if;
      end loop;
      return Str;
   end Get_Fill_String;

   -----------------
   -- Check_Wipes --
   -----------------

   procedure Check_Wipes (W : Window; M : Maze; Callbacks : in out Score_Callbacks) is
   begin
      for S in Score_Callback_Entry loop
         if Callbacks (S).Action = Wipe then
            declare
               X : constant Board_Width := Callbacks (S).Pos.X;
               Y : constant Board_Height := Callbacks (S).Pos.Y;
               Wipe_Str : constant String := Get_Fill_String (M, X, Y);
            begin
               Add (Win    => W,
                    Line   => Line_Position (Callbacks (S).Pos.Y),
                    Column => Column_Position (Callbacks (S).Pos.X),
                    Str    => Wipe_Str,
                    Len    => Callbacks (S).Length
                   );
               Callbacks (S).Action := Nothing;
            end;

         end if;
      end loop;
   end Check_Wipes;

end Board_Pack_Scores;
