package body Board_Pack is

   task body Render is

      Delay_Time : Time := System_Start;
   begin

      loop
         Delay_Time := Delay_Time + Render_Time;
         delay until Delay_Time;

         Board.Render;
      end loop;

   end Render;

   protected body Board is

      procedure Initialise is
      begin
         Init_Windows;

         W := Create (Number_Of_Lines       => Line_Position (Board_Height'Last),
                      Number_Of_Columns     => Column_Position (Board_Width'Last),
                      First_Line_Position   => 3,
                      First_Column_Position => 10);

         Set_Echo_Mode (False);
         Set_NoDelay_Mode (W, False);
         Set_Timeout_Mode (W, Non_Blocking, 1);

         Use_Colour := Has_Colors;

         declare
            V : Cursor_Visibility := Invisible;
         begin
            Set_Cursor_Visibility (V);
            pragma Unreferenced (V);
         end;

         -- Box (Win               => W,
         --      Vertical_Symbol   => Pipe,
         --      Horizontal_Symbol => Bar);

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
         end if;

         Maze_Pack.Read_Maze ("tmp", M);

         for Y in Board_Height'First .. M.Maze_Height loop
            Add (Win    => W,
                 Line   => Line_Position (Y),
                 Column => Column_Position (Board_Width'First),
                 Str    => M.Maze_Str (Y),
                 Len    => M.Maze_Width);
         end loop;

         Player.Pos := M.Initial_Player_Pos;

      end Initialise;

      procedure Set_Player_Pos (Pos : Coordinates) is
      begin
         Player.Pos := Pos;
      end Set_Player_Pos;

      procedure Make_Player_Move (Dir : Direction) is
      begin
         Player.Next_Direction := Dir;
      end Make_Player_Move;

      entry Set_Ghost_Pos (for G in Ghost) (Pos : Coordinates)
      when True is
      begin
         Ghosts (G).Pos := Pos;
      end Set_Ghost_Pos;

      entry Make_Ghost_Move (G : Ghost;
                             Dir : Direction)
        when True is
      begin
         Ghosts (G).Current_Direction := Dir;
      end Make_Ghost_Move;

      entry Set_Ghost_State (for G in Ghost) (S : Ghost_State)
        when True is
      begin
         Ghosts (G).State := S;
      end Set_Ghost_State;

      entry Render
        when Board.Make_Ghost_Move'Count = 0 is
      begin

         Add (Win    => W,
              Line   => Line_Position (Player.Pos (Y)),
              Column => Column_Position (Player.Pos (X)),
              Ch     => Space);

         -- Next_Direction shall only be taken if available, otherwise
         -- Player will stay on current trajectory.
         if Player.Next_Direction /= Player.Current_Direction then
            case Player.Next_Direction  is
            when Left =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Left then
                  Player.Current_Direction := Player.Next_Direction;
               end if;
            when Right =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Right then
                  Player.Current_Direction := Player.Next_Direction;
               end if;
            when Up =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Up then
                  Player.Current_Direction := Player.Next_Direction;
               end if;
            when Down =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Down then
                  Player.Current_Direction := Player.Next_Direction;
               end if;
            end case;
         end if;

         case Player.Current_Direction  is
            when Left =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Left then
                  Player.Pos (X) := Player.Pos (X) - 1;
               end if;
            when Right =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Right then
                  Player.Pos (X) := Player.Pos (X) + 1;
               end if;
            when Up =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Up then
                  Player.Pos (Y) := Player.Pos (Y) - 1;
               end if;
            when Down =>
               if M.Cells (Player.Pos (X), Player.Pos (Y)).Down then
                  Player.Pos (Y) := Player.Pos (Y) + 1;
               end if;
         end case;

         -- Redraw Pacman Character sprite
         declare
            Player_Char : constant Attributed_Character :=
              (if Player.Size = Small then Pacman_Small else Pacman_Large);
         begin
            Add (Win    => W,
                 Line   => Line_Position (Player.Pos (Y)),
                 Column => Column_Position (Player.Pos (X)),
                 Ch     => Player_Char);
         end;
         Player.Size := Switch (Player.Size);

         -- Appropriately Eat Dots / Pills
         M.Cells (Player.Pos (X), Player.Pos (Y)).Contents := Maze_Pack.None;

         -- Ghosts Moves
         for G in Ghost loop
            declare
               Pos : constant Coordinates := Ghosts (G).Pos;
            begin
               -- Fill behind with appropriate character
               declare
                  Fill_Char : Attributed_Character;
               begin
                  case M.Cells (Pos (X), Pos (Y)).Contents is
                     when Maze_Pack.None => Fill_Char := Space;
                     when Maze_Pack.Dot => Fill_Char := Dot;
                     when Maze_Pack.Pill => Fill_Char := Pill;
                  end case;
                  Add (Win    => Win,
                       Line   => Line_Position (Ghosts (G).Pos (Y)),
                       Column => Column_Position (Ghosts (G).Pos (X)),
                       Ch     => Fill_Char);
               end;

               case Ghosts (G).Current_Direction is
               when Left =>
                  if M.Cells (Pos (X), Pos (Y)).Left then
                     Ghosts (G).Pos (X) := Ghosts (G).Pos (X) - 1;
                  end if;
               when Right =>
                  if M.Cells (Pos (X), Pos (Y)).Right then
                     Ghosts (G).Pos (X) := Ghosts (G).Pos (X) + 1;
                  end if;
               when Up =>
                  if M.Cells (Pos (X), Pos (Y)).Up then
                     Ghosts (G).Pos (Y) := Ghosts (G).Pos (Y) - 1;
                  end if;
               when Down =>
                  if M.Cells (Pos (X), Pos (Y)).Down then
                     Ghosts (G).Pos (Y) := Ghosts (G).Pos (Y) + 1;
                  end if;
               end case;
            end;

            declare
               Char : Attributed_Character := Ghosts (G).Symbol;
            begin
               case G is
                  when Settings.Red =>
                     Char.Color := Colour_Pairs (Red_Ghost);
                  when Settings.Blue =>
                     Char.Color := Colour_Pairs (Blue_Ghost);
                  when Settings.Orange =>
                     Char.Color := Colour_Pairs (Orange_Ghost);
                  when Settings.Pink =>
                     Char.Color := Colour_Pairs (Pink_Ghost);
               end case;

               if Ghosts (G).State = Zombie then
                  if Use_Colour then
                     Char.Color := Colour_Pairs (Zombie_Ghost);
                  else
                     Char.Attr.Dim_Character := True;
                  end if;
               end if;

               Add (Win    => W,
                    Line   => Line_Position (Ghosts (G).Pos (Y)),
                    Column => Column_Position (Ghosts (G).Pos (X)),
                    Ch     => Char);
            end;
         end loop;

         if Fruit_Valid then
            if Player.Pos = Fruit.Pos then
               declare
                  Cancel_Successful : Boolean; pragma Unreferenced (Cancel_Successful);
               begin
                  Cancel_Handler (Event     => Fruit_Timer,
                                  Cancelled => Cancel_Successful);
                  Add (Win    => W,
                       Line   => Line_Position (Fruit.Pos (Y)),
                       Column => Column_Position (Fruit.Pos (X)),
                       Ch     => Space);
                  Fruit_Valid := False;
               end;
            else
               Add (Win    => W,
                    Line   => Line_Position (Fruit.Pos (Y)),
                    Column => Column_Position (Fruit.Pos (X)),
                    Ch     => Fruit.Ch);
            end if;
         end if;

         Redraw (W);
      end Render;

      procedure Fruit_Timeout (Event : in out Timing_Event) is
         pragma Unreferenced (Event);
      begin
         Add (Win    => W,
              Line   => Line_Position (Fruit.Pos (Y)),
              Column => Column_Position (Fruit.Pos (X)),
              Ch     => Space);
         Fruit_Valid := False;
      end Fruit_Timeout;

      procedure Place_Fruit (F : Fruit_Type) is
      begin
         Fruit := F;
         Fruit_Valid := True;
         Set_Handler (Event   => Fruit_Timer,
                      In_Time => Fruit.Timeout,
                      Handler => Fruit_Timeout_Handler);
      end Place_Fruit;

      function Get_Player_Pos return Coordinates is (Player.Pos);

      function Get_Ghost_Pos (G : Ghost) return Coordinates is (Ghosts (G).Pos);
      function Get_Ghost_State (G : Ghost) return Ghost_State is (Ghosts (G).State);
      function Get_Cell (G : Ghost) return Maze_Pack.Maze_Cell is (M.Cells (Ghosts (G).Pos (X), Ghosts (G).Pos (Y)));

      function Win return Window is (W);
   end Board;

   procedure Init_Colour (Colour : Color_Number;
                          R  : RGB_Colour;
                          G  : RGB_Colour;
                          B  : RGB_Colour) is
   begin
      Init_Color (Color => Colour,
                  Red   => R,
                  Green => G,
                  Blue  => B);
   end Init_Colour;

   function Switch (T : Token_Size) return Token_Size is
   begin
      case T is
         when Small => return Large;
         when Large => return Small;
      end case;
   end Switch;

begin
   Board.Initialise;
end Board_Pack;
