with Ada.Real_Time; use Ada.Real_Time;

package Settings is

   type Ghost is (Red, Blue, Orange, Pink);
   type Ghost_State is (Alive, Dead, Zombie);

   type Direction is (Left, Right, Up, Down);

   subtype Score is Natural;

   subtype Board_Dimension is Positive;
   subtype Board_Height is Board_Dimension range 1 .. 40;
   subtype Board_Width is Board_Dimension range 1 .. 40;

   type Coordinate is (X, Y);
   type Coordinates is array (Coordinate) of Board_Dimension;
   Coordinates_Zero : constant Coordinates :=
     (others => Board_Dimension'First);

   System_Start : constant Time := Clock;

   Render_Time : constant Time_Span := Milliseconds (33);

   function Next_Cell (Pos : Coordinates; D : Direction) return Coordinates;

end Settings;
