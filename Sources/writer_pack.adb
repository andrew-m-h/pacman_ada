with Ada.Containers; use type Ada.Containers.Count_Type;

package body Writer_Pack is

   ------------------
   -- Get_Priority --
   ------------------

   function Get_Priority (W : Writer_Job) return Priority is (W.P);

   ------------
   -- Before --
   ------------

   function Before (L, R : Priority) return Boolean is (L < R);

   ---------
   -- Add --
   ---------

   procedure Add
     (W : Window;
      Line : Line_Position;
      Column : Column_Position;
      Ch : Attributed_Character;
      P : Priority := Priority'First;
      Wt : in out Writer)
   is
      Job : constant Writer_Job :=
        (W      => W,
         Line   => Line,
         Column => Column,
         Ch     => Ch,
         P      => P);

   begin
      Wt.Enqueue (Job);
   end Add;

   --------------------
   -- Perform_Writes --
   --------------------

   procedure Perform_Writes (Wt : in out Writer) is
   begin
      while Wt.Current_Use > 0 loop
         declare
            Job : Writer_Job;
         begin
            Wt.Dequeue (Job);
            Add (Win    => Job.W,
                 Line   => Job.Line,
                 Column => Job.Column,
                 Ch     => Job.Ch);
         end;
      end loop;
   end Perform_Writes;

   package body Scores is

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

      -- Generate the string used to fill in a
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

   end Scores;

end Writer_Pack;
