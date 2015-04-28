<!--- instantiate the object --->
<cfset myFeedObj = createobject("component","garyrgilbert.tutorials.coldfusion.com.gg.feedburner").init('','')>
<!--- get all my feeds --->
<cfset myfeeds=myFeedobj.findfeeds()>
<!--- get the details on my first feed --->
<cfset myfeedDetails =myFeedobj.getfeed(myfeeds[1].id)>
<!--- dump out the details --->
<cfdump var="#myfeedDetails#">
<!--- set up the services array for more information on this check out the api
http://code.google.com/apis/feedburner/api_reference.html
--->
<cfset params=['forcedlandingpage=true']>
<cfset service=myFeedObj.addservice('BrowserFriendly',params)>
<cfset addAfeed =myFeedobj.addFeed('garyrgilbert2','testfeed','http://www.garyrgilbert.com/blog/rss.cfm?mode=full')>
<cfdump var="#addAfeed#">
<cfset deletemyfeed =myFeedobj.deleteFeed(uri='garyrgilbert2')>
<cfdump var="#deletemyfeed#">