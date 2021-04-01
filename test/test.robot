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

#Test Setup                      Start chrome browser
#Test Teardown                    Teardown

*** Variables ***

${URL}                            https://vaadin.com/
${TEST_DIR}                       /usr/src/tests/results
${TEST_RUN_ID}                    test-run-id-missing

*** Test Cases ***
Download starter from tutorial
    [Documentation]               Download the starter linked in tutorial and run it

    # Initialize variables and create a working directory
    ${download_directory}         Join Path    ${TEST_DIR}
    Create Directory              ${download_directory}

    # Simulate user navigating and downloading from vaadin.com
    Start chrome browser          ${URL}     ${download_directory}
    #Close vaadin cookie dialog
    Click First Element with Caption  Start a new app
    Page should contain                 Download
    # From frontpage we go to tutorial page first
    Click First Element with Caption  Download
    # Now we should be in tutorial page
    ${file}                       Wait Until Keyword Succeeds    1 min    2 sec    Wait for Download to complete    ${download_directory}
    
  
*** Keywords ***

Click First Element with Caption
    [Arguments]                   ${caption}
    Click Element                 xpath=//a[contains(.,"${caption}")]/.
    Wait for Vaadin                

Close vaadin cookie dialog
    [Documentation]               Closes vaadin website cookie dialog
    Press Keys                    None    exit
    Press Keys                    None    RETURN                 

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

Wait for Vaadin
    Sleep                         5s
    # This was the original one for V8 from TestBench. Does not seem to work for V10+
    #Wait For Condition           if (window.vaadin == null) {return true;} var clients = window.vaadin.clients; if (clients) { for (var client in clients) { if (clients[client].isActive()) {return false;}} return true; } else { return false; }

Teardown 
    Close All Browsers
    Terminate process             jetty
