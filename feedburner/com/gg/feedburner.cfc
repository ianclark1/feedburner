<!--- Created By Gary Gilbert http://www.garyrgilbert.com
Change History:
15/01/2008 : - Added addService() method to make it easier to add services and service parameters,
						 - Added some comments
						 - Added parameter check to getFeed, both parameters are optional would cause an error if none were given
14/01/2008 : Created
 --->

<cfcomponent displayname="Feedburner" output="false">
	<cfproperty name="username" default="">
	<cfproperty name="password" default="">

	<cfscript>
		variables.username="";
		variables.password="";
		variables.secure="";
		variables.services = arrayNew(1);
	</cfscript>
<!--- initialize the component --->
	<cffunction name="init" access="public" returntype="feedburner">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="String" required="true">
		<cfargument name="secure" type="boolean" required="false" default=false>

		<cfset variables.username=username>
		<cfset variables.password=password>
		<cfif secure>
			<cfset variables.secure='s'>
		</cfif>

		<cfreturn this>
	</cffunction>
	<!--- find my feeds  --->
	<cffunction name="FindFeeds" access="public" returntype="Array">
	<!--- Gets all the feeds for a specific username/password combination
		Returns an Array of Structures with feed uri,id,and title an empty array if there arent any
		or it failed--->
	<Cfset var aFeeds = arrayNew(1) >

	<cfhttp url="http#variables.secure#://api.feedburner.com/management/1.0/FindFeeds" method="get" result="feeds">
		<cfhttpparam type="url" name="user" value="#variables.username#">
		<cfhttpparam type="url" name="password" value="#variables.password#">
	</cfhttp>
	<!--- the results are returne as an XML string so parse it --->
	<cfset xmlResult = XMLParse(feeds.filecontent)>

	<!--- Loop through the feeds and grab the values --->
		<cfif xmlResult.rsp.XMlAttributes.stat eq "ok">
			<cfloop from="1" to="#arraylen(xmlResult.rsp.feeds)#" index="i">
				<cfset Feeds = structNew()>
				<cfset Feeds.uri=xmlResult.rsp.feeds[i].feed.XMLAttributes.uri>
				<cfset Feeds.id=xmlResult.rsp.feeds[i].feed.XMLAttributes.id>
				<cfset Feeds.title=xmlResult.rsp.feeds[i].feed.XMLAttributes.title>
				<Cfset t = arrayAppend(aFeeds,feeds)>
			</cfloop>
		</cfif>
		<cfreturn aFeeds/>
	</cffunction>
<!--- get a specific feed --->
	<cffunction name="getFeed" access="public" returntype="struct">
		<!--- You must either send in the id or the uri in order to return details on a feed
		Returns a structure containing the feed details.--->
		<cfargument name="id" type="numeric" required="false" default="0">
		<cfargument name="uri" type="string" required="false" default="">

		<cfset sReturn = structNew()>
		<!--- since both variables are optional check to see if at least one is given --->
		<cfif id neq 0 and len(uri)>

			<cfif id gt 0>
				<cfset name="id">
				<cfset value="#id#">
			<cfelseif len(uri)>
				<cfset name="uri">
				<cfset value="#uri#">
			</cfif>
			<cfhttp url="http#variables.secure#://api.feedburner.com/management/1.0/GetFeed" method="get" result="feed">
				<cfhttpparam type="url" name="user" value="#variables.username#">
				<cfhttpparam type="url" name="password" value="#variables.password#">
				<cfhttpparam type="url" name="#name#" value="#value#">
			</cfhttp>
			<Cfset xmlResult = xmlParse(feed.filecontent)>
			<cfif xmlResult.rsp.XMlAttributes.stat eq "ok">
					<cfset sReturn.id = xmlResult.rsp.feed.xmlAttributes.id>
					<cfset sReturn.title = xmlResult.rsp.feed.xmlAttributes.title>
					<cfset sReturn.uri = xmlResult.rsp.feed.xmlAttributes.uri>
					<cfset sReturn.source= xmlResult.rsp.feed.source.xmlAttributes.url>
			</cfif>
		</cfif>
	<Cfreturn sReturn>

	</cffunction>
	<!--- add a new feed --->
	<Cffunction name="addFeed" access="public" returntype="struct">
	<!--- Adds a feed to your feedburner account
		If you want to add any services to your feed you must first call the addServices function
	--->
		<cfargument name="uri" type="string" required="true">
		<cfargument name="title" type="string" required="true">
		<cfargument name="source" type="string" required="true">

		<!--- build the XML string  --->
		<cfset sReturn = structNew()>
		<cfsavecontent variable="xmlAsString">
		<Cfoutput>
			<feed uri="#uri#" title="#title#">
				<source url="#source#"/>
					<services>
						<cfloop from="1" to="#arraylen(variables.services)#" index="i">
							<service class="#variables.services[i].class#">
								<cfloop from="1" to="#arraylen(variables.services[i].params)#" index="x">
									<param name="#variables.services[i].params[x].paramname#">#variables.services[i].params[x].paramvalue#</param>
								</cfloop>
							</service>
						</cfloop>
					</services>
			</feed>
			</Cfoutput>
		</cfsavecontent>

