<?xml version="1.0"?>
<!--
 !
 ! Copyright (c) 2015 Vojtech Horky
 ! All rights reserved.
 !
 ! Redistribution and use in source and binary forms, with or without
 ! modification, are permitted provided that the following conditions
 ! are met:
 !
 ! - Redistributions of source code must retain the above copyright
 !   notice, this list of conditions and the following disclaimer.
 ! - Redistributions in binary form must reproduce the above copyright
 !   notice, this list of conditions and the following disclaimer in the
 !   documentation and/or other materials provided with the distribution.
 ! - The name of the author may not be used to endorse or promote products
 !   derived from this software without specific prior written permission.
 !
 ! THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 ! IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 ! OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 ! IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 ! INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 ! NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 ! DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 ! THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 ! (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 ! THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ! 
 !-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="html" />

<xsl:template match="/html">
	<html>
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
			<title><xsl:value-of select="descendant::div[@class='post']/h2" /></title>
		</head>
		<body>
			<xsl:apply-templates select="descendant::div[@class='post']" />
			<h3>Comments</h3>
			<xsl:apply-templates select="descendant::div[@class='commentWrap']" />
		</body>
	</html>
</xsl:template>

<xsl:template match="div[@class='post']">
	<xsl:apply-templates select="*" />
</xsl:template>

<xsl:template match="div[@class='commentWrap']">
	<xsl:for-each select="div">
		<h4><xsl:value-of select="text()" /></h4>
		<xsl:apply-templates select="./p" />
	</xsl:for-each>
</xsl:template>

<xsl:template match="/ | @* | node()" >
	<xsl:copy>
		<xsl:apply-templates select="@* | node()"  />
	</xsl:copy>
</xsl:template>


</xsl:stylesheet>
