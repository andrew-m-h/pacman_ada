package body Settings is

   function Next_Cell (Pos : Coordinates; D : Direction) return Coordinates is
      Output : Coordinates := Pos;
   begin
      case D is
         when Up => Output (Y) := Output (Y) - 1;
         when Down => Output (Y) := Output (Y) + 1;
         when Left => Output (X) := Output (X) - 1;
         when Right => Output (X) := Output (X) + 1;
      end case;
      return Output;
   end Next_Cell;

end Settings;
