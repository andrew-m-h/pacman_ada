package body Board_Pack is
   ---------------------
   -- Render Task --
   ---------------------

   -- Periodical task executing Board.Render every Render_Time on highest priority
   -- shall cease execution upon receiving a system failure exception from Board
   task body Render is
      Delay_Time : Time := System_Start;
   begin
      loop
         Delay_Time := Delay_Time + Render_Time;
         delay until Delay_Time;

         -- Attempt to render, if render is not open after 5ms, revoke call and skip render cycle
         -- in the hopes that it will be open for some future calls
         declare
            Timeout : constant Time := Delay_Time + Milliseconds (5);
         begin
            select
               Board.Render;
            or
               delay until Timeout;
            end select;
         end;
      end loop;

   exception
      when System_Failure => null;
   end Render;

   ---------------------
   -- Board --
   ---------------------
   -- Object mediating interaction with the board and screen from concurrent entities

   protected body Board is

      -- Run initialisation code and set Board in to 'Initialised' state allowing
      -- other entries to be run safely
      entry Initialise
        when State = Uninitialised is
      begin
         Ghosts := Ghosts_Data_Initial;

         -- Initialise screen and curses settings
         Init_Windows;

         W := Standard_Window;

         Set_Echo_Mode (False);
         Set_NoDelay_Mode (W, False);
         Set_Timeout_Mode (W, Non_Blocking, 1);

         Use_Colour := Has_Colors; -- Does the terminal allow displaying colours

         declare
            V : Cursor_Visibility := Invisible;
         begin
            Set_Cursor_Visibility (V);
            pragma Unreferenced (V);
         end;

         -- Initialise the various asset colours used
         if Use_Colour then
            Start_Color;
            Init_Colour (Colour => Zombie_Colour,
                         R      => 0,
                         G      => 0,
                         B      => 1000);
            Init_Colour (Colour => Orange_Ghost_Colour,
                         R      => 1000,
                         G      => 647,
                         B      => 0);
            Init_Colour (Colour => Pink_Ghost_Colour,
                         R      => 1000,
                         G      => 752,
                         B      => 796);
            Init_Colour (Colour => Blue_Ghost_Colour,
                         R      => 678,
                         G      => 847,
                         B      => 901);

            Init_Pair (Pair => Colour_Pairs (Player_Colour),
                       Fore => Yellow,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Red_Ghost),
                       Fore => Terminal_Interface.Curses.Red,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Blue_Ghost),
                       Fore => Blue_Ghost_Colour,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Orange_Ghost),
                       Fore => Orange_Ghost_Colour,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Pink_Ghost),
                       Fore => Pink_Ghost_Colour,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Zombie_Ghost),
                       Fore => Zombie_Colour,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Border_Element),
                       Fore => Green,
                       Back => Black);
            Init_Pair (Pair => Colour_Pairs (Ghost_Error),
                       Fore => Green,
                       Back => Black);
         end if;

         -- Read in board from external file
         Maze_Pack.Read_Maze ("tmp", M);

         -- Draw board on screen
         for Y in Board_Height'First .. M.Maze_Height loop
            Add (Win    => W,
                 Line   => Line_Position (Y),
                 Column => Column_Position (Natural (Board_Width'First)),
                 Str    => M.Maze_Str (Y),
                 Len    => Natural (M.Maze_Width));
         end loop;

         Player.Pos := M.Initial_Player_Pos;

         State := Initialised;

      exception
         when Maze_Pack.File_Error =>
            End_Windows;
            State := Failure;
         when Maze_Pack.Parse_Error =>
            End_Windows;
            State := Failure;
      end Initialise;

      entry Set_Player_Pos (Pos : Coordinates)
        when State /= Uninitialised is
      begin
         case State is
            when Initialised =>
               Player.Pos := Pos;
            when others =>
               raise System_Failure;
         end case;
      end Set_Player_Pos;

      entry Make_Player_Move (Dir : Direction)
        when State /= Uninitialised is
      begin
         case State is
            when Initialised =>
               Player.Next_Direction := Dir;
            when others => raise System_Failure;
         end case;
      end Make_Player_Move;

      entry Set_Ghost_Pos (for G in Ghost) (Pos : Coordinates)
      when State /= Uninitialised is
      begin
         case State is
            when Initialised =>
               Ghosts (G).Pos := Pos;
            when others =>
               raise System_Failure;
         end case;
      end Set_Ghost_Pos;

      entry Make_Ghost_Move (for G in Ghost) (Dir : Direction)
      when State /= Uninitialised is
      begin
         case State is
            when Initialised =>
               Ghosts (G).Current_Direction := Dir;
            when others => raise System_Failure;
         end case;
      end Make_Ghost_Move;

      entry Set_Ghost_State (for G in Ghost) (S : Ghost_State)
      when State /= Uninitialised is
      begin
         case State is
            when Initialised =>
               Ghosts (G).State := S;
               Ghosts (G).Symbol := (if S = Alive then Ghost_Symbol else Ghost_Dead);
            when others =>
               raise System_Failure;
         end case;
      end Set_Ghost_State;

      procedure Set_Failure is
      begin
         State := Failure;
      end Set_Failure;

      entry Render
      -- Run once initialised and there are no ghosts waiting on the make_ghost_move entries
        when State /= Uninitialised
        and then (for all G in Ghost => Board.Make_Ghost_Move (G)'Count = 0) is
      begin

         if State = Failure then
            raise System_Failure;
            -- When paused to eat a fruit, erase the score
         elsif Pause_Countdown > Natural'First then
            Pause_Countdown := Natural'Pred (Pause_Countdown);
         else
            -- Check the Wipe_Callbacks for any scores which need
            -- clearing
            Check_Wipes (W, M, Callbacks);

            -- Add 'space' where player character is (removing from board)
--              Add (Win    => W,
--                   Line   => Line_Position (Player.Pos.Y),
--                   Column => Column_Position (Player.Pos.X),
--                   Ch     => Space);
            Writer_Pack.Add (W      => W,
                             Line   => Line_Position (Player.Pos.Y),
                             Column => Column_Position (Player.Pos.X),
                             Ch     => Space,
                             P      => Space_Priority,
                             Wt     => Wt);

            -- Next_Direction shall only be taken if available, otherwise
            -- Player will stay on current trajectory.
            if Player.Next_Direction /= Player.Current_Direction then
               case Player.Next_Direction  is
               when Left =>
                  if M.Cells (Player.Pos.X, Player.Pos.Y).Left then
                     Player.Current_Direction := Player.Next_Direction;
                  end if;
               when Right =>
                  if M.Cells (Player.Pos.X, Player.Pos.Y).Right then
                     Player.Current_Direction := Player.Next_Direction;
                  end if;
               when Up =>
                  if M.Cells (Player.Pos.X, Player.Pos.Y).Up then
                     Player.Current_Direction := Player.Next_Direction;
                  end if;
               when Down =>
                  if M.Cells (Player.Pos.X, Player.Pos.Y).Down then
                     Player.Current_Direction := Player.Next_Direction;
                  end if;
               end case;
            end if;

            case Player.Current_Direction  is
            when Left =>
               if M.Cells (Player.Pos.X, Player.Pos.Y).Left then
                  if Player.Pos.X = Board_Width'First then
                     Player.Pos.X := M.Maze_Width;
                  else
                     Player.Pos.X := Player.Pos.X - 1;
                  end if;
               end if;
            when Right =>
               if M.Cells (Player.Pos.X, Player.Pos.Y).Right then
                  if Player.Pos.X = M.Maze_Width then
                     Player.Pos.X := Board_Width'First;
                  else
                     Player.Pos.X := Player.Pos.X + 1;
                  end if;
               end if;
            when Up =>
               if M.Cells (Player.Pos.X, Player.Pos.Y).Up then
                  Player.Pos.Y := Player.Pos.Y - 1;
               end if;
            when Down =>
               if M.Cells (Player.Pos.X, Player.Pos.Y).Down then
                  Player.Pos.Y := Player.Pos.Y + 1;
               end if;
            end case;

            -- Redraw Pacman Character sprite
            declare
               Player_Char : constant Attributed_Character :=
                 (if Player_Size = Small then Pacman_Small else Pacman_Large);
            begin
--                 Add (Win    => W,
--                      Line   => Line_Position (Player.Pos.Y),
--                      Column => Column_Position (Player.Pos.X),
--                      Ch     => Player_Char);
               Writer_Pack.Add (W      => W,
                                Line   => Line_Position (Player.Pos.Y),
                                Column => Column_Position (Player.Pos.X),
                                Ch     => Player_Char,
                                P      => Player_Priority,
                                Wt     => Wt);
            end;
            Player_Size := not Player_Size;

            -- Appropriately Eat Dots / Pills
            if M.Cells (Player.Pos.X, Player.Pos.Y).Contents = Maze_Pack.Pill then
               for G in Ghost loop
                  if Ghosts (G).State = Alive then
                     Ghosts (G).State := Zombie;
                  end if;
               end loop;
            end if;

            M.Cells (Player.Pos.X, Player.Pos.Y).Contents := Maze_Pack.None;

            Check_Collision;

            -- Ghosts Moves
            for G in Ghost loop
               declare
                  Pos : constant Coordinates := Ghosts (G).Pos;
               begin
                  -- Fill behind with appropriate character
                  declare
                     Fill_Char : Attributed_Character;
                  begin
                     case M.Cells (Pos.X, Pos.Y).Contents is
                     when Maze_Pack.None => Fill_Char := Space;
                     when Maze_Pack.Dot => Fill_Char := Dot;
                     when Maze_Pack.Pill => Fill_Char := Pill;
                     end case;
--                       Add (Win    => Win,
--                            Line   => Line_Position (Ghosts (G).Pos.Y),
--                            Column => Column_Position (Ghosts (G).Pos.X),
--                            Ch     => Fill_Char);
                     Writer_Pack.Add (W      => W,
                                      Line   => Line_Position (Ghosts (G).Pos.Y),
                                      Column => Column_Position (Ghosts (G).Pos.X),
                                      Ch     => Fill_Char,
                                      P      => Space_Priority,
                                      Wt     => Wt);
                  end;

                  case Ghosts (G).Current_Direction is
                  when Left =>
                     if M.Cells (Pos.X, Pos.Y).Left then
                        if Ghosts (G).Pos.X = Board_Width'First then
                           Ghosts (G).Pos.X := M.Maze_Width;
                        else
                           Ghosts (G).Pos.X := Ghosts (G).Pos.X - 1;
                        end if;
                     end if;
                  when Right =>
                     if M.Cells (Pos.X, Pos.Y).Right then
                        if Ghosts (G).Pos.X = M.Maze_Width then
                           Ghosts (G).Pos.X := Board_Width'First;
                        else
                           Ghosts (G).Pos.X := Ghosts (G).Pos.X + 1;
                        end if;
                     end if;
                  when Up =>
                     if M.Cells (Pos.X, Pos.Y).Up then
                        Ghosts (G).Pos.Y := Ghosts (G).Pos.Y - 1;
                     end if;
                  when Down =>
                     if M.Cells (Pos.X, Pos.Y).Down then
                        Ghosts (G).Pos.Y := Ghosts (G).Pos.Y + 1;
                     end if;
                  end case;
               end;

               declare
                  Ghost_Char : Attributed_Character := Ghosts (G).Symbol;
                  P : Priority := Ghost_Priority;
               begin
                  case G is
                  when Settings.Red =>
                     Ghost_Char.Color := Colour_Pairs (Red_Ghost);
                     P := P + 3;
                  when Settings.Blue =>
                     Ghost_Char.Color := Colour_Pairs (Blue_Ghost);
                     P := P + 2;
                  when Settings.Orange =>
                     Ghost_Char.Color := Colour_Pairs (Orange_Ghost);
                     P := P + 1;
                  when Settings.Pink =>
                     Ghost_Char.Color := Colour_Pairs (Pink_Ghost);
                  end case;

                  if Ghosts (G).State = Zombie then
                     if Use_Colour then
                        Ghost_Char.Color := Colour_Pairs (Zombie_Ghost);
                     else
                        Ghost_Char.Attr.Dim_Character := True;
                     end if;
                  end if;

                  Writer_Pack.Add (W      => W,
                                   Line   => Line_Position (Ghosts (G).Pos.Y),
                                   Column => Column_Position (Ghosts (G).Pos.X),
                                   Ch     => Ghost_Char,
                                   P      => P,
                                   Wt     => Wt);
               end;
            end loop;

            Check_Collision;

            -- Check the fruit event handler if necessary
            if Fruit_Valid then
               if Player.Pos = Fruit.Pos then
                  declare
                     Cancel_Successful : Boolean; pragma Unreferenced (Cancel_Successful);
                     Score_Str : constant String := Score'Image (Fruit.Value);
                     CB : Score_Callback := (Action => Write,
                                             Pos    => Fruit.Pos,
                                             Str    => (others => ' '),
                                             Length => Score_Str'Length);
                  begin
                     Cancel_Handler (Event     => Fruit_Timer,
                                     Cancelled => Cancel_Successful);

                     CB.Str (1 .. Score_Str'Length) := Score_Str;
                     CB.Pos.X := CB.Pos.X - 1;
                     Callbacks (Score_Fruit) := CB;

                     Fruit.Value := Fruit.Value * 2;
                     Fruit_Valid := False;

                     Pause_Countdown := 6;
                  end;
               else
                  Writer_Pack.Add (W      => W,
                                   Line   => Line_Position (Fruit.Pos.Y),
                                   Column => Column_Position (Fruit.Pos.X),
                                   Ch     => Fruit.Ch,
                                   P      => Fruit_Priority,
                                   Wt     => Wt);
               end if;
            end if;

            Perform_Writes (Wt);

            Check_Writes (W, Callbacks);

            Redraw (W);
         end if;

      end Render;

      procedure Check_Collision is
      begin
         -- Check if ghosts eat pacman or otherwise pacman eats ghosts!
         for G in Ghost loop
            if Ghosts (G).Pos = Player.Pos then
               case Ghosts (G).State is
               when Zombie =>
                  Ghosts (G).State := Dead;
                  Ghosts (G).Symbol := Ghost_Dead;

                  declare
                     Score_Str : constant String := "YUM!";
                     CB : Score_Callback := (Action => Write,
                                             Pos    => Player.Pos,
                                             Str    => (others => ' '),
                                             Length => Score_Str'Length);
                  begin
                     CB.Str (1 .. Score_Str'Length) := Score_Str;

                     case G is
                     when Settings.Red    => Callbacks (Score_Red) := CB;
                     when Settings.Blue   => Callbacks (Score_Blue) := CB;
                     when Settings.Pink   => Callbacks (Score_Pink) := CB;
                     when Settings.Orange => Callbacks (Score_Orange) := CB;
                     end case;

                     Pause_Countdown := 6;
                  end;

               when Alive =>
                  Writer_Pack.Add (W      => W,
                                   Line   => Line_Position (Ghosts (G).Pos.Y),
                                   Column => Column_Position (Ghosts (G).Pos.X),
                                   Ch     => Death,
                                   P      => 22,
                                   Wt     => Wt);
                  Perform_Writes (Wt);
                  Redraw (W);
                  raise System_Failure;
               when Dead => null;
               end case;
            end if;
         end loop;
      end Check_Collision;

      procedure Fruit_Timeout (Event : in out Timing_Event) is
         pragma Unreferenced (Event);
      begin
         case State is
         when Initialised =>
            -- Remove fruit sprite from board
            Writer_Pack.Add (W      => W,
                             Line   => Line_Position (Fruit.Pos.Y),
                             Column => Column_Position (Fruit.Pos.X),
                             Ch     => Space,
                             P      => Space_Priority,
                             Wt     => Wt);
            Fruit_Valid := False;
         when others => raise System_Failure;
         end case;
      end Fruit_Timeout;

      entry Place_Fruit (F : Fruit_Type)
        when State /= Uninitialised is
      begin
         case State is
         when Initialised =>
            Fruit := F;
            Fruit_Valid := True;
            -- Set timeout handler
            Set_Handler (Event   => Fruit_Timer,
                         In_Time => Fruit.Timeout,
                         Handler => Fruit_Timeout_Handler);
         when others => raise System_Failure;
         end case;
      end Place_Fruit;

      function Get_Player_Pos return Coordinates is (Player.Pos);
      function Get_Player_Heading return Direction is (Player.Current_Direction);

      function Get_Ghost_Pos (G : Ghost) return Coordinates is (Ghosts (G).Pos);
      function Get_Ghost_State (G : Ghost) return Ghost_State is (Ghosts (G).State);
      function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell is (M.Cells (Ghosts (G).Pos.X, Ghosts (G).Pos.Y));
      function Get_State return Board_State is (State);

      function Win return Window is (W);
   end Board;

   -- Initialise a colour using RGB_Colour which add's bounds checking
   -- not yet present in AdaCurses
   procedure Init_Colour (Colour : Color_Number;
                          R  : RGB_Colour;
                          G  : RGB_Colour;
                          B  : RGB_Colour) is
   begin
      -- Directly dispatch to AdaCurses Init_Color
      Init_Color (Color => Colour,
                  Red   => R,
                  Green => G,
                  Blue  => B);
   end Init_Colour;

begin
   Board.Initialise;
end Board_Pack;
