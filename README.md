# rtp dev setup script

A fully automated procedure to setup the RTP development environment.

It will install:
 * Homebrew
 * Docker
 * dnsamsq
 * Maven
 * oh-my-zsh
 * rtp-zsh plugin. Includes rtp aliases and environment variables

To execute, open terminal and switch to zsh:

```zsh```

execute curl as follows:

```curl -s https://raw.githubusercontent.com/yohayg/rtp-docker-dev/master/rtp-docker-env-setup.sh | zsh```

If you experience issues using curl to get the rtp-docker-env-setup.sh just donwnload it from:
https://raw.githubusercontent.com/yohayg/rtp-docker-dev/master/rtp-docker-env-setup.sh
Then:

```chmod +x file_name```

And execute it:

```.filename```
 
The scripts does several installations.
So in case it aborts just rerun the script again
