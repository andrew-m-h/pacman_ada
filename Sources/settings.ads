with Ada.Real_Time; use Ada.Real_Time;

-- @summary
-- Global Settings including useful datatypes
-- @description
-- Provide all packages with common datatypes to deal with
-- coordinates, scoring, and ghost properties
package Settings is

   -- Four Types of Ghost
   type Ghost is (Red, Blue, Orange, Pink);

   -- Possible Ghost States
   -- @value Alive When a ghost is in normal mode, not eaten or zombie
   -- @value Dead When a ghost has been eaten by player in zombie mode
   -- @value Zombie When a player has consumed a power pellet and turned
   -- the ghosts blue
   type Ghost_State is (Alive, Dead, Zombie);

   -- The ghosts have two modes, which the switch between on a timed basis
   type Ghost_Mode is (Chase, Scatter);

   -- Four directions entities can move
   type Direction is (Left, Right, Up, Down);

   -- Players Score
   subtype Score is Natural;

   subtype Board_Dimension is Positive;
   subtype Board_Height is Board_Dimension range 1 .. 40;
   subtype Board_Width is Board_Dimension range 1 .. 40;

   -- Locate an object on the board
   -- @field X Starting from 1 being the leftermost column
   -- @field Y Starting from 1 being the topmost row
   type Coordinates is record
      X : Board_Width := Board_Width'First;
      Y : Board_Height := Board_Height'First;
   end record;

   -- Global System Start time allows synchronisation of various concurrent entities
   System_Start : constant Time := Clock;

   -- Time in between screen rendering.
   -- All actions need to happend before this time is up including
   -- ghost moves and board update
   Render_Time : constant Time_Span := Milliseconds (100);

   -- Return coordinate of cell in a given direction from another cell.
   -- @param Pos Starting position from which to advance
   -- @param D direction in which to move
   function Next_Cell (Pos : Coordinates; D : Direction) return Coordinates;

   System_Failure : exception;

end Settings;
