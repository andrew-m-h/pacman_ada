with Board_Pack; use Board_Pack;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package body Player is

   ---------------------
   -- Player_Task --
   ---------------------
   -- A periodic task polling for keypresses of directional
   task body Player_Task is
      Keypress_Poll_Delay : Time := System_Start;

      Input_Key : Real_Key_Code := Real_Key_Code'First;
   begin

      loop
         begin
            Input_Key := Get_Keystroke (Board_Pack.Board.Win);
            if Input_Key = 27 then
               Input_Key := Get_Keystroke (Board_Pack.Board.Win);
               if Input_Key = 91 then
                  Input_Key := Get_Keystroke (Board_Pack.Board.Win);

                  case Input_Key is
                  when 65 => Board.Make_Player_Move (Up); -- Up Key
                  when 66 => Board.Make_Player_Move (Down); -- Down Key
                  when 67 => Board.Make_Player_Move (Right); -- Right Key
                  when 68 => Board.Make_Player_Move (Left); -- Left Key
                  when others => null;
                  end case;
               end if;
            end if;

            if Board.Get_State = Failure then
               raise System_Failure;
            end if;

            Keypress_Poll_Delay := Keypress_Poll_Delay + Keypress_Poll_Interval;
            delay until Keypress_Poll_Delay;

         exception
            when System_Failure => exit;
            when others => null;
         end;
      end loop;
   end Player_Task;

end Player;
