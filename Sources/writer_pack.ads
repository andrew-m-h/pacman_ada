with Ada.Containers.Bounded_Priority_Queues;
with Ada.Containers.Synchronized_Queue_Interfaces;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package Writer_Pack is

   type Priority is new Integer range 0 .. 24;

   -- Some default priorities which produce nice behaviour
   -- Priorities 21-24 are reserved for anything with MUST be on top
   -- Priorities 0-1 are reserved for anything which MUST have lowest priority
   -- there is a priority in between each known item.
   Player_Priority : constant Priority := 20;
   Ghost_Priority : constant Priority := 10;
   Fruit_Priority : constant Priority := 6;
   Space_Priority : constant Priority := 2;

   type Writer_Job is record
      W : Window;
      Line : Line_Position;
      Column : Column_Position;
      Ch : Attributed_Character;
      P : Priority := Priority'First;
   end record;

   package Writer_Interface is new Ada.Containers.Synchronized_Queue_Interfaces (Writer_Job);

   function Get_Priority (W : Writer_Job) return Priority;
   function Before (L, R : Priority) return Boolean;

   package Writer_Priority_Queue is
     new Ada.Containers.Bounded_Priority_Queues
       (Queue_Interfaces => Writer_Interface,
        Queue_Priority   => Priority,
        Get_Priority     => Get_Priority,
        Before           => Before,
        Default_Capacity => 50);
   use Writer_Priority_Queue;

   subtype Writer is Writer_Priority_Queue.Queue;

   procedure Add (W : Window;
                  Line : Line_Position;
                  Column : Column_Position;
                  Ch : Attributed_Character;
                  P : Priority := Priority'First;
                  Wt : in out Writer
                 );

   procedure Perform_Writes (Wt : in out Writer);

end Writer_Pack;