<cfdump var="#variables.services#">
		<cfabort>	<!--- must use POST method in cfhttp to add a feed --->
		<cfhttp url="http#variables.secure#://api.feedburner.com/management/1.0/AddFeed" method="post" result="feedResponse">
			<cfhttpparam type="formfield" name="user" value="#variables.username#">
			<cfhttpparam type="formfield" name="password" value="#variables.password#">
			<cfhttpparam type="formfield" name="feed" value="#xmlAsString#">
		</cfhttp>
		<!--- parse the result xml string --->
		<Cfset xmlResult = xmlParse(feedResponse.filecontent)>
		<!--- check the result status if it is ok then return the feed with its ID otherwise
		return with the error --->
		<cfif xmlResult.rsp.XMlAttributes.stat eq "ok">
					<cfset sReturn.id = xmlResult.rsp.feed.xmlAttributes.id>
					<cfset sReturn.title = xmlResult.rsp.feed.xmlAttributes.title>
					<cfset sReturn.uri = xmlResult.rsp.feed.xmlAttributes.uri>
			<cfelse>
					<cfset sReturn.id =''>
					<cfset sReturn.title = ''>
					<cfset sReturn.uri = ''>
					<cfset sReturn.error=xmlResult.rsp.err.xmlAttributes.msg>
			</cfif>
		<cfreturn sReturn>
	</Cffunction>
<!--- delete a feed --->
	<cffunction name="deleteFeed" access="public" returntype="boolean">
		<cfargument name="id" type="numeric" required="false" default="0">
		<cfargument name="uri" type="string" required="false" default="">

		<cfif id gt 0>
			<cfset name="id">
			<cfset value="#id#">
		<cfelseif len(uri)>
			<cfset name="uri">
			<cfset value="#uri#">
		</cfif>
		<cfhttp url="http#secure#://api.feedburner.com/management/1.0/DeleteFeed" method="post" result="feedresponse">
			<cfhttpparam type="formfield" name="user" value="#variables.username#">
			<cfhttpparam type="formfield" name="password" value="#variables.password#">
			<cfhttpparam type="formfield" name="#name#" value="#value#">
		</cfhttp>
		<cfif len(feedResponse.filecontent)>
				<cfreturn false>
		</cfif>
		<cfreturn true>
	</cffunction>
	<!--- helper function to add services --->
	<cffunction name="addService" access="public" returntype="void">
		<cfargument name="className" type="string" required="true">
		<cfargument name="params" type="array" required="no">

		<cfset servicesStruct= structNew()>
		<cfset servicesStruct.class="#classname#">
		<cfset servicesStruct.params = arrayNew(1)>
		<cfloop from="1" to="#arrayLen(params)#" index="x">
				<cfset param=structNew()>
				<cfset param.paramname=listgetat(params[x],1,"=")>
				<cfset param.paramvalue=listgetat(params[x],2,"=")>
				<cfset t = arrayAppend(servicesStruct.params,param)>
		</cfloop>
		<cfset t = arrayAppend(variables.services,servicesstruct)>
	</cffunction>
</cfcomponent>