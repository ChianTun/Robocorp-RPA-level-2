*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.JavaAccessBridge
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the order file
    ${orders}=    Read it as a table and return the result
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Fill and submit the form for one order    ${order}
        Wait Until Keyword Succeeds    10x    3s    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${order}
        Order another robot
    END
    Create ZIP package from PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Element Is Visible    xpath://button[contains(text(),'OK')]
    RPA.Browser.Selenium.Click Element    xpath://button[contains(text(),'OK')]

Download the order file
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    target_file=${OUTPUT_DIR}${/}OrderData.xlsx
    ...    overwrite=True

Read it as a table and return the result
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}OrderData.xlsx
    RETURN    ${orders}

# Submit orders
#    [Arguments]    ${orders}
#    FOR    ${order}    IN    @{orders}
#    Log    ${order}
#    Fill and submit the form for one order    ${order}
#    END

Fill and submit the form for one order
    [Arguments]    ${order}
    Wait Until Element Is Visible    head
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text
    ...    xpath://input[contains(@placeholder,'legs')]
    ...    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    xpath://button[contains(text(),'Preview')]

Submit order
    Wait Until Element Is Visible    xpath://button[contains(text(),'Order')]
    Click Button    xpath://button[contains(text(),'Order')]
    Wait Until Element Is Visible    id:receipt
    #Wait Until Keyword Succeeds    10x    1s    Order error

# Order error
#    Wait Until Element Is Visible    xpath://div[contains(text(),'Error')]

Store the receipt as a PDF file
    [Arguments]    ${order}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robotpreview.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${order}
    # ${files}=    Create List    ${OUTPUT_DIR}${/}receipt.pdf    ${OUTPUT_DIR}${/}robotpreview.png
    # Add Files To PDF    ${files}    newdoc.pdf
    Open Pdf    ${OUTPUT_DIR}${/}receipt.pdf
    Add Watermark Image To Pdf
    ...    image_path=${OUTPUT_DIR}${/}robotpreview.png
    ...    source_path=${OUTPUT_DIR}${/}receipt.pdf
    ...    output_path=${OUTPUT_DIR}${/}output${/}final${order}[Order number].pdf
    Close pdf    ${OUTPUT_DIR}${/}receipt.pdf

Order another robot
    Click Button    xpath://button[contains(text(),'Order')]
    Wait Until Element Is Visible    xpath://button[contains(text(),'OK')]
    RPA.Browser.Selenium.Click Element    xpath://button[contains(text(),'OK')]

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}output    ${OUTPUT_DIR}/PDFs.zip
