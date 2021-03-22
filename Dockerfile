FROM selenium/node-chrome-debug:3.141.59-radium
LABEL maintainer="sami@vaadin.com"
RUN sudo apt-get -y update
RUN sudo apt-get -y install default-jdk
RUN sudo apt-get -y install maven
RUN sudo apt-get -y install python3-pip
RUN sudo apt-get -y install npm
RUN sudo python3 -m pip install --upgrade pip
RUN sudo python3 -m pip install certifi
RUN sudo python3 -m pip install urllib3[secure]
RUN sudo python3 -m pip install robotframework
RUN sudo python3 -m pip install robotframework-requests
RUN sudo python3 -m pip install robotframework-selenium2library
RUN sudo python3 -m pip install webdrivermanager
RUN sudo webdrivermanager chrome:75.0.3770.140 --linkpath /usr/local/bin
RUN sudo npm install -g npm@latest-6
CMD ["sh", "-c", "/usr/bin/Xvfb :99 ; sudo chmod -R 775 /usr/src/tests/ ; sudo robot -d /usr/src/tests/results /usr/src/tests/test-tutorial-starter.robot"]
