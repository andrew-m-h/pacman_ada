with Ghost_Abstract; use Ghost_Abstract;
with Settings; use Settings;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Numerics.Discrete_Random;
with Maze_Pack; use Maze_Pack;

package Ghost_Pack is

   package Random_Direction is new Ada.Numerics.Discrete_Random (Direction);

   -- Array allowing access to ghosts for external manipulation
   type Ghost_Array is array (Ghost) of Ghost_Type;

   -- Return access to the four ghosts
   function Ghost_Tasks return Ghost_Array
     with Inline_Always;

   Revive_Point : constant Coordinates := (X => 18, Y => 17);

private
   -- Ghosts operate under real time constraint, missing a deadline shall send
   -- A ghost into Safe_Mode to handle system degredation
   -- @value Normal_Mode Normal mode of execution, making a move before each render
   -- @value Safe_Mode Safe mode of execution, saving processing power
   type System_Mode_Type is (Normal_Mode, Safe_Mode);

   -- A Ghost missing a deadline will raise this exception
   Ghost_Render_Timeout : exception;

   -- All Ghosts must have made a move before this deadline
   Ghost_Deadline : constant Time_Span := Render_Time - Milliseconds (5);
   -- All Ghosts must wait at least this long until beginning calculating a move
   -- Ghosts service requests in this period of time
   Ghost_Wait_Time : constant Time_Span := Milliseconds (5);

   -- A zombie Timer is used to handle the ghost's transition in and out of zombie state
   protected type Zombie_Handler_Type is
      -- Check returns the value of Timeout_Occurred while simultaneously setting
      -- it to False atomically.
      procedure Check (Happened : out Boolean);

      -- Set Timeout_Occurred when a zombie timer event happens
      procedure Handler (Event : in out Timing_Event);

   private
      Timeout_Occurred : Boolean := False;
   end Zombie_Handler_Type;

   Zombie_Time_Out : constant Time_Span := Render_Time * 30;

   -- Return square of euclidian distance between two coordinates
   -- Many ghost algorithms require taking the shortest euclidian distance
   -- and this can be efficiantly calculated without using square roots
   function Distance_Square (A, B : Coordinates) return Natural;

   -- Greedy algorithm used by the ghosts to choose a direction which
   -- brings them towards their target point from the source.
   procedure Choose_Direction (Source, Target : Coordinates; Cell : Maze_Cell; Dir : in out Direction);

   -- select the reversed direction
   function Reverse_Direction (Dir : Direction) return Direction;

   procedure Choose_Random_Direction (Gen : Random_Direction.Generator; Cell : Maze_Cell; Dir : in out Direction);
end Ghost_Pack;
