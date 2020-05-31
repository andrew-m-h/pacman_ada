with Settings; use Settings;

-- @summary
-- Describe the operations on an abstract ghost task interface
-- @description
-- This interface shall be implemented by the four ghost tasks in Ghost_Pack.
-- These operations will allow the external manipulation of these tasks in a
-- ghost neutral manner.

package Ghost_Abstract is

   -- An abstract definition  of what a ghost task must implement
   type Ghost_Interface is task interface;

   -- Set the 'Ghost_State' of a ghost
   -- @param G The Ghost_Interface Parameter
   -- @param S The state to which the ghost is to be set
   procedure Set_State (G : in out Ghost_Interface;
                        S : Ghost_State) is abstract;

   -- Set the position of a ghost on the board
   -- @field G The Ghost_Interface Parameter
   -- @field S The Coordinate to which the Ghost will be
   procedure Set_Position (G : in out Ghost_Interface;
                           P : Coordinates) is abstract;

   -- return the colour of the Ghost in question
   -- @field GI The Ghost_Interface Parameter
   -- @field G the type of the ghost (Red, Blue etc)
   procedure Which_Ghost (GI : in out Ghost_Interface;
                          G : out Ghost) is abstract;

   -- Set the ghost to a specific Ghost_Mode
   -- @field G The Ghost_Interface Parameter
   -- @field M The mode to which the ghost is to be set
   procedure Set_Mode (G : in out Ghost_Interface;
                       M : Ghost_Mode) is abstract;

   type Ghost_Type is access all Ghost_Interface'Class;
end Ghost_Abstract;
