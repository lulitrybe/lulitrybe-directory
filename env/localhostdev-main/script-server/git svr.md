 j b

Probabily this question should go to https://serverfault.com/, but, anyway...

The git advantage is to have local and remotre repositories, so, in the server, you should have "only" the remote repositories, and they should be cloned in localmachines.

to work with that paradigm, or with the one you are asking for, you need a umask of 007 (depending on your distribution edit /etc/login.defs and change there)

You should have diferent groups for the diferent kind of shared projects, and a user to "own all the repositories", for example, git-adm ).

With all the prerequisites, you create with that user the base folder for all the repositories:

sudo -i
mkdir /srv/git
chown git-adm:gitgrp /srv/git
chmod g+s /srv/git
exit

The last line in the "sticky bite", wich allows to mantain the group (and avoid the problems you previously stated), so, in order to cerate a repository should be something like:

sudo su - git-adm
mkdir /srv/git/<group>/<repoName>.git
cd /srv/git/<group>/<repoName>.git
git init --bare

exit

And thats all: if the folder /srv/git/<group>/ we owned for a diferent group, then it'll keep the group.

