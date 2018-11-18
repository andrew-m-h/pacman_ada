with Ada.Containers; use type Ada.Containers.Count_Type;

package body Writer_Pack is

   ------------------
   -- Get_Priority --
   ------------------

   function Get_Priority (W : Writer_Job) return Priority is (W.P);

   ------------
   -- Before --
   ------------

   function Before (L, R : Priority) return Boolean is (L < R);

   ---------
   -- Add --
   ---------

   procedure Add
     (W : Window;
      Line : Line_Position;
      Column : Column_Position;
      Ch : Attributed_Character;
      P : Priority := Priority'First;
      Wt : in out Writer)
   is
      Job : constant Writer_Job :=
        (W      => W,
         Line   => Line,
         Column => Column,
         Ch     => Ch,
         P      => P);

   begin
      Wt.Enqueue (Job);
   end Add;

   --------------------
   -- Perform_Writes --
   --------------------

   procedure Perform_Writes (Wt : in out Writer) is
   begin
      while Wt.Current_Use > 0 loop
         declare
            Job : Writer_Job;
         begin
            Wt.Dequeue (Job);
            Add (Win    => Job.W,
                 Line   => Job.Line,
                 Column => Job.Column,
                 Ch     => Job.Ch);
         end;
      end loop;
   end Perform_Writes;

end Writer_Pack;
