p <- Sys.time()
library(RSelenium)
library(magrittr)
library(stringr)
library(stringi) #For stri_extract_first (last, etc...)

#NOTE: WD should default to the root fanduel_scraper directory

#-------------------#
# SET UP AND LOG ON #
#-------------------#

#Using firefox
checkForServer()
#system(paste("open", "./RSelenium_assets/batch.command"))
system(paste("open", "./RSelenium_assets/batch-ff.command"))
Sys.sleep(5)

# Browser object
#remDr <- remoteDriver(browserName="chrome")
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4444, browserName = "firefox")
remDr$open()
remDr$getStatus()
remDr$navigate("https://www.fanduel.com/")
#Make fullscreen:
#remDr$maxWindowSize(winHand = "current")

#LOG IN
#Navigate to login page
elemLogin <- remDr$findElement(using = 'css selector', "a.mini:nth-child(1)")
elemLogin$highlightElement() #Just for visual confirmation
elemLogin$clickElement()
#Enter UN
elemUn <- remDr$findElement(using="css selector", "#email")
elemUn$highlightElement()
elemUn$sendKeysToElement(list("kyle.chadha@gmail.com"))
#Enter PW and enter
elemPw <- remDr$findElement(using="css selector", "#password")
elemPw$highlightElement()
elemPw$sendKeysToElement(list("fdscraper", key="enter"))

#There seems to be an issue here, added a sleep to test
Sys.sleep(5)

#Navigate to event page
remDr$navigate("https://www.fanduel.com/games/15560/contests/15560-24540594/entries/486153173/scoring")

#Another
Sys.sleep(5)

#-------------------#
#  SCREEN SCRAPING  #
#-------------------#
scrapePage <- function(){

  #Find the main page element and highlight for confirmation
  elemMain <- remDr$findElement(using = 'css selector', ".live-leaderboard-container")
  elemMain$highlightElement()
  
  ### GATHER USER INFORMATION ----
  #Get all the HTML and format for parsing with xpath
  elemTxtMain <- elemMain$getElementAttribute("outerHTML")[[1]]
  elemXmlMain <- htmlTreeParse(elemTxtMain, useInternalNodes=T) # parse string into HTML tree to allow for querying with XPath
  
  #1 - INDIVIDUAL RANK
  xpathRank <- "//*[@class and contains(concat(' ', normalize-space(@class), ' '), ' rank ')]"
  FDrank <- unlist(xpathApply(elemXmlMain, xpathRank, xmlValue, 'class'))
  
  #2 - INDIVIDUAL UN
  #Trying to figure out the xpath, use selectr
  xpathUN <- "//*[@class and contains(concat(' ', normalize-space(@class), ' '), ' username ')]"
  FDun <- unlist(xpathApply(elemXmlMain, xpathUN, xmlValue, 'class')) %>%
    str_extract("(?!\r\n|\r|\n)([A-Za-z0-9]+)")
  
  #3 - INDIVIDUAL $ WON
  xpathWinnings <- "//*[@class and contains(concat(' ', normalize-space(@class), ' '), ' user-winnings ')]"
  FDwinnings <- unlist(xpathApply(elemXmlMain, xpathWinnings, xmlValue, 'class')) %>% 
    str_extract("[$][0-9].\\.*[0-9]*")
  
  #4 - INDIVIDUAL SCORE
  xpathScore <- "//*[@class and contains(concat(' ', normalize-space(@class), ' '), ' user-score ')]"
  FDscore <- unlist(xpathApply(elemXmlMain, xpathScore, xmlValue, 'value'))
  
  #CREATE DATAFRAME OF INDIVIDUAL ON PAGE
  #Probably name based on the page number, so DF=i or something
  pageUsers <- data.frame(FDrank, FDun, FDwinnings, FDscore)
  
  #BUILD FUNCTION TO LOOP USERS (will be nested local vars)
  userElem <- remDr$findElements("css selector", ".live-leaderboard-entry-link")
  
  dataset <- data.frame()
  for (user in 1:nrow(pageUsers)){
    userElem[[user]]$mouseMoveToLocation()
    userElem[[user]]$highlightElement()
    userElem[[user]]$clickElement()
    Sys.sleep(3)
    
    #Identify team and convert to XML for local parsing
    userTeam <- remDr$findElement("css selector", ".live-comparison-entry.active")
    userTeam$mouseMoveToLocation()
    userTeam$highlightElement()
    teamTxtMain <- userTeam$getElementAttribute("outerHTML")[[1]]
    teamXmlMain <- htmlTreeParse(teamTxtMain, useInternalNodes=T)
    
    #Parse out team attributes - Using selector gadget for xpaths
    #1 - PLAYER POSITION
    xpathFill <- '//*[contains(concat( " ", @class, " " ), concat( " ", "lineup__player-position", " " ))]'
    playerPosition <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value'))
    
    #2 - PLAYER NAME
    xpathFill <- '//*[contains(concat( " ", @class, " " ), concat( " ", "lineup__player-name--link", " " ))]'
    playerFName <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value')) %>%
      stri_extract_first(regex="([A-Z][\\.]*[A-Z]*[\\.]*)\\w+")
    playerLName <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value')) %>%
      stri_extract_last(regex="([A-Z][\\.]*[A-Z]*[\\.]*)\\w+")
    
    #3 - SALARY
    xpathFill <- '//*[contains(concat( " ", @class, " " ), concat( " ", "lineup__player-salary", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "definition__value", " " ))]'
    playerSalary <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value')) %>%
      .[seq(1, length(.), 2)] #To select ever other term
    
    #4 - PERCENTAGE OWNED
    xpathFill <- '//*[contains(concat( " ", @class, " " ), concat( " ", "active", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "lineup__player-ppo", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "definition__value", " " ))]'
    playerOwned <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value')) %>%
      .[seq(1, length(.), 2)] #To select ever other term
    
    #5 - SCORE
    xpathFill <- '//*[contains(concat( " ", @class, " " ), concat( " ", "active", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "lineup__player-score", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "definition__value", " " ))]'
    playerScore <- unlist(xpathApply(teamXmlMain, xpathFill, xmlValue, 'value'))
    
    #BUILD THE LOCAL DF
    playerTotal <- data.frame(playerPosition, playerFName, playerLName, playerSalary, playerOwned, playerScore)
    
    #COMBINE FOR UNIQUE - Throws warning
    userPlayers <- data.frame(pageUsers[user,], playerTotal)
    dataset <- rbind(dataset, userPlayers)
  }
  return(dataset)
} #Close scrapePage

#FIND THE NUMBER OF PAGES
elemPages <- remDr$findElement(using='css selector', '.pagination-status')
elemPages$highlightElement()
pagesText <- elemPages$getElementAttribute("outerHTML") %>%
  str_extract("((of) [0-9][0-9]*[0-9]*)") %>% str_extract("[0-9][0-9]*[0-9]*") %>%
  as.numeric()

#CREATE THE DATASET
dataset <- data.frame()

#x=0
#for (page in 1:pagesText){x = x+2}

for (page in 1:pagesText){
  dataset <- rbind(dataset, scrapePage())
  if (page < pagesText){
    #GO TO THE NEXT PAGE
    elemNext <- remDr$findElement(using = 'css selector', "button.paging-control:nth-child(4)")
    elemNext$highlightElement()
    elemNext$clickElement()
    dataset <- rbind(dataset, scrapePage())
  }else{
    return(dataset)
    }
}

#Shut down the session
#remDr$closeWindow()
remDr$navigate("http://localhost:4444/selenium-server/driver/?cmd=shutDownSeleniumServer")
#remDr$close() #The close call may be redundant

#REMOVE ALL EXCEPT DATASET (and end timer)
rm(list=setdiff(ls(), c("dataset", "p")))
Sys.time() - p #One page including startup is 1.38 mins
rm(p)