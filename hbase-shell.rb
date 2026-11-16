status 'simple'
list
describe 'lab3_Student'
scan 'lab3_Student'
scan 'lab3_Course'
scan 'lab3_SC'
count 'lab3_Student'
count 'lab3_Course'
count 'lab3_SC'
create 'lab3_shell_demo', 'Info'
put 'lab3_shell_demo', 'demo', 'Info:value', 'old'
put 'lab3_shell_demo', 'demo', 'Info:value', 'new'
get 'lab3_shell_demo', 'demo'
alter 'lab3_shell_demo', {NAME => 'Extra'}
put 'lab3_shell_demo', 'demo', 'Extra:x', '1'
deleteall 'lab3_shell_demo', 'demo', 'Extra:x'
alter 'lab3_shell_demo', {NAME => 'Extra', METHOD => 'delete'}
scan 'lab3_shell_demo'
deleteall 'lab3_shell_demo', 'demo'
count 'lab3_shell_demo'
put 'lab3_shell_demo', 'demo', 'Info:value', '1'
truncate 'lab3_shell_demo'
count 'lab3_shell_demo'
exit
