with Settings; use Settings;

package Ghost_Abstract is

   type Ghost_Interface is task interface;

   procedure Set_State (G : in out Ghost_Interface;
                        S : Ghost_State) is abstract;
   procedure Set_Position (G : in out Ghost_Interface;
                           P : Coordinates) is abstract;
   procedure Which_Ghost (GI : in out Ghost_Interface;
                          G : out Ghost) is abstract;

   type Ghost_Type is access all Ghost_Interface'Class;
end Ghost_Abstract;
