with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Numerics.Discrete_Random;
with Maze_Pack; use Maze_Pack;

private package Ghost_Pack.Util is
   -- The static elaboration checks fail to identify
   -- that Util does NOT depend upon Ghost_Pack. However
   -- it rightly sits inside the ghost_pack sub-pacakges
   pragma Suppress (Elaboration_Check, Ghost_Pack.Util);

   package Random_Direction is new Ada.Numerics.Discrete_Random (Direction);

   Revive_Point : constant Coordinates := (X => 18, Y => 17);

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
      -- @param Happened set to true if the event occurred, false otherwise
      procedure Check (Happened : out Boolean);

      -- Set Timeout_Occurred when a zombie timer event happens
      -- @param Event Timing Event which caused the timeout
      procedure Handler (Event : in out Timing_Event);

   private
      Timeout_Occurred : Boolean := False;
   end Zombie_Handler_Type;

   Zombie_Time_Out : constant Time_Span := Render_Time * 30;

   -- Utility function used to set the various states of objects based upon the Board
   -- @param My_Colour The colour of the ghost who's state is to be known
   -- @param State Current state of the ghost, is set based upon the board
   -- @param Zombie_Handler Used if the board says that a ghost has been zombified to set the zombie timeout
   -- @param Zombie_Timer Used if the board says that a ghost has been zombified to set the zombie timeout
   -- @param Handler Used if the board says that a ghost has been zombified to set the zombie timeout
   procedure Check_Board_State (My_Colour : Ghost;
                                State : in out Ghost_State;
                                Zombie_Handler : in out Zombie_Handler_Type;
                                Zombie_Timer : in out Timing_Event;
                                Handler : Timing_Event_Handler);

   -- Return square of euclidian distance between two coordinates
   -- Many ghost algorithms require taking the shortest euclidian distance
   -- and this can be efficiantly calculated without using square roots
   -- @param A First Coordinate
   -- @param B Second Coordinate
   function Distance_Square (A, B : Coordinates) return Natural;

   -- Greedy algorithm used by the ghosts to choose a direction which
   -- brings them towards their target point from the source.
   -- @param Source Location of ghost on the board
   -- @param Target Location the ghost is trying to reach
   -- @param Cell The Maze_Cell which describes the possible directions that can be taken
   -- @param Dir Current direction of the ghost, set to the new direction that the ghost should go
   procedure Choose_Direction (Source, Target : Coordinates; Cell : Maze_Cell; Dir : in out Direction);

   -- select the reversed direction
   -- @param Dir Current direction to be reversed
   function Reverse_Direction (Dir : Direction) return Direction;

   -- Choose a random direction (for use when zombified). Ghosts cannot reverse but upon the scatter timeout.
   -- @param Gen Random direction generator object
   -- @param Cell Maze Cell the ghost currently occupies
   -- @param Dir Current direction of the ghost, set to the new random direction
   procedure Choose_Random_Direction (Gen : Random_Direction.Generator; Cell : Maze_Cell; Dir : in out Direction);

end Ghost_Pack.Util;
