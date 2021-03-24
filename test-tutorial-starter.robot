*** Settings ***
Documentation               Validate a starter in tutorial

Library  BuiltIn
Library  SeleniumLibrary
Library  RequestsLibrary
Library  OperatingSystem

Library  String
Library  Process
Library  DateTime

# docker run -p 5900:5900 -v `pwd`/tests/:/usr/src/tests -v /dev/shm:/dev/shm -it dx-tutorial-starter bash
# sudo robot -d /usr/src/tests/results /usr/src/tests/test-tutorial-starter.robot
# /usr/bin/Xvfb :99 &  /usr/bin/x11vnc -bg 

#Test Setup                      Start chrome browser
#Test Teardown                    Teardown

*** Variables ***

${URL}                            https://vaadin.com/
${TEST_DIR}                       /usr/src/tests/results
${TEST_RESULT_FORM_ID}            1fkpAffaxsZ0mpxzBThRUfaCDfAoRy7lZ1Ml90d5xJ84
${TEST_RUN_ID}                    test-run-id-missing

*** Test Cases ***
Download starter from tutorial
    [Documentation]               Download the starter linked in tutorial and run it

    # Initialize variables and create a working directory
    ${start_time_epoch}           Get Current Date  result_format=epoch
    ${start_time}                 Get Current Date
    Set Global Variable           ${TEST_RUN_ID}    test-run-${start_time_epoch}
    ${now}                        Get Time    epoch
    ${download_directory}         Join Path    ${TEST_DIR}    downloads_${now}
    Create Directory              ${download_directory}

    # Simulate user navigating and downloading from vaadin.com
    Start chrome browser          ${URL}     ${download_directory}
    #Close vaadin cookie dialog
    Click First Element with Caption  Get started
    Page should contain                 Download project
    # From frontpage we go to tutorial page first
    Click First Element with Caption  Download project
    # Now we should be in tutorial page
    ${file}                       Wait Until Keyword Succeeds    1 min    2 sec    Wait for Download to complete    ${download_directory}

    # Log download time
    ${dl_end_time}                Get Current Date
    ${dl_duration}                Subtract Date From Date    ${dl_end_time}    ${start_time}
    ${dl_size}                    Get File Size    ${file}
    Post test results             tutorial-starter   download    SUCCESS    ${dl_duration}    ${dl_size}
    
    # Extract the starter and run it
    ${starter_directory}          Extract starter zip           ${download_directory}    ${file}
    Should Exist                  ${starter_directory} 
    ${build_status}               Run Maven    install -Pproduction       ${starter_directory}    

    # Log build time
    ${build_end_time}             Get Current Date
    ${build_duration}             Subtract Date From Date    ${build_end_time}    ${dl_end_time}
    Post test results             tutorial-starter   first-build    ${build_status}    ${build_duration}    0

    # Run Spring App
    ${log_file}                   Run Maven Spring Boot project       ${starter_directory}    
    ${port}                       Wait Until Keyword Succeeds    5 min    2 sec    Wait for Spring app to start    ${log_file}


    # Log start time
    ${run_time}                   Get Current Date
    ${run_duration}               Subtract Date From Date    ${run_time}    ${build_end_time}
    Post test results             tutorial-starter   run-project    SUCCESS    ${run_duration}    0

    # Validate the running starter application
    Goto                          http://localhost:8080
    Sleep                         10s    
    Capture Page Screenshot       ${file}.png
    Validate hello world application

    # Log some duration statistics
    ${end_time}                   Get Current Date
    ${duration}                   Subtract Date From Date    ${end_time}    ${start_time}
    Post test results             tutorial-starter   full-test    SUCCESS    ${duration}    0
    Log                           Full test duration ${duration}    console=True

*** Keywords ***

Post test results
    [Arguments]                   ${topic}    ${testcase}   ${status}   ${duration}    ${size}
    &{data}=  Create Dictionary   entry.1238790128=${TEST_RUN_ID}    entry.1629084965=${topic}     entry.1535146350=${testcase}     entry.706010805=${status}    entry.760432941=${duration}    entry.291574596=${size}    submit=Submit    ifq=
    Create Session                googleform     https://docs.google.com
    ${resp}=                      Post Request                  alias=googleform    uri=/forms/d/${TEST_RESULT_FORM_ID}/formResponse    params=${data}
    Log                           Timing ${TEST_RUN_ID},${topic},${testcase},${status},${duration},${size}    console=True

Validate hello world application
    Page should contain           Say hello
    Click Button with Caption     Say hello
    Sleep                         1
    Page should contain           Hello anonymous user


Click First Element with Caption
    [Arguments]                   ${caption}
    Click Element                 xpath=//a[contains(.,"${caption}")]/.
    Wait for Vaadin    

Click Element with id
    [Arguments]                   ${id}
    Click Element                 xpath=id:${id}
    Wait for Vaadin       
    
Click First Link with Caption
    [Arguments]                   ${caption}
    Click Link                    (//a[contains(text(),"${caption}")][1])
    Wait for Vaadin    

Click Link with Caption
    [Arguments]                   ${caption}
    Click Link                    xpath=//a[.='${caption}' and not(ancestor::div[contains(@style,'display:none')]) and not(ancestor::div[contains(@style,'display: none')])]
    Wait for Vaadin               


Click Button with Caption
    [Arguments]                   ${caption}
    [Documentation]               Clicks a vaadin-button with given caption
    Click Element                 xpath=//vaadin-button[contains(@role,"button") and contains(text(),"${caption}")]/.

Close vaadin cookie dialog
    [Documentation]               Closes vaadin website cookie dialog
    Press Keys                    None    exit
    Press Keys                    None    RETURN                 

Run Maven 
    [Arguments]                   ${goal}    ${directory}
    [Documentation]               Start a project with mvn spring-boot:run, returns stdout file name
    ${log_file}                   Join Path    ${directory}    stdout.log
    Start Process                 mvn ${goal}    cwd=${directory}    shell=yes    alias=maven    stdout=${log_file}
    Wait For Process              maven
    ${status}                     Get Maven Build Status    ${log_file} 
    Log                           mvn ${goal} in ${directory} exited with status ${status}   console=True
    [Return]                      ${status}


Run Maven Spring Boot project
    [Arguments]                   ${directory}
    [Documentation]               Start a project with mvn spring-boot:run, returns stdout file name
    ${log_file}                   Join Path    ${directory}    stdout.log
    Start Process                 mvn spring-boot:run -Dvaadin.ignoreVersionChecks\=true   cwd=${directory}    shell=yes    alias=jetty    stdout=${log_file}
    [Return]                      ${log_file}
    
Run Maven jetty project
    [Arguments]                   ${directory}
    [Documentation]               Start a project with mvn jetty:run, returns stdout file name
    ${log_file}                   Join Path    ${directory}    stdout.log
    Start Process                 mvn jetty:run -Dvaadin.ignoreVersionChecks\=true   cwd=${directory}    shell=yes    alias=jetty    stdout=${log_file}
    [Return]                      ${log_file}


Extract starter zip
    [Arguments]                   ${directory}   ${file}
    [Documentation]               Extract starter zip into given directory
    Run                           cd ${directory} && unzip ${file}     
    Log                           Extracted ${file}    console=True
    Remove File                   ${file}
    ${project_directory}    ${extension}         Split Extension   ${file}
    [Return]                      ${project_directory}

Select second browser tab
    [Documentation]               Select the second browser tab, when opening links in new window
    ${Tabs}                       Get Window Titles
    select window                 title=${Tabs[1]}

Start chrome browser
    [Arguments]                   ${open_url}    ${directory}
    [Documentation]               Open chrome browser
    ${chrome_options}             Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method                   ${chrome options}   add_argument    disable-infobars
    Call Method                   ${chrome options}   add_argument    start-maximized
    Call Method                   ${chrome options}   add_argument    enable-automation
    Call Method                   ${chrome options}   add_argument    --disable-extensions
    Call Method                   ${chrome options}   add_argument    --disable-dev-shm-usage
    Call Method                   ${chrome options}   add_argument    --disable-gpu
    Call Method                   ${chrome options}   add_argument    --no-sandbox
    Call Method                   ${chrome options}   add_argument    --disable-setuid-sandbox
    ${chrome_prefs}               Create Dictionary    download.default_directory=${directory}    download.prompt_for_download=false    download.directory_upgrade=true 
    Call Method                   ${chrome_options}    add_experimental_option    prefs    ${chrome_prefs}
    Create Webdriver              Chrome    chrome_options=${chrome options}
    Maximize Browser Window
    Goto                          ${open_url}
    Wait for Vaadin
        

Wait for Download to complete
    [Arguments]                   ${directory}
    [Documentation]               Verifies that the directory has only one folder and it is not a temporary file.
    ...
    ...    Returns path to the file
    ${files}                      List Files In Directory    ${directory}
    Length Should Be              ${files}    1    Should be one and only one file in the download folder.
    Should Not Match Regexp       ${files[0]}    (?i).*\\.tmp    Chrome is still downloading a file
    ${file}                       Join Path    ${directory}    ${files[0]}
    Log                           File was successfully downloaded to ${file}    console=True
    [Return]                      ${file}

Get Maven Build Status
    [Arguments]                   ${log_file}
    [Documentation]               Checks if a Maven build is running based on logfile.
    ${file_content}               Run    grep 'BUILD ' ${log_file}  
    Should Not Be Empty           ${file_content}       Failed to read Maven build status in ${log_file}
    ${status}                     Fetch From Right    ${file_content}    ' '
    ${status}                     Fetch From Right    ${status}    ]
    ${status}                     Strip String    ${status}
    [Return]                      ${status}


Wait for Jetty to start
    [Arguments]                   ${log_file}
    [Documentation]               Checks if a Jetty application is running based on logfile.
    ${file_content}               Run    grep 'Started Jetty Server' ${log_file}  
    Should Not Be Empty           ${file_content}       Tomcat not started yet
    Log                           Started Jetty Server    console=True
    [Return]                      Started Jetty Server

Wait for Spring app to start
    [Arguments]                   ${log_file}
    [Documentation]               Checks if a Spring application is running based on logfile.
    ${file_content}               Run    grep 'Tomcat started on port(s): 8080 (http) with context path' ${log_file}  
    Should Not Be Empty           ${file_content}       Tomcat not started yet
    Log                           Started Spring Application    console=True
    [Return]                      Started Spring Application

Wait for Spring Boot to start
    [Arguments]                   ${log_file}
    [Documentation]               Checks if a Spring Boot application is running based on logfile.
    ${file_content}               Run    grep 'Tomcat started on port' ${log_file}  
    Should Not Be Empty           ${file_content}       Tomcat not started yet
    ${port}                       Fetch From Right    ${file_content}    :
    ${port}                       Fetch From Left    ${port}    (
    ${port}                       Strip String    ${port}
    Log                           Spring Boot application running on port ${port}    console=True
    [Return]                      ${port}


Wait for Vaadin
    Sleep                         5s
    # This was the original one for V8 from TestBench. Does not seem to work for V10+
    #Wait For Condition           if (window.vaadin == null) {return true;} var clients = window.vaadin.clients; if (clients) { for (var client in clients) { if (clients[client].isActive()) {return false;}} return true; } else { return false; }

Teardown 
    Close All Browsers
    Terminate process             jetty