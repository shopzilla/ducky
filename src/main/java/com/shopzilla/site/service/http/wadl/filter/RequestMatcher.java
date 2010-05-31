/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import javax.servlet.ServletRequest;

/**
 * Filter strategy for matching requests which we want to operate on.
 *
 * @author Will Gage <wgage@shopzilla.com>
 */
public interface RequestMatcher {

    /**
     * Does this request match whatever criteria we're looking for?
     * @param request
     * @return
     */
    public boolean match(ServletRequest request);
    
}
