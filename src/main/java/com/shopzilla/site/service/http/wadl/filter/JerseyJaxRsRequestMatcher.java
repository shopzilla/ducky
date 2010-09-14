/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;

/**
 * Singleton implementation of RequestMatcher, for use with the Jersey framework's JAX-RS
 * implementation.  Looks for a "application.wadl" at the end of the request url.
 * 
 * See http://wikis.sun.com/display/Jersey/WADL
 */
public enum JerseyJaxRsRequestMatcher implements RequestMatcher {

    INSTANCE;

     public boolean match(ServletRequest request) {
        
         if (request instanceof HttpServletRequest) {
             return ((HttpServletRequest)request).getRequestURI().endsWith("application.wadl");
         } else {
             return false;
         }
     }
}