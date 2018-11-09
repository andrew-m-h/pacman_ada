with Board_Pack; use Board_Pack;
with Maze_Pack; use Maze_Pack;

package body Ghost_Pack.Red_Ghost is

   --------------------
   -- Red_Ghost_Task --
   --------------------

   task body Red_Ghost_Type is
      Ghost_Delay_Time : Time := System_Start;

      System_Mode : System_Mode_Type := Normal_Mode;

      Dir : Direction := Down;

      My_Colour : constant Ghost := Red;

      State : Ghost_State := Board.Get_Ghost_State (My_Colour);
      Pos : Coordinates := Board.Get_Ghost_Pos (My_Colour);
   begin

      Ghost_Loop : loop
         declare
            Min_Wait : constant Time := Ghost_Delay_Time + Ghost_Wait_Time;
            Deadline : constant Time := Ghost_Delay_Time + Ghost_Deadline;
         begin
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
                        accept Which_Ghost (G : out Ghost) do
                           G := My_Colour;
                        end Which_Ghost;
                     or
                        delay until Min_Wait;
                        exit Service_Loop;
                     end select;
                  end loop Service_Loop;

                  -- Check state from board (set zombie timer if needed)
                  declare
                     New_State : constant Ghost_State := Board.Get_Ghost_State (My_Colour);
                     Did_Cancel : Boolean; pragma Unreferenced (Did_Cancel);
                  begin
                     if New_State /= State then
                        case New_State is
                           when Zombie =>
                              Set_Handler (Event   => Zombie_Timer,
                                           In_Time => Zombie_Time_Out,
                                           Handler => Handler);
                           when Dead =>
                              Cancel_Handler (Event     => Zombie_Timer,
                                              Cancelled => Did_Cancel);
                           when Alive => null;
                        end case;
                     end if;
                     State := New_State;
                  end;

                  declare
                     Zombie_Timeout_Happened : Boolean;
                  begin
                     Zombie_Handler.Check (Zombie_Timeout_Happened);

                     if State = Zombie and then Zombie_Timeout_Happened then
                        State := Alive;
                        Board.Set_Ghost_State (My_Colour) (Alive);
                     end if;
                  end;

                  Pos := Board.Get_Ghost_Pos (My_Colour);

                  -- Perform Direction Calculation
                  select
                     delay until Deadline;
                     raise Ghost_Render_Timeout;
                  then abort

                     -- Blinky
                     -- Look at any adjoining move tiles, and select the one
                     -- which will bring ghost closest to player's position
                     -- Cannot ever move backwards
                     declare
                        Cell : constant Maze_Cell := Board.Get_Cell (My_Colour);
                        Player_Pos : constant Coordinates := Board.Get_Player_Pos;
                        Directions_Valid : constant array (Direction) of Boolean :=
                          (Up => Dir /= Down and then Cell.Up,
                           Down => Dir /= Up and then Cell.Down,
                           Left => Dir /= Right and then Cell.Left,
                           Right => Dir /= Left and then Cell.Right);
                        Next_Dir : Direction := Dir;
                        Min_Distance : Natural := Natural'Last;
                     begin
                        for D in Direction loop
                           if Directions_Valid (D) then
                              declare
                                 Next : constant Coordinates := Next_Cell (Pos, D);
                                 Dist : constant Natural := Distance_Square (Next, Player_Pos);
                              begin
                                 if Dist < Min_Distance then
                                    Next_Dir := D;
                                    Min_Distance := Dist;
                                 end if;
                              end;
                           end if;
                        end loop;
                        Dir := Next_Dir;
                     end;

                     Board.Make_Ghost_Move (My_Colour) (Dir);

                  end select;
               exception
                  when Ghost_Render_Timeout =>
                     System_Mode := Safe_Mode;
                  when System_Failure =>
                     exit Ghost_Loop;
               end;
            end case;

            Ghost_Delay_Time := Ghost_Delay_Time + Render_Time;
            delay until Ghost_Delay_Time;
         end;
      end loop Ghost_Loop;

   end Red_Ghost_Type;

end Ghost_Pack.Red_Ghost;
