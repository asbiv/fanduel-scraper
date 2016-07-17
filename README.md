---
output: html_document
---
<strong>READ FIRST</strong><br>

<strong>KLUDGES</strong><br>
1. Viewport - Currently RSelenium does not include a function to adjust viewport size. As such, if you are running a smaller browser window you will need to manually decrease (cmd-) the content size in the viewport to 50% or so. Do this when the window opens. Or use NoSquint Plus plugin with a Firefox user account.<br>
2. Versions - Requires Firefox 47.0.1+ or <= 45.x.x. Includes Selenum Server JAR 2.53.1<br>
3. Slow - Currently very slow, ~ 20 minute build time<br>

<strong>PREPARATION</strong><br>
1. CHROME WEBDRIVER (None required for Firefox)
Included version 2.22
https://sites.google.com/a/chromium.org/chromedriver/downloads
2. SELENIUM SERVER JAR<br>
Included version 2.53.1
Make sure to be running a 64-bit version of Java
http://www.seleniumhq.org/download/
3. COMMAND FILE<br>
Included executes from within the batch.command directory. The batch.command script is accessed from R. Note that permissions may have to be adjusted to run the script from R.<br>
Note the batch-ff command executes for Firefox.

<strong>RUNNING THE R SCRIPT</strong><br>
1. Prep and run batch.command to launch selenium standalone server. Sys.sleep ensures the server gets running before R tries to open the remote driver.<br>
2. Create the browser object using a remote driver<br>
3. Opens a chrome browser and navigates to page<br>
4. Logs in to Fanduel<br>
5. Navigates to example game URL<br>
6. Iterates over user teams<br>
7. Iterates over pages<br>
8. Saves teams as a DF by UN<br>
9. Shuts down Selenium