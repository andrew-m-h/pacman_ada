with Board_Pack; use Board_Pack;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package body Player is

   task body Player_Task is
      Input_Key : Real_Key_Code := Key_None;
   begin

      loop
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

         Keypress_Poll_Delay := Keypress_Poll_Delay + Keypress_Poll_Interval;
         delay until Keypress_Poll_Delay;
      end loop;
   end Player_Task;

end Player;
