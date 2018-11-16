with Ghost_Abstract; use Ghost_Abstract;
with Settings; use Settings;

package Ghost_Pack is

   -- Array allowing access to ghosts for external manipulation
   type Ghost_Array is array (Ghost) of Ghost_Type;

   -- Return access to the four ghosts
   function Ghost_Tasks return Ghost_Array
     with Inline_Always;

end Ghost_Pack;
