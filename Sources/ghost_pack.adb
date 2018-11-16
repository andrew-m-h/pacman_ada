with Ghost_Pack.Red_Ghost;
with Ghost_Pack.Blue_Ghost;
with Ghost_Pack.Orange_Ghost;
with Ghost_Pack.Pink_Ghost;

package body Ghost_Pack is

   function Ghost_Tasks return Ghost_Array is ((Red => Ghost_Pack.Red_Ghost.Red_Ghost_Task'Access,
                                                Blue => Ghost_Pack.Blue_Ghost.Blue_Ghost_Task'Access,
                                                Orange => Ghost_Pack.Orange_Ghost.Orange_Ghost_Task'Access,
                                                Pink => Ghost_Pack.Pink_Ghost.Pink_Ghost_Task'Access
                                               ));

end Ghost_Pack;
