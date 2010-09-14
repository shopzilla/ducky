<?xml version="1.0" encoding="UTF-8"?>
<!--
  wadl_documentation.xsl (2007-12-19)

  An XSLT stylesheet for generating HTML documentation from WADL,
  by Mark Nottingham <mnot@yahoo-inc.com>.

  Copyright (c) 2006-2007 Yahoo! Inc.
  
  This work is licensed under the Creative Commons Attribution-ShareAlike 2.5 
  License. To view a copy of this license, visit 
    http://creativecommons.org/licenses/by-sa/2.5/ 
  or send a letter to 
    Creative Commons
    543 Howard Street, 5th Floor
    San Francisco, California, 94105, USA
-->
<!-- 
 * FIXME
    - Doesn't inherit query/header params from resource/@type
    - XML schema import, include, redefine don't import
-->
<!--
  * TODO
    - forms
    - link to or include non-schema variable type defs (as a separate list?)
    - @href error handling
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:wadl="http://research.sun.com/wadl/2006/10"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:html="http://www.w3.org/1999/xhtml" xmlns:exsl="http://exslt.org/common"
                xmlns:ns="urn:namespace" extension-element-prefixes="exsl"
                xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xsl wadl xs html ns">

  <xsl:output method="html" encoding="UTF-8" indent="yes"
              doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

  <xsl:variable name="wadl-ns">http://research.sun.com/wadl/2006/10</xsl:variable>


  <!-- expand @hrefs, @types into a full tree -->

  <xsl:variable name="resources">
    <xsl:apply-templates select="/wadl:application/wadl:resources" mode="expand"/>
  </xsl:variable>

  <xsl:template match="wadl:resources" mode="expand">
    <xsl:variable name="base">
      <xsl:call-template name="chop-trailing-slash">
        <xsl:with-param name="pathParam" select="@base"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:element name="resources" namespace="{$wadl-ns}">
      <xsl:for-each select="namespace::*">
        <xsl:variable name="prefix" select="name(.)"/>
        <xsl:if test="$prefix">
          <xsl:attribute name="ns:{$prefix}">
            <xsl:value-of select="."/>
          </xsl:attribute>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates select="@*|node()" mode="expand">
        <xsl:with-param name="base" select="$base"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="wadl:resource[@type]" mode="expand">
    <xsl:param name="base"/>
    <xsl:variable name="uri" select="substring-before(@type, '#')"/>
    <xsl:variable name="id" select="substring-after(@type, '#')"/>
    <xsl:element name="resource" namespace="{$wadl-ns}">
      <xsl:choose>
        <xsl:when test="$uri">
          <xsl:variable name="included" select="document($uri, /)"/>
          <xsl:copy-of select="$included/descendant::wadl:resource_type[@id=$id]/@*"/>
          <xsl:attribute name="id">
            <xsl:value-of select="@type"/>
          </xsl:attribute>
          <xsl:apply-templates select="$included/descendant::wadl:resource_type[@id=$id]/*"
                               mode="expand">
            <xsl:with-param name="base" select="$uri"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="//resource_type[@id=$id]/@*"/>
          <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="@type"/>
          </xsl:attribute>
          <xsl:apply-templates select="//wadl:resource_type[@id=$id]/*" mode="expand">
            <xsl:with-param name="base" select="$base"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="node()" mode="expand">
        <xsl:with-param name="base" select="$base"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="wadl:*[@href]" mode="expand">
    <xsl:param name="base"/>
    <xsl:variable name="uri" select="substring-before(@href, '#')"/>
    <xsl:variable name="id" select="substring-after(@href, '#')"/>
    <xsl:element name="{local-name()}" namespace="{$wadl-ns}">
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <xsl:when test="$uri">
          <xsl:attribute name="id">
            <xsl:value-of select="@href"/>
          </xsl:attribute>
          <xsl:variable name="included" select="document($uri, /)"/>
          <xsl:apply-templates select="$included/descendant::wadl:*[@id=$id]/*" mode="expand">
            <xsl:with-param name="base" select="$uri"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="$id"/>
          </xsl:attribute>
          <!-- xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute -->
          <xsl:attribute name="element">
            <xsl:value-of select="//wadl:*[@id=$id]/@element"/>
          </xsl:attribute>
          <xsl:attribute name="mediaType">
            <xsl:value-of select="//wadl:*[@id=$id]/@mediaType"/>
          </xsl:attribute>
          <xsl:apply-templates select="//wadl:*[@id=$id]/*" mode="expand">
            <xsl:with-param name="base" select="$base"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="node()[@id]" mode="expand">
    <xsl:param name="base"/>
    <xsl:element name="{local-name()}" namespace="{$wadl-ns}">
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="@id"/>
      </xsl:attribute>
      <!-- xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute -->
      <xsl:apply-templates select="node()" mode="expand">
        <xsl:with-param name="base" select="$base"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*|node()" mode="expand">
    <xsl:param name="base"/>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="expand">
        <xsl:with-param name="base" select="$base"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- debug $resources
      <xsl:template match="/">
      <xsl:copy-of select="$resources"/>
      </xsl:template>
  -->

  <!-- collect grammars (TODO: walk over $resources instead) -->

  <xsl:variable name="grammars">
    <xsl:copy-of select="/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
    <xsl:apply-templates select="/wadl:application/wadl:grammars/wadl:include[@href]"
                         mode="include-grammar"/>
    <xsl:apply-templates select="/wadl:application/wadl:resources/descendant::wadl:resource[@type]"
                         mode="include-href"/>
    <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:*[@href]"
                         mode="include-href"/>
  </xsl:variable>

  <xsl:template match="wadl:include[@href]" mode="include-grammar">
    <xsl:variable name="included" select="document(@href, /)/*"/>
    <xsl:element name="wadl:include">
      <xsl:attribute name="href">
        <xsl:value-of select="@href"/>
      </xsl:attribute>
      <xsl:copy-of select="$included"/>
      <!-- FIXME: xml-schema includes, etc -->
    </xsl:element>
  </xsl:template>

  <xsl:template match="wadl:*[@href]" mode="include-href">
    <xsl:variable name="uri" select="substring-before(@href, '#')"/>
    <xsl:if test="$uri">
      <xsl:variable name="included" select="document($uri, /)"/>
      <xsl:copy-of
              select="$included/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
      <xsl:apply-templates select="$included/descendant::wadl:include[@href]"
                           mode="include-grammar"/>
      <xsl:apply-templates
              select="$included/wadl:application/wadl:resources/descendant::wadl:resource[@type]"
              mode="include-href"/>
      <xsl:apply-templates
              select="$included/wadl:application/wadl:resources/descendant::wadl:*[@href]"
              mode="include-href"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="wadl:resource[@type]" mode="include-href">
    <xsl:variable name="uri" select="substring-before(@type, '#')"/>
    <xsl:if test="$uri">
      <xsl:variable name="included" select="document($uri, /)"/>
      <xsl:copy-of
              select="$included/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
      <xsl:apply-templates select="$included/descendant::wadl:include[@href]"
                           mode="include-grammar"/>
      <xsl:apply-templates
              select="$included/wadl:application/wadl:resources/descendant::wadl:resource[@type]"
              mode="include-href"/>
      <xsl:apply-templates
              select="$included/wadl:application/wadl:resources/descendant::wadl:*[@href]"
              mode="include-href"/>
    </xsl:if>
  </xsl:template>

  <!-- main template -->

  <xsl:template match="/wadl:application">

    <html>
      <head>
        <title>
          <xsl:choose>
            <xsl:when test="wadl:doc[@title]">
              <xsl:value-of select="wadl:doc[@title][1]/@title"/>
            </xsl:when>
            <xsl:otherwise>Web Application Description</xsl:otherwise>
          </xsl:choose>
        </title>
        <link rel="shortcut icon"
              href="http://img01.shopzilla-images.com/sz2s/sz2/common/images/shopzilla.ico"/>
        <style type="text/css">

          body {
            font-family: sans-serif;
            font-size: 0.85em;
            margin: 2em 8em;
          }

          .methods {
            background-color: #eef;
            padding: 1em;
          }

          h1 {
            font-size: 2.5em;
          }

          h2 {
            border-bottom: 1px solid black;
            margin-top: 1em;
            margin-bottom: 0.5em;
            font-size: 2em;
          }

          h3 {
            color: orange;
            font-size: 1.75em;
            margin-top: 1.25em;
            margin-bottom: 0em;
          }

          h4 {
            margin: 0em;
            padding: 0em;
            border-bottom: 2px solid white;
          }

          h5 {
            font-size: 1.1em;
            margin: 0.5em 0em 0.25em 0.5em;
          }

          h6 {
            font-size: 1.1em;
            color: #99a;
            margin: 0.5em 0em 0.25em 0em;
          }

          dd {
            margin-left: 1em;
          }

          tt {
            font-size: 1.2em;
          }

          table {
            margin-bottom: 0.5em;
          }

          th {
            text-align: left;
            font-weight: normal;
            color: black;
            border-bottom: 1px solid black;
            padding: 3px 6px;
          }

          td {
            padding: 3px 6px;
            vertical-align: top;
            background-color: #f6f6ff;
            font-size: 0.85em;
          }

          td p {
            margin: 0px;
          }

          ul {
            padding-left: 1.75em;
          }

          p + ul, p + ol, p + dl {
            margin-top: 0em;
          }

          .optional {
            font-weight: normal;
            opacity: 0.75;
          }

          .formBox {
            margin: 10px;
            padding: 10px;
          }

          .formOutputOk, .formOutputError {
            margin: 5px;
            padding: 2px;
            text-align: right;
            background-color: #ffffff;
          }

          .formOutputOk {
            border: #00cc00 dotted 1px;
          }

          .formOutputError {
            border: #ff0000 dotted 1px;
          }

          .formOutputEntry {
            border-top: #cccccc dotted 1px;
            padding-top: 5px;
            padding-bottom: 15px;
          }

          a.formControl:link, a.formControl:visited, a.formToggle:link, a.formToggle:visited {
            text-decoration: none;
          }

          .formOutputData {
            color: #000000;
            font-family: andale mono, mono-type;
            margin: 10px;
            padding: 10px;
            text-align: left;
            overflow: auto;
          }

          .form {
            margin-top: 10px;
            padding: 5px;
            border: #cccccc solid 1px;
            /*width: 50%;*/
          }

          .formToggle {
            line-height: 120%;
          }

          .logo {
            margin: 10px 0px 10px 0px;
          }

          #footer {
            margin-top: 3em;
            font-size: 0.85em;
            text-align: center;
          }
        </style>
        <script type="text/JavaScript">
            <xsl:text disable-output-escaping="yes">
              <![CDATA[
              
                 function Parameter(name, value) {
                    this.name=name;
                    this.value=value;
                    this.fixed=false;
                 }

                 function ParameterDefinition(style, required, fixed) {
                    this.style=style;
                    this.required=required;
                    this.fixed=fixed;
                 }

                 Parameter.prototype.toString = function() {
                    if(this.value) {
                      return this.name + '=' + window.escape(this.value);
                    } else if(this.fixed) {
                      return this.name;
                    }
                    return '';
                 }

                 function UrlBuilder(actionUrl) {
                    this.actionUrl = actionUrl;
                    this.templateParams = new Array();
                    this.queryParams = new Array();
                    this.matrixParams = new Array();
                 }

                 UrlBuilder.prototype.addTemplateParam = function(param) {
                    this.templateParams.push(param)
                 }

                 UrlBuilder.prototype.addQueryParam = function(param) {
                    this.queryParams.push(param)
                 }
                 
                 UrlBuilder.prototype.addMatrixParam = function(param) {
                    this.matrixParams.push(param)
                 }

                 UrlBuilder.prototype.buildUrl = function() {

                    var finalAction = this.actionUrl;

                    // put in template params  
                    for(var i=0; i < this.templateParams.length; i++) {
                      var p = this.templateParams[i];
                      if(p.value) {
                        finalAction = finalAction.replace('{' + p.name + '}', window.escape(p.value));
                      }
                    }


                    // add matrix params
                    if(this.matrixParams.length > 0) {

                      var matrixString = this.matrixParams.join(';');
                      
                      if(!UrlBuilder.containsOnly(matrixString, ';')) {
                        finalAction = UrlBuilder.addIfNotPresent(finalAction, '/');
                        finalAction += matrixString;
                      }
                    }


                    // add query params
                    if(this.queryParams.length > 0) {

                      var paramString = this.queryParams.join('&');

                      if(!UrlBuilder.containsOnly(paramString, '&')) {
                        finalAction = UrlBuilder.addIfNotPresent(finalAction, '?');
                        finalAction += paramString;
                      }

                    }

                    return finalAction;
                 }

                 UrlBuilder.containsOnly = function(str, chr) {

                    if(str == null) {
                      return false;
                    }

                    for(i=0; i < str.length; i++) {
                      if(str[i] != chr) {
                        return false;
                      }
                    }

                    return true;

                 }

                 UrlBuilder.addIfNotPresent = function(path, char) {
                    if(path[path.length-1] != char) {
                      return path + char;  
                    }
                 }

                 function WADLForm(formId) {
                    this.formId=formId;
                    this.paramDefinitions = new Array();
                    this.contentType = null;
                 }

                 WADLForm.httpFactories = [
                  function() { return new XMLHttpRequest(); },
                  function() { return new ActiveXObject('Mxsml2.XMLHTTP'); },
                  function() { return new ActiveXObject('Microsoft.XMLHTTP'); }
                 ];

                 WADLForm.newRequest = function() {
                 
                   for(var i=0; i < WADLForm.httpFactories.length; i++) {
                     try {

                       var factory = WADLForm.httpFactories[i];
                       var request = factory();
                       if(request != null) {
                         return request;
                       }

                     } catch(e) {
                       continue;
                     }

                   }

                   throw new Error('Could not create XMLHttpRequest');

                 }

                 WADLForm.prototype.closeOutput = function() {
                      var outerPanel = document.getElementById('form-' + this.formId+"-output");
                      outerPanel.style.visibility = 'hidden';
                      outerPanel.style.display = 'none';
                  }

                 WADLForm.prototype.toggleForm = function() {
                    var anchor = document.getElementById('link-' + this.formId);
                    var form = document.getElementById('form-' + this.formId);
                    if (anchor != null && form != null) {
                      if(form.style.visibility == 'hidden') {
                        form.style.visibility = 'visible';
                        form.style.display = 'block';
                        anchor.innerHTML = anchor.innerHTML.replace('+', 'x').replace('show', 'hide');
                      } else {
                        this.closeOutput();
                        form.style.visibility = 'hidden';
                        form.style.display = 'none';
                        anchor.innerHTML=anchor.innerHTML.replace('x', '+').replace('hide', 'show');
                      }

                    }
                 }

                 WADLForm.prototype.clearOutput = function() {
                    var innerPanel = document.getElementById('form-' + this.formId + '-output-data');
                    while(innerPanel.childNodes.length > 0) {
                      innerPanel.removeChild(innerPanel.childNodes[0]);
                    }
                 }

                 WADLForm.prototype.showOutput = function(message, isOk) {

                    var innerPanel = document.getElementById('form-' + this.formId + '-output-data');

                    var textNode = document.createTextNode(message);
                    var logEntry = document.createElement('div');
                    logEntry.setAttribute('class', 'formOutputEntry');
                    logEntry.appendChild(textNode);
                    innerPanel.appendChild(logEntry);

                    var outerPanel = document.getElementById('form-' + this.formId + '-output');
                    outerPanel.style.visibility = 'visible';
                    outerPanel.style.display = 'block';

                    if(isOk) {
                      outerPanel.setAttribute('class', 'formOutputOk');
                    } else {
                      outerPanel.setAttribute('class', 'formOutputError');
                    }

                  }

                  WADLForm.prototype.addInput = function(inputName, style, required, fixed) {

                    this.paramDefinitions[inputName] = new ParameterDefinition(style.toLowerCase(), required, fixed);
                  }


                  WADLForm.prototype.setContentType = function(contentType) {
                      this.contentType = contentType;
                  }

                  WADLForm.addHeaders = function(request, headerParams) {

                    for(var i=0; i < headerParams.length; i++) {
                      request.setRequestHeader(headerParams[i].name, headerParams[i].value);
                    }

                  }

                  WADLForm.prototype.submit = function() {

                    var form = document.getElementById('form-'+this.formId);

                    var action = form.getAttribute('action');
                    var method = form.getAttribute('method').toLowerCase();
                    var inputs = form.getElementsByTagName('input');

                    var headers = new Array();
                    var builder = new UrlBuilder(action);

                    for(var i=0; i < inputs.length; i++) {
                      var x = inputs[i];
                      var name = x.getAttribute('name');
                      var paramDef = this.paramDefinitions[name];
                      
                      if(paramDef) {
                        var style = paramDef.style;
                        if(style == 'query') {
                          var p = new Parameter(name, x.value);
                          p.fixed = paramDef.fixed;
                          builder.addQueryParam(p);
                        } else if (style == 'template') {
                          builder.addTemplateParam(new Parameter(name, x.value));
                        } else  if (style == 'matrix') {
                          builder.addMatrixParam(new Parameter(name, x.value));
                        } else  if (style == 'header') {
                          headers.push(new Parameter(name, x.value));
                        }

                      }

                    }

                    try {

                      var finalUrl = builder.buildUrl();

                      var requestBody = document.getElementById('form-'+this.formId+'-request-body');

                      this.clearOutput();

                      var req = WADLForm.newRequest();

                      if(requestBody && requestBody.value && this.contentType) {

                        this.showOutput(method.toUpperCase() + ' ' + finalUrl, true);
                        headers.push(new Parameter('Content-Type', this.contentType));
                        req.open(method, finalUrl, false);
                        WADLForm.addHeaders(req, headers);
                        req.send(requestBody.value);

                      } else {

                        this.showOutput(method.toUpperCase() + ' ' + finalUrl, true);

                        req.open(method, finalUrl, false);
                        WADLForm.addHeaders(req, headers);
                        req.send(null);

                      }
                    

                      if(req.status && req.status > 199 && req.status < 300) {
                        this.showOutput(req.responseText, true);
                      } else {
                        this.showOutput("ERROR Status: " + req.status + " - " + req.statusText
                          + "; " + req.responseText, false);
                      }
                      
                    } catch(e) {
                        this.showOutput("ERROR " +  e, false);
                    }

                  }

                  ]]>
                  </xsl:text>
        </script>

      </head>
      <body>

        <h1>
          <xsl:choose>
            <xsl:when test="wadl:doc[@title]">
              <xsl:value-of select="wadl:doc[@title][1]/@title"/>
            </xsl:when>
            <xsl:otherwise>Web Application Description</xsl:otherwise>
          </xsl:choose>
        </h1>
        <xsl:apply-templates select="wadl:doc"/>
        <ul>
          <li>
            <a href="#resources">Resources</a>
            <xsl:apply-templates select="exsl:node-set($resources)" mode="toc"/>
          </li>
          <li>
            <a href="#representations">Representations</a>
            <ul>
              <xsl:apply-templates
                      select="exsl:node-set($resources)/descendant::wadl:representation"
                      mode="toc"/>
            </ul>
          </li>
          <xsl:if test="descendant::wadl:fault">
            <li>
              <a href="#faults">Faults</a>
              <ul>
                <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:fault"
                                     mode="toc"/>
              </ul>
            </li>
          </xsl:if>
        </ul>
        <h2 id="resources">Resources</h2>
        <xsl:apply-templates select="exsl:node-set($resources)" mode="list"/>
        <h2 id="representations">Representations</h2>
        <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:representation"
                             mode="list"/>
        <xsl:if test="exsl:node-set($resources)/descendant::wadl:fault">
          <h2 id="faults">Faults</h2>
          <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:fault"
                               mode="list"/>
        </xsl:if>
        <p id="footer">
        </p>
      </body>
    </html>
  </xsl:template>

  <!-- Table of Contents -->

  <xsl:template match="wadl:resources" mode="toc">
    <xsl:variable name="base">
      <xsl:call-template name="chop-leading-trailing-slash">
                <xsl:with-param name="pathParam" select="@base"/>
      </xsl:call-template>
    </xsl:variable>
    <ul>
      <xsl:apply-templates select="wadl:resource" mode="toc">
        <xsl:with-param name="context">
          <xsl:value-of select="$base"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </ul>
  </xsl:template>

  <xsl:template match="wadl:resource" mode="toc">
    <xsl:param name="context"/>
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="chop-leading-trailing-slash">
        <xsl:with-param name="pathParam" select="$context"/>
      </xsl:call-template>/<xsl:call-template name="chop-leading-trailing-slash">
        <xsl:with-param name="pathParam" select="@path"/>
      </xsl:call-template>
    </xsl:variable>
    <li>
      <a href="#{$id}">
        <xsl:value-of select="$name"/>
      </a>
      <xsl:if test="wadl:resource">
        <ul>
          <xsl:apply-templates select="wadl:resource" mode="toc">
            <xsl:with-param name="context">
              <xsl:call-template name="chop-leading-trailing-slash">
                <xsl:with-param name="pathParam" select="$name"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:apply-templates>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>

  <xsl:template match="wadl:representation|wadl:fault" mode="toc">
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <xsl:variable name="href" select="@id"/>
    <xsl:choose>
      <xsl:when test="preceding::wadl:*[@id=$href]"/>
      <xsl:otherwise>
        <li>
          <a href="#{$id}">
            <xsl:call-template name="representation-name"/>
          </a>
        </li>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Listings -->

  <xsl:template match="wadl:resources" mode="list">
    <xsl:variable name="base">
      <xsl:call-template name="chop-leading-trailing-slash">
        <xsl:with-param name="pathParam" select="@base"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:apply-templates select="wadl:resource" mode="list">
      <xsl:with-param name="context">
        <xsl:value-of select="$base"/>
      </xsl:with-param>
    </xsl:apply-templates>

  </xsl:template>

  <xsl:template match="wadl:resource" mode="list">
    <xsl:param name="context"/>
    <xsl:variable name="href" select="@id"/>
    <xsl:choose>
      <xsl:when test="preceding::wadl:resource[@id=$href]"/>
      <xsl:otherwise>
        <xsl:variable name="id">
          <xsl:call-template name="get-id"/>
        </xsl:variable>
        <xsl:variable name="name">
          <xsl:call-template name="chop-leading-trailing-slash">
            <xsl:with-param name="pathParam" select="$context"/>
          </xsl:call-template>/<xsl:call-template name="chop-leading-trailing-slash">
            <xsl:with-param name="pathParam" select="@path"/>
          </xsl:call-template>
          <xsl:for-each select="wadl:param[@style='matrix']">
            <span class="optional">;<xsl:value-of select="@name"/>=...
            </span>
          </xsl:for-each>
        </xsl:variable>
        <div class="resource">
          <h3 id="{$id}">
            <xsl:choose>
              <xsl:when test="wadl:doc[@title]">
                <xsl:value-of select="wadl:doc[@title][1]/@title"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="$name"/>
                <xsl:for-each select="wadl:method[1]/wadl:request/wadl:param[@style='query']">
                  <xsl:choose>
                    <xsl:when test="@required='true'">
                      <xsl:choose>
                        <xsl:when test="preceding-sibling::wadl:param[@style='query']">
                          &amp;</xsl:when>
                        <xsl:otherwise>?</xsl:otherwise>
                      </xsl:choose>
                      <xsl:value-of select="@name"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <span class="optional">
                        <xsl:choose>
                          <xsl:when test="preceding-sibling::wadl:param[@style='query']">
                            &amp;</xsl:when>
                          <xsl:otherwise>?</xsl:otherwise>
                        </xsl:choose>
                        <xsl:value-of select="@name"/>
                      </span>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>

          </h3>
          <xsl:apply-templates select="wadl:doc"/>
          <xsl:apply-templates select="." mode="param-group">
            <xsl:with-param name="prefix">resource-wide</xsl:with-param>
            <xsl:with-param name="style">template</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="." mode="param-group">
            <xsl:with-param name="prefix">resource-wide</xsl:with-param>
            <xsl:with-param name="style">matrix</xsl:with-param>
          </xsl:apply-templates>
          <h6>Methods</h6>
          <div class="methods">
            <xsl:apply-templates select="wadl:method">
              <xsl:with-param name="context" select="$name"/>
            </xsl:apply-templates>
          </div>
        </div>
        <xsl:apply-templates select="wadl:resource" mode="list">
          <xsl:with-param name="context" select="$name"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="wadl:method">
    <xsl:param name="context"/>
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <div class="method">
      <h4 id="{$id}">
        <xsl:value-of select="@name"/>
      </h4>
      <xsl:apply-templates select="wadl:doc"/>
      <xsl:apply-templates select="wadl:request"/>
      <xsl:apply-templates select="wadl:response"/>
      <xsl:choose>
        <xsl:when test="wadl:request">
          <xsl:apply-templates select="wadl:request" mode="form">
            <xsl:with-param name="context" select="$context"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="form">
            <xsl:with-param name="context" select="$context"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template match="wadl:request">
    <xsl:apply-templates select="." mode="param-group">
      <xsl:with-param name="prefix">request</xsl:with-param>
      <xsl:with-param name="style">query</xsl:with-param>
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="param-group">
      <xsl:with-param name="prefix">request</xsl:with-param>
      <xsl:with-param name="style">header</xsl:with-param>
    </xsl:apply-templates>
    <xsl:if test="wadl:representation">
      <p>
        <em>acceptable request representations:</em>
      </p>
      <ul>
        <xsl:apply-templates select="wadl:representation"/>
      </ul>
    </xsl:if>
  </xsl:template>

  <xsl:template match="wadl:*" mode="form">
    <xsl:param name="context"/>
    <xsl:apply-templates select="." mode="form-param-group">
      <xsl:with-param name="context" select="$context"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="wadl:response">
    <xsl:apply-templates select="." mode="param-group">
      <xsl:with-param name="prefix">response</xsl:with-param>
      <xsl:with-param name="style">header</xsl:with-param>
    </xsl:apply-templates>
    <xsl:if test="wadl:representation">
      <p>
        <em>available response representations:</em>
      </p>
      <ul>
        <xsl:apply-templates select="wadl:representation"/>
      </ul>
    </xsl:if>
    <xsl:if test="wadl:fault">
      <p>
        <em>potential faults:</em>
      </p>
      <ul>
        <xsl:apply-templates select="wadl:fault"/>
      </ul>
    </xsl:if>
  </xsl:template>

  <xsl:template match="wadl:representation|wadl:fault">
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <li>
      <a href="#{$id}">
        <xsl:call-template name="representation-name"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="wadl:representation|wadl:fault" mode="list">
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <xsl:variable name="href" select="@id"/>
    <xsl:variable name="expanded-name">
      <xsl:call-template name="expand-qname">
        <xsl:with-param select="@element" name="qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="preceding::wadl:*[@id=$href]"/>
      <xsl:otherwise>
        <h3 id="{$id}">
          <xsl:call-template name="representation-name"/>
        </h3>
        <xsl:apply-templates select="wadl:doc"/>
        <xsl:if test="@element or wadl:param">
          <div class="representation">
            <xsl:if test="@element">
              <h6>XML Schema</h6>
              <xsl:call-template name="get-element">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="qname" select="@element"/>
              </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="." mode="param-group">
              <xsl:with-param name="style">plain</xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="." mode="param-group">
              <xsl:with-param name="style">header</xsl:with-param>
            </xsl:apply-templates>
          </div>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="wadl:*" mode="param-group">
    <xsl:param name="style"/>
    <xsl:param name="prefix"/>
    <xsl:if test="ancestor-or-self::wadl:*/wadl:param[@style=$style]">
      <h6>
        <xsl:value-of select="$prefix"/><xsl:text> </xsl:text><xsl:value-of select="$style"/>
        parameters
      </h6>
      <table>
        <tr>
          <th>parameter</th>
          <th>value</th>
          <th>description</th>
        </tr>
        <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:param[@style=$style]"/>
      </table>
    </xsl:if>
  </xsl:template>

  <xsl:template match="wadl:*" mode="form-param-group">
    <xsl:param name="context"/>
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <!--<xsl:if test="ancestor-or-self::wadl:*/wadl:param[@style=$style]">-->
    <!--<xsl:if test="ancestor-or-self::wadl:*/wadl:param">  -->
    <xsl:if test="ancestor-or-self::wadl:method">
      <div class="formBox">

        <script type="text/JavaScript">

            var form_<xsl:value-of select="$id"/> = new WADLForm('<xsl:value-of select="$id"/>');
          
        </script>
        <a id="link-{$id}" class="formToggle">
          <xsl:attribute name="href">javascript:form_<xsl:value-of select="$id"/>.toggleForm();</xsl:attribute>
          [ + ] show form
        </a>



        <form class="form" id="form-{$id}" style="visibility: hidden; display: none">
          <xsl:attribute name="action">
            <xsl:value-of select="$context"/>
          </xsl:attribute>
          <xsl:choose>
            <xsl:when test="ancestor-or-self::wadl:method">
              <xsl:attribute name="method">
                <xsl:value-of select="ancestor-or-self::wadl:method/@name"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="method">GET</xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
          <h5>
            <xsl:value-of select="$context"/>
          </h5>

          <xsl:if test="ancestor-or-self::wadl:*/wadl:param or ancestor-or-self::wadl:*/wadl:representation">
            <table>
              <tr>
                <th>parameter</th>
                <th>value</th>
                <th>input</th>
              </tr>

              <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:param"
                                 mode="form-param"/>

              <xsl:apply-templates select="."
                                 mode="form-request-body">
                <xsl:with-param name="formId" select="$id"/>
              </xsl:apply-templates>
            </table>
          </xsl:if>

          <!-- setting up configuration for the form submit -->
          <script type="text/JavaScript">

              <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:param"
                                 mode="form-param-config">
                <xsl:with-param name="formId" select="$id"/>
              </xsl:apply-templates>

          </script>

          <input type="button" value="submit">
            <xsl:attribute name="onclick">form_<xsl:value-of select="$id"/>.submit();</xsl:attribute>
          </input>
        </form>
        <div class="formOutputOk" id="form-{$id}-output" style="visibility: hidden; display: none">
          <a class="formControl"><xsl:attribute name="href">javascript:form_<xsl:value-of select="$id"/>.closeOutput();</xsl:attribute>[ x ]</a>
          <div class="formOutputData" id="form-{$id}-output-data">
          <!-- empty until we fill with response output -->
          </div>
        </div>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="wadl:*" mode="form-request-body">
    <xsl:param name="formId"/>
    <xsl:choose>
      <xsl:when test="ancestor-or-self::wadl:*/wadl:representation">
        <tr>
          <td>
            <p>
              <strong>
                request body
              </strong>
            </p>
          </td>
          <td>
          
            <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:representation"
                                 mode="form-representation-name">
              <xsl:with-param name="formId" select="$formId"/>
            </xsl:apply-templates>
          </td>
          <td>
            <textarea rows="10" cols="35">
              <xsl:attribute name="id">form-<xsl:value-of select="$formId"/>-request-body</xsl:attribute>
              <!-- Generate an example of the first listed representation -->
              <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:representation[1]"
                                 mode="form-representation-example"/>

            </textarea>
          </td>
        </tr>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="wadl:representation" mode="form-representation-name">
    <xsl:param name="formId"/>
    <xsl:variable name="id">
      <xsl:call-template name="get-id"/>
    </xsl:variable>
    <p>
      <em>
        <xsl:choose>
          <xsl:when test="@mediaType">
            <input type="radio">
              <xsl:attribute name="name">form-<xsl:value-of select="$formId"/>-content-type</xsl:attribute>
              <xsl:attribute name="value"><xsl:value-of select="@mediaType"/></xsl:attribute>
              <xsl:attribute name="onclick">form_<xsl:value-of select="$formId"/>.setContentType(this.value);</xsl:attribute>
              <xsl:choose>
              <xsl:when test="position() = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:when>
              </xsl:choose>
            </input>
            <xsl:choose>
              <xsl:when test="position() = 1">
                <script type="text/JavaScript">
                  <!-- setting initial values -->

                  form_<xsl:value-of select="$formId"/>.setContentType('<xsl:value-of select="@mediaType"/>');

                </script>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
        <a href="#{$id}">
          <xsl:call-template name="representation-name"/>
        </a>
      </em>
    </p>
  </xsl:template>

  <xsl:template match="wadl:representation" mode="form-representation-example">
    <xsl:if test="@element">
      <xsl:call-template name="generate-element">
        <xsl:with-param name="context" select="."/>
        <xsl:with-param name="qname" select="@element"/>
    </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <xsl:template match="wadl:param">
    <tr>
      <td>
        <p>
          <strong>
            <xsl:value-of select="@name"/>
          </strong>
        </p>
      </td>
      <td>
        <p>
          <em>
            <xsl:call-template name="link-qname">
              <xsl:with-param name="qname" select="@type"/>
            </xsl:call-template>
          </em>
          <xsl:if test="@required='true'">
            <small>(required)</small>
          </xsl:if>
          <xsl:if test="@repeating='true'">
            <small>(repeating)</small>
          </xsl:if>
        </p>
        <xsl:choose>
          <xsl:when test="wadl:option">
            <p>
              <em>One of:</em>
            </p>
            <ul>
              <xsl:apply-templates select="wadl:option"/>
            </ul>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="@default">
              <p>Default:
                <tt>
                  <xsl:value-of select="@default"/>
                </tt>
              </p>
            </xsl:if>
            <xsl:if test="@fixed">
              <p>Fixed:
                <tt>
                  <xsl:value-of select="@fixed"/>
                </tt>
              </p>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td>
        <xsl:apply-templates select="wadl:doc"/>
        <xsl:if test="wadl:option[wadl:doc]">
          <dl>
            <xsl:apply-templates select="wadl:option" mode="option-doc"/>
          </dl>
        </xsl:if>
        <xsl:if test="@path">
          <ul>
            <li>XPath to value:
              <tt>
                <xsl:value-of select="@path"/>
              </tt>
            </li>
            <xsl:apply-templates select="wadl:link"/>
          </ul>
        </xsl:if>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="wadl:param" mode="form-param">
    <tr>
      <td>
        <p>
          <strong>
            <xsl:value-of select="@name"/>
          </strong>
        </p>
      </td>
      <td>
        <p>
          <em>
            <xsl:call-template name="link-qname">
              <xsl:with-param name="qname" select="@type"/>
            </xsl:call-template>
          </em>
          <xsl:if test="@required='true'">
            <small>(required)</small>
          </xsl:if>
          <xsl:if test="@repeating='true'">
            <small>(repeating)</small>
          </xsl:if>
        </p>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="wadl:option">
            <select>
              <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:choose>
                <xsl:when test="@required='true'"></xsl:when>
                <xsl:otherwise>
                  <option value="">...</option>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:apply-templates select="wadl:option" mode="form-param-option"/>
            </select>
          </xsl:when>
          <xsl:when test="@type='xsd:boolean'">
            <select>
              <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:choose>
                <xsl:when test="@required='true'"></xsl:when>
                <xsl:otherwise>
                  <option value="">...</option>
                </xsl:otherwise>
              </xsl:choose>
              <option value="true">true</option>
              <option value="false">false</option>
            </select>
          </xsl:when>
          <xsl:otherwise>
            <input type="text">
              <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:if test="@default">
                <xsl:attribute name="value">
                  <xsl:value-of select="@default"/>
                </xsl:attribute>
              </xsl:if>
              <xsl:if test="@fixed">
                <xsl:attribute name="value">
                  <xsl:value-of select="@fixed"/>
                </xsl:attribute>
              </xsl:if>
            </input>
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>


  <xsl:template match="wadl:param" mode="form-param-config">
    <xsl:param name="formId"/>
    <xsl:variable name="required" select="boolean(string(@required))"/>
    <xsl:variable name="fixed" select="boolean(@fixed)"/>
    <!-- making note of the parameter's "style" for the JavaScript layer -->
    form_<xsl:value-of select="$formId"/>.addInput('<xsl:value-of select="@name"/>','<xsl:value-of select="@style"/>', <xsl:value-of select="$required"/>, <xsl:value-of select="$fixed"/>);
  </xsl:template>


  <xsl:template match="wadl:link">
    <li>
      Link:
      <a href="#{@resource_type}">
        <xsl:value-of select="@rel"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="wadl:option">
    <li>
      <tt>
        <xsl:value-of select="@value"/>
      </tt>
      <xsl:if test="ancestor::wadl:param[1]/@default=@value">
        <small>(default)</small>
      </xsl:if>
    </li>
  </xsl:template>

  <xsl:template match="wadl:option" mode="form-param-option">
    <option>
      <xsl:attribute name="value">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
      <xsl:if test="ancestor::wadl:param[1]/@default=@value">
        <xsl:attribute name="selected"/>
      </xsl:if>
      <xsl:value-of select="@value"/>
    </option>
  </xsl:template>

  <xsl:template match="wadl:option" mode="option-doc">
    <dt>
      <tt>
        <xsl:value-of select="@value"/>
      </tt>
      <xsl:if test="ancestor::wadl:param[1]/@default=@value">
        <small>(default)</small>
      </xsl:if>
    </dt>
    <dd>
      <xsl:apply-templates select="wadl:doc"/>
    </dd>
  </xsl:template>

  <xsl:template match="wadl:doc">
    <xsl:param name="inline">0</xsl:param>
    <!-- skip WADL elements -->
    <xsl:choose>
      <xsl:when test="node()[1]=text() and $inline=0">
        <p>
          <xsl:apply-templates select="node()" mode="copy"/>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="node()" mode="copy"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- utilities -->

  <xsl:template name="get-id">
    <xsl:choose>
      <xsl:when test="@id">
        <xsl:value-of select="@id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="chop-trailing-slash">
    <xsl:param name="pathParam" />
    <xsl:choose>
      <xsl:when test="substring($pathParam, string-length($pathParam)) = '/'">
        <xsl:value-of select="substring($pathParam, 1, string-length($pathParam)-1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pathParam"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="chop-leading-trailing-slash">
    <xsl:param name="pathParam" />
    <xsl:variable name="choppedPathParam">
    <xsl:choose>
      <xsl:when test="substring($pathParam, 1, 1) = '/'">
         <xsl:value-of select="substring($pathParam, 2, string-length($pathParam))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of   select="$pathParam"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="chop-trailing-slash">
      <xsl:with-param name="pathParam" select="$choppedPathParam"/>  
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="get-namespace-uri">
    <xsl:param name="context" select="."/>
    <xsl:param name="qname"/>
    <xsl:variable name="prefix" select="substring-before($qname,':')"/>
    <xsl:variable name="qname-ns-uri" select="$context/namespace::*[name()=$prefix]"/>
    <!-- nasty hack to get around libxsl's refusal to copy all namespace nodes when pushing nodesets around -->
    <xsl:choose>
      <xsl:when test="$qname-ns-uri">
        <xsl:value-of select="$qname-ns-uri"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
                select="exsl:node-set($resources)/*[1]/attribute::*[namespace-uri()='urn:namespace' and local-name()=$prefix]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-element">
    <xsl:param name="context" select="."/>
    <xsl:param name="qname"/>
    <xsl:variable name="ns-uri">
      <xsl:call-template name="get-namespace-uri">
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="qname" select="$qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="localname" select="substring-after($qname, ':')"/>
    <xsl:variable name="definition"
                  select="exsl:node-set($grammars)/descendant::xs:element[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>
    <xsl:variable name="source" select="$definition/ancestor-or-self::wadl:include[1]/@href"/>
    <p>
      <em>Source:
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="substring-after($source, 'xsd/')"/>
          </xsl:attribute>
          <xsl:value-of select="substring-after($source, 'xsd/')"/>
        </a>
      </em>
    </p>
    <pre>
      <xsl:apply-templates select="$definition" mode="encode"/>
    </pre>
  </xsl:template>


  <xsl:template name="generate-element">
    <xsl:param name="context" select="."/>
    <xsl:param name="qname"/>
    <xsl:variable name="ns-uri">
      <xsl:call-template name="get-namespace-uri">
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="qname" select="$qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="localname" select="substring-after($qname, ':')"/>
    <xsl:variable name="definition"
                  select="exsl:node-set($grammars)/descendant::xs:element[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>
   
    <xsl:apply-templates select="$definition" mode="generate"/>
  </xsl:template>

  <xsl:template name="link-qname">
    <xsl:param name="context" select="."/>
    <xsl:param name="qname"/>
    <xsl:variable name="ns-uri">
      <xsl:call-template name="get-namespace-uri">
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="qname" select="$qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="localname" select="substring-after($qname, ':')"/>
    <xsl:choose>
      <xsl:when test="$ns-uri='http://www.w3.org/2001/XMLSchema'">
        <a href="http://www.w3.org/TR/xmlschema-2/#{$localname}">
          <xsl:value-of select="$localname"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="definition"
                      select="exsl:node-set($grammars)/descendant::xs:*[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>
        <a href="http://www.mnot.net/webdesc/%7B$definition/ancestor-or-self::wadl:include%5B1%5D/@href%7D"
           title="{$definition/descendant::xs:documentation/descendant::text()}">
          <xsl:value-of select="$localname"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="expand-qname">
    <xsl:param name="context" select="."/>
    <xsl:param name="qname"/>
    <xsl:variable name="ns-uri">
      <xsl:call-template name="get-namespace-uri">
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="qname" select="$qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$ns-uri"/>
    <xsl:text>} </xsl:text>
    <xsl:value-of select="substring-after($qname, ':')"/>
  </xsl:template>


  <xsl:template name="representation-name">
    <xsl:variable name="expanded-name">
      <xsl:call-template name="expand-qname">
        <xsl:with-param select="@element" name="qname"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="wadl:doc[@title]">
        <xsl:value-of select="wadl:doc[@title][1]/@title"/>
        <xsl:if test="@status or @mediaType or @element">(</xsl:if>
        <xsl:if test="@status">Status Code</xsl:if>
        <xsl:value-of select="@status"/>
        <xsl:if test="@status and @mediaType">-</xsl:if>
        <xsl:value-of select="@mediaType"/>
        <xsl:if test="(@status or @mediaType) and @element">-</xsl:if>
        <xsl:if test="@element">
          <abbr title="{$expanded-name}">
            <xsl:value-of select="@element"/>
          </abbr>
        </xsl:if>
        <xsl:if test="@status or @mediaType or @element">)</xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="@status">Status Code</xsl:if>
        <xsl:value-of select="@status"/>
        <xsl:if test="@status and @mediaType">-</xsl:if>
        <xsl:value-of select="@mediaType"/>
        <xsl:if test="@element">(</xsl:if>
        <abbr title="{$expanded-name}">
          <xsl:value-of select="@element"/>
        </abbr>
        <xsl:if test="@element">)</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- entity-encode markup for display -->

  <xsl:template match="*" mode="encode">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="attribute::*" mode="encode"/>
    <xsl:choose>
      <xsl:when test="*|text()">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates select="*|text()" mode="encode" xml:space="preserve"/>
        <xsl:text>&lt;/</xsl:text><xsl:value-of select="name()"/><xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" mode="encode">
    <xsl:text> </xsl:text><xsl:value-of select="name()"/><xsl:text>="</xsl:text><xsl:value-of
          select="."/><xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template match="text()" mode="encode">
    <xsl:value-of select="." xml:space="preserve"/>
  </xsl:template>


  <xsl:template match="xs:element" mode="generate">

    <xsl:choose>
    <xsl:when test="@name">
    <xsl:text>&lt;</xsl:text>  
    <xsl:value-of select="@name"/>
    <!--<xsl:apply-templates select="attribute::*" mode="generate"/>-->
    <xsl:choose>
      <xsl:when test="*|text()">
        <xsl:apply-templates select="xs:attribute" mode="generate" xml:space="preserve"/>
        <xsl:text>&gt;</xsl:text>
        <!--<xsl:apply-templates select="*|text()" mode="generate" xml:space="preserve"/>-->
        <xsl:text>&lt;/</xsl:text><xsl:value-of select="@name"/><xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:when>  
    </xsl:choose>
  </xsl:template>


  <xsl:template match="xs:attribute" mode="generate">
    <xsl:choose>
      <xsl:when test="@name">
        <xsl:variable name="name" select="@name"/>
        <xsl:attribute name="{$name}"></xsl:attribute>
    </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" mode="generate">
    <xsl:text> </xsl:text><xsl:value-of select="name()"/><xsl:text>="</xsl:text><xsl:value-of
          select="."/><xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template match="text()" mode="generate">
    <xsl:value-of select="." xml:space="preserve"/>
  </xsl:template>

  <!-- copy HTML for display -->

  <xsl:template match="html:*" mode="copy">
    <!-- remove the prefix on HTML elements -->
    <xsl:element name="{local-name()}">
      <xsl:for-each select="@*">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="node()" mode="copy"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*|node()[namespace-uri()!='http://www.w3.org/1999/xhtml']" mode="copy">
    <!-- everything else goes straight through -->
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="copy"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>