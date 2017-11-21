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
      Pos : Coordinates := Board.Get_Ghost_Pos (My_Colour);
   begin

      loop
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
                           requeue Board.Set_Ghost_State (My_Colour);
                        end Set_State;
                     or
                        accept Set_Position (P : Coordinates) do
                           requeue Board.Set_Ghost_Pos (My_Colour);
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
                     case Pos (X) is
                        when 10 =>
                           case Pos (Y) is
                              when 10 => Dir := Right;
                              when 30 => Dir := Up;
                              when others => null;
                           end case;
                        when 30 =>
                           case Pos (Y) is
                              when 10 => Dir := Down;
                              when 30 => Dir := Left;
                              when others => null;
                           end case;
                        when others => null;
                     end case;
                     Board.Make_Ghost_Move (My_Colour, Dir);

                  end select;
               exception
                  when Ghost_Render_Timeout =>
                     System_Mode := Safe_Mode;
                  when others =>
                     System_Mode := Safe_Mode;
               end;
            end case;

            Ghost_Delay_Time := Ghost_Delay_Time + Render_Time;
            delay until Ghost_Delay_Time;
         end;
      end loop;
   end Blue_Ghost_Type;

end Ghost_Pack.Blue_Ghost;
