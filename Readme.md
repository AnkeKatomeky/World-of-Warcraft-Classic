HINTS:
0)Place client near Dokerfile. And "run docker build .". Fore u know, its take a bunch of time.
1)In compose file hint about how to get to remote console
2)srv-cfg - is where is config lies. Edit mangos.conf on RC.* paragraph to enable remote conect
3)Use sql client to edit realmd database. Table Realm - change ip to ip from whom been login. Its fixes some errors.