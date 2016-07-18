p <- Sys.time()
library(RSelenium)
library(magrittr)
library(stringr)
library(stringi) #For stri_extract_first (last, etc...)

#NOTE: WD should default to the root fanduel_scraper directory
#NOTE: Highlights - Time with highlights 11.53586 mins, 
# but need them to ensure DOM is good to go

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

#Source the function
source("scrape_fun.R")

#CREATE THE DATASET
dataset <- data.frame()
dataset <- rbind(dataset, scrapePage())

#FIND THE NUMBER OF PAGES
elemPages <- remDr$findElement(using='css selector', '.pagination-status')
elemPages$highlightElement()
pagesText <- elemPages$getElementAttribute("outerHTML") %>%
  str_extract("((of) [0-9][0-9]*[0-9]*)") %>% str_extract("[0-9][0-9]*[0-9]*") %>%
  as.numeric()

#ITERATE OVER PAGES
for (page in 1:(pagesText-1)){
  if (page < pagesText){
    #GO TO THE NEXT PAGE
    elemNext <- remDr$findElement(using = 'css selector', 'button.paging-control:nth-child(4)')
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
