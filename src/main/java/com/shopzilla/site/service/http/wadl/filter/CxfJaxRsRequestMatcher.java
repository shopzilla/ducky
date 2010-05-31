/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import javax.servlet.ServletRequest;

/**
 * Singleton implementation of RequestMatcher, for use with the CXF XML service framework's JAX-RS
 * implementation.  Looks for a "_wadl" parameter on the request.
 */
public enum CxfJaxRsRequestMatcher implements RequestMatcher {

    INSTANCE;

     public boolean match(ServletRequest request) {
        
         return request.getParameterMap().containsKey("_wadl");

     }

}