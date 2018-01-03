#!/bin/zsh

function get_abs_path {
     local PARENT_DIR=$(dirname "$1")
     cd "$PARENT_DIR"
     local ABS_PATH="$(pwd)"/"$(basename "$1")"
     cd - >/dev/null

    if [[ -z $ABS_PATH ]]; then
      echo "path is empty string"
      echo "Please provide the path to your your git directory"
      exit 1
    fi

    if [[ ! -d $ABS_PATH ]]; then
        echo "Error: $ABS_PATH is not a valid directory"
        echo "Please provide the path to your your git directory"
        exit 1
    fi
    echo "Select dir: \"$ABS_PATH\""
    echo "Using git directory: $ABS_PATH"
    export GIT_PATH=${ABS_PATH%/}
    export RTP_DOCKER_HOME=$GIT_PATH/JenkinsScripts/docker-dev
}

echo "Type the git root directory that you want to pull the code to (This could be changed by re-running the script), followed by [ENTER]:" 
echo ""
read tmp_rtp_dir

get_abs_path $tmp_rtp_dir


function add_rtp_zsh {
    echo "Creating rtp zsh plugin at /.oh-my-zsh/plugins/rtp/"
    
    [ -d ~/.oh-my-zsh/plugins/rtp ] || mkdir ~/.oh-my-zsh/plugins/rtp

    
    cat > ~/.oh-my-zsh/plugins/rtp/rtp.plugin.zsh << EOF
        
        export GIT_PATH=$GIT_PATH
        export RTP_DOCKER_HOME=$GIT_PATH/JenkinsScripts/docker-dev

        alias mysql="docker-compose -f $RTP_DOCKER_HOME/docker-compose.yaml exec mysql.docker mysql -usa -psa"
        alias redis-cli="docker-compose -f $RTP_DOCKER_HOME/docker-compose.yaml exec redis.master.docker redis-cli"
        alias mongo="docker-compose -f $RTP_DOCKER_HOME/docker-compose.yaml exec mongo.docker mongo"
     

        function bo_set_ver {
            echo "Setting BO version"
            bo_ver=\$(command grep --max-count=1 '<version>' $GIT_PATH/RtpBackOffice/pom.xml | awk -F '>' '{ print \$2 }' | awk -F '<' '{ print \$1 }')
            echo "BO_VER=\$bo_ver"
            echo "BO_VER=\$bo_ver" > ${RTP_DOCKER_HOME}/.env
        }
        
        function dx_set_ver {
            echo "Setting DX version"
            dx_ver=\$(command grep --max-count=1 '<version>' $GIT_PATH/RtpDX/pom.xml | awk -F '>' '{ print \$2 }' | awk -F '<' '{ print \$1 }')
            echo "DX_VER=\$dx_ver"
            echo "DX_VER=\$dx_ver" >> ${RTP_DOCKER_HOME}/.env
        }
        function exit_on_fail {
            echo "Running mvn clean install \$2 -Dmaven.test.skip=true -f $GIT_PATH/\$1/pom.xml"
            mvn clean install \$2 -Dmaven.test.skip=true -f $GIT_PATH/\$1/pom.xml
            rc=\$?
            if [[ \$rc -ne 0 ]] ; then
              echo "could not install \$1"
              return 0
            fi
            return 1
        }
        
        function exit_mvn_manifest {
            echo "Running  mvn org.apache.maven.plugins:maven-war-plugin:2.6:manifest -Dmaven.test.skip=true -f $GIT_PATH/RtpDX/pom.xml"
            mvn org.apache.maven.plugins:maven-war-plugin:2.6:manifest -Dmaven.test.skip=true -f $GIT_PATH/RtpDX/pom.xml
            rc=\$?
            if [[ \$rc -ne 0 ]] ; then
              echo "could not install \$1"
              return 0
            fi
            return 1
        }  
     
        function rtp-up {
            cd $RTP_DOCKER_HOME
            bo_set_ver
            dx_set_ver
            exit_mvn_manifest || exit_on_fail RtpDX || exit_on_fail RtpCEP || exit_on_fail RtpBackOffice || docker-compose up -d
        }
     
        function rtp-down {
            cd $RTP_DOCKER_HOME
            docker-compose down
        }
 
        function rtp-start {
            cd $RTP_DOCKER_HOME
            bo_set_ver
            dx_set_ver
            exit_mvn_manifest || exit_on_fail RtpDX || exit_on_fail RtpCEP || exit_on_fail RtpBackOffice || docker-compose start
        }
 
        function rtp-stop {
            cd $RTP_DOCKER_HOME
            docker-compose stop
        }
 
        function bo-restart {
            cd $RTP_DOCKER_HOME
            docker-compose stop bo.docker
            exit_on_fail RtpCore -o || exit_on_fail RtpCommon -o || exit_on_fail RtpTRWCommons -o || exit_on_fail RtpBackOffice -o || mvn  war:exploded -q -o -Dmaven.test.skip=true -f $GIT_PATH/RtpBackOffice/pom.xml || docker-compose start bo.docker
        }

        function cep-restart {
            cd $RTP_DOCKER_HOME
            docker-compose stop cep.docker
            exit_on_fail RtpCore -o || exit_on_fail RtpCommon -o || exit_on_fail RtpTRWCommons -o || exit_on_fail RtpCEP -o || docker-compose start cep.docker     
        }
        
        function dx-restart {
            cd $RTP_DOCKER_HOME
            docker-compose stop data-exchange.docker
            exit_on_fail RtpCore -o || exit_on_fail RtpCommon -o || exit_on_fail RtpTRWCommons -o || exit_on_fail RtpCEP -o || docker-compose start data-exchange.docker     
        }
EOF

    echo "oh-my-zsh/ rtp plugin created at /.oh-my-zsh/plugins/rtp/"
}


if [[ $(command -v brew) == "" ]]; then
    echo "Installing Hombrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "Updating Homebrew"
   # brew update
fi

if [[ $(command -v docker) == "" ]]; then
    echo "Installing Docker"
    brew cask install docker
    echo "Starting docker"
    open /Applications/Docker.app
else
    echo "Docker already installed"
    open /Applications/Docker.app
fi

if [[ $(command brew list | grep dnsmasq) == "" ]]; then
    echo "Installing dnsmasq"
    brew install dnsmasq
else
    echo "dnsmask already installed"
fi

echo "Modifing dnsmasq.conf"
mkdir -pv $(brew --prefix)/etc/
echo "Configuring dnsmasq at $(brew --prefix)/etc/dnsmasq.conf"
echo 'address=/.docker/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
echo -e 'address=/.docker/127.0.0.1 \nserver=8.8.8.8 \nserver=8.8.4.4 \nstrict-order' > $(brew --prefix)/etc/dnsmasq.conf
echo "Copying $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist to /Library/LaunchDaemons"
sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
echo "Creating directory /etc/resolver"
sudo mkdir -v /etc/resolver
echo "Creating /etc/resolver/docker file"
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/docker'
echo "Luanching damon"
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

if [[ $(command -v mvn) == "" ]]; then
    echo "Installing Maven"
    brew install maven
else
    echo "Maven already installed"
fi

if [[ ! -d $GIT_PATH/JenkinsScripts ]]; then
    cd $GIT_PATH 
    echo "Cloning JenkinsScripts to $GIT_PATH/JenkinsScripts"
    git clone git@gitlab.marketo.org:RTP/JenkinsScripts.git
    echo "Setting executable permissions to cloneRepos.sh"
    chmod +x JenkinsScripts/docker-dev/cloneRepos.sh
    $GIT_PATH/JenkinsScripts/docker-dev/cloneRepos.sh
else
    echo "JenkinsScripts already exists in $GIT_PATH/JenkinsScripts"
fi


if [[ $(command ssh-add -l | grep  `ssh-keygen -lf ~/.ssh/id_rsa  | awk '{print $2}'`) == "" ]]; then
    echo "Adding key to  ~/.ssh/id_rsa"
    ssh-add -K ~/.ssh/id_rsa
else
    echo "Key ~/.ssh/id_rsa already exists"
fi


if [[ ! -d ~/.oh-my-zsh ]]; then
    echo "Installing oh my zsh. This will abort your script. Please re-run the script again"
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
    echo "oh-my-zsh already exists"
fi

add_rtp_zsh
echo "Checking zsh plugins at .zshrc"
if [[ $(command cat ~/.zshrc | grep "^plugins=($") == "" ]]; then
    echo "zsh plugins already installed at .zshrc"
else
    echo "Installing zsh plugins at .zshrc"
    ex -sc '%s/plugins=(\n  git\n)/plugins=(git docker kubectl docker-compose mvn iterm2 sublime rtp)/g|x' ~/.zshrc
    echo "Zsh plugins installed at .zshrc"

    
fi
echo ""
echo ""
echo "  ____ _____ ____    ____               ____        _            ";
echo " |  _ \_   _|  _ \  |  _ \  _____   __ |  _ \ _   _| | ___  ___  ";
echo " | |_) || | | |_) | | | | |/ _ \ \ / / | |_) | | | | |/ _ \/ __| ";
echo " |  _ < | | |  __/  | |_| |  __/\ V /  |  _ <| |_| | |  __/\__ \ ";
echo " |_| \_\|_| |_|     |____/ \___| \_/   |_| \_\\__,_|_|\___||___/ ";
echo "                                                                 ";    
echo ""
echo "You are all set"
echo "You can now use the following commands: rtp-up rtp-down rtp-start rtp-stop bo-restart cep-restart"
echo "Enjoy!"



echo "-----------------------------------------------------------"
echo "                  Few notes!"
echo "1. Switch to zsh by typing: zsh"
echo "2. Please try to autocomplete rtp in command line"
echo "   If it doesn't work please type source ~/.zshrc"
echo "3. Make sure docker is running before running rtp-up"
echo "-----------------------------------------------------------"

echo "Your docker configuration:"
memory=$(command grep "  \"memoryMiB\" : [0-9]*," ~/Library/Group\ Containers/group.com.docker/settings.json | awk '{print $3}' | rev | cut -c 2- | rev)
cpu=$(command grep "  \"cpus\" : [0-9]*," ~/Library/Group\ Containers/group.com.docker/settings.json | awk '{print $3}' | rev | cut -c 2- | rev)

echo "Memory: $memory"
echo "CPUs: $cpu"

if [[ $cpu < 5 ]]; then
    echo "Please add more CPUs to Docker daemon. You need at least 4 CPUs"
    echo "Set Docker computing resources: Docker menu > Preferences > Advanced > Set cpu = 4"
fi

if [[ $memory < 7000 ]]; then
    echo "Please add more memory to Docker daemon. You need at least 6 6GB"
    echo "Set Docker computing resources: Docker menu > Preferences > Advanced > Set memory = 6GB"
fi

echo "Attempting to switch to zsh."
zsh
echo "Running source ~/.zshrc"
source ~/.zshrc
echo "Running source ~/.zshrc is done"
