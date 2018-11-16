with Board_Pack; use Board_Pack;

package body Ghost_Pack.Util is

   protected body Zombie_Handler_Type is
      procedure Check (Happened : out Boolean) is
      begin
         Happened := Timeout_Occurred;
         Timeout_Occurred := False;
      end Check;

      procedure Handler (Event : in out Timing_Event) is
         pragma Unreferenced (Event);
      begin
         Timeout_Occurred := True;
      end Handler;
   end Zombie_Handler_Type;

   procedure Check_Board_State (My_Colour : Ghost;
                                State : in out Ghost_State;
                                Zombie_Handler : in out Zombie_Handler_Type;
                                Zombie_Timer : in out Timing_Event;
                                Handler : Timing_Event_Handler) is

      New_State : constant Ghost_State := Board.Get_Ghost_State (My_Colour);
      Did_Cancel : Boolean; pragma Unreferenced (Did_Cancel);

      Zombie_Timeout_Happened : Boolean;
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
            when others => null;
         end case;
      end if;
      State := New_State;

      Zombie_Handler.Check (Zombie_Timeout_Happened);

      if State = Zombie and then Zombie_Timeout_Happened then
         State := Alive;
         Board.Set_Ghost_State (My_Colour) (Alive);
      end if;

   end Check_Board_State;

   function Distance_Square (A, B : Coordinates) return Natural is
      DX : constant Integer := Integer (A.X) - Integer (B.X);
      DY : constant Integer := Integer (A.Y) - Integer (B.Y);
   begin
      return Natural (DX * DX + DY * DY);
   end Distance_Square;

   procedure Choose_Direction (Source, Target : Coordinates; Cell : Maze_Cell; Dir : in out Direction) is
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
               Next : constant Coordinates := Next_Cell (Source, D);
               Dist : constant Natural := Distance_Square (Next, Target);
            begin
               if Dist < Min_Distance then
                  Next_Dir := D;
                  Min_Distance := Dist;
               end if;
            end;
         end if;
      end loop;

      Dir := Next_Dir;
   end Choose_Direction;

   function Reverse_Direction (Dir : Direction) return Direction is
   begin
      case Dir is
         when Up => return Down;
         when Down => return Up;
         when Left => return Right;
         when Right => return Left;
      end case;
   end Reverse_Direction;

   procedure Choose_Random_Direction (Gen : Random_Direction.Generator; Cell : Maze_Cell; Dir : in out Direction) is

      Directions_Valid : constant array (Direction) of Boolean :=
        (Up => Dir /= Down and then Cell.Up,
         Down => Dir /= Up and then Cell.Down,
         Left => Dir /= Right and then Cell.Left,
         Right => Dir /= Left and then Cell.Right);

      Count_Valid : Natural := Natural'First;
   begin

      for D of Directions_Valid loop
         if D then
            Count_Valid := Natural'Succ (Count_Valid);
         end if;
      end loop;

      if Count_Valid > Natural'First then
         Dir_Loop :
         loop
            Dir := Random_Direction.Random (Gen);
            exit Dir_Loop when Directions_Valid (Dir);
         end loop Dir_Loop;
      end if;
   end Choose_Random_Direction;

end Ghost_Pack.Util;
