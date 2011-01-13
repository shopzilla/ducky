/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class JerseyJaxRsRequestMatcherTest {

    ServletRequest request;

    @Before
    public void setUp() throws Exception {
    }

    @Test
    public void testMatchPositive() {
        request = mock(HttpServletRequest.class);
        when(((HttpServletRequest)request).getRequestURI()).thenReturn("/xyz/application.wadl");
        Assert.assertTrue(JerseyJaxRsRequestMatcher.INSTANCE.match(request));
    }

    @Test
    public void testMatchNegative() {
        request = mock(HttpServletRequest.class);
        when(((HttpServletRequest)request).getRequestURI()).thenReturn("/xyz/Application.WADL");
        Assert.assertFalse(JerseyJaxRsRequestMatcher.INSTANCE.match(request));
    }

    @Test
    public void testMatchNegativeNotHttp() {
        request = mock(ServletRequest.class);
        Assert.assertFalse(JerseyJaxRsRequestMatcher.INSTANCE.match(request));
    }
}