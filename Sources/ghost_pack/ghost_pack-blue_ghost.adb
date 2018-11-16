with Ada.Real_Time; use Ada.Real_Time;
with Board_Pack; use Board_Pack;

package body Ghost_Pack.Blue_Ghost is

   ---------------------
   -- Blue_Ghost_Task --
   ---------------------

   task body Blue_Ghost_Type is
      Ghost_Delay_Time : Time := System_Start;

      System_Mode : System_Mode_Type := Normal_Mode;

      Dir : Direction := Down;

      My_Colour : constant Ghost := Blue;

      State : Ghost_State := Board.Get_Ghost_State (My_Colour);
      Mode, New_Mode : Ghost_Mode := Scatter;

      Pos : Coordinates := Board.Get_Ghost_Pos (My_Colour);

      -- Bottom Right scatter point
      Scatter_Point : constant Coordinates :=
        (X => Board_Width'Last, Y => Board_Height'Last);

   begin

      Ghost_Loop : loop
         declare
            Min_Wait : constant Time := Ghost_Delay_Time + Ghost_Wait_Time;
            Deadline : constant Time := Ghost_Delay_Time + Ghost_Deadline;
         begin
            Random_Direction.Reset (Generator);

            case System_Mode is
            when Safe_Mode =>
               null;
            when Normal_Mode =>
               begin
                  -- Service Entries
                  Service_Loop : loop
                     select
                        accept Set_State (S : Ghost_State) do
                           requeue Board.Set_Ghost_State (My_Colour) with abort;
                        end Set_State;
                     or
                        accept Set_Position (P : Coordinates) do
                           requeue Board.Set_Ghost_Pos (My_Colour) with abort;
                        end Set_Position;
                     or
                        accept Set_Mode (M : Ghost_Mode) do
                           New_Mode := M;
                        end Set_Mode;
                     or
                        accept Which_Ghost (G : out Ghost) do
                           G := My_Colour;
                        end Which_Ghost;
                     or
                        delay until Min_Wait;
                        exit Service_Loop;
                     end select;
                  end loop Service_Loop;

                  Check_Board_State (My_Colour      => My_Colour,
                                     State          => State,
                                     Zombie_Handler => Zombie_Handler,
                                     Zombie_Timer   => Zombie_Timer,
                                     Handler        => Handler);

                  Pos := Board.Get_Ghost_Pos (My_Colour);

                  -- Perform Direction Calculation
                  select
                     delay until Deadline;
                     select
                        Board.Make_Ghost_Move (My_Colour) (Dir);
                     else
                        null;
                     end select;
                  then abort

                     case State is
                        when Zombie =>
                           Mode := New_Mode;
                           Choose_Random_Direction (Gen  => Generator,
                                                    Cell => Board.Get_Cell (My_Colour),
                                                    Dir  => Dir);
                           Board.Make_Ghost_Move (My_Colour) (Dir);

                        when Alive =>
                           if New_Mode /= Mode then
                              Dir := Reverse_Direction (Dir);
                              Mode := New_Mode;
                           else

                              case Mode is
                              when Chase =>

                                 -- Inky
                                 -- Target the position that is pointed to by the vector between
                                 -- Blinky and the point 2 spots ahead of pacman doubled.

                                 declare
                                    Player_Dir : constant Direction := Board.Get_Player_Heading;
                                    Player_Pos : constant Coordinates := Next_Cell
                                      (Next_Cell (Board.Get_Player_Pos, Player_Dir), Player_Dir);

                                    Blinkey_Pos : constant Coordinates := Board.Get_Ghost_Pos (Red);

                                    Target_X : constant Integer := 2 * (Integer (Player_Pos.X) - Integer (Blinkey_Pos.X));
                                    Target_Y : constant Integer := 2 * (Integer (Player_Pos.Y) - Integer (Blinkey_Pos.Y));

                                    Target : constant Coordinates :=
                                      (X => (if Target_X < Board_Width'First then Board_Width'First else
                                                 (if Target_X > Board_Width'Last then Board_Width'Last else Board_Width (Target_X))
                                            ),
                                       Y => (if Target_Y < Board_Height'First then Board_Height'First else
                                                 (if Target_Y > Board_Height'Last then Board_Height'Last else Board_Height (Target_Y))
                                            )
                                      );
                                 begin
                                    -- Only use algorithm if Red is Alive.
                                    if Board.Get_Ghost_State (Red) /= Dead then
                                       Choose_Direction (Source    => Pos,
                                                         Target    => Target,
                                                         Cell      => Board.Get_Cell (My_Colour),
                                                         Dir       => Dir);
                                    else
                                       Choose_Direction (Source    => Pos,
                                                         Target    => Player_Pos,
                                                         Cell      => Board.Get_Cell (My_Colour),
                                                         Dir       => Dir);
                                    end if;
                                 end;

                              when Scatter =>
                                 Choose_Direction (Source    => Pos,
                                                   Target    => Scatter_Point,
                                                   Cell      => Board.Get_Cell (My_Colour),
                                                   Dir       => Dir);
                              end case;
                           end if;

                           Board.Make_Ghost_Move (My_Colour) (Dir);

                        when Dead =>
                           if Pos = Revive_Point then
                              Board.Set_Ghost_State (My_Colour) (Alive);
                           else
                              Choose_Direction (Source => Pos,
                                                Target => Revive_Point,
                                                Cell   => Board.Get_Cell (My_Colour),
                                                Dir    => Dir);
                              Board.Make_Ghost_Move (My_Colour) (Dir);
                           end if;
                     end case;
                  end select;

               exception
                  when Ghost_Render_Timeout =>
                     System_Mode := Safe_Mode;
                  when others =>
                     exit Ghost_Loop;
               end;
            end case;

            Ghost_Delay_Time := Ghost_Delay_Time + Render_Time;
            delay until Ghost_Delay_Time;
         end;
      end loop Ghost_Loop;

      Board.Set_Failure;

   end Blue_Ghost_Type;
end Ghost_Pack.Blue_Ghost;
