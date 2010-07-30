/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.ducky;

import com.shopzilla.ducky.CxfJaxRsRequestMatcher;
import org.junit.*;
import static org.mockito.Mockito.*;

import javax.servlet.ServletRequest;
import java.util.Map;

public class CxfJaxRsRequestMatcherTest {

    ServletRequest request;

    @Before
    public void setUp() throws Exception {

        request = mock(ServletRequest.class);

    }


    @Test
    public void testMatchPositive() {

        final Map paramMap = mock(Map.class);
        when(paramMap.containsKey("_wadl")).thenReturn(true);
        when(request.getParameterMap()).thenReturn(paramMap);

        Assert.assertTrue(CxfJaxRsRequestMatcher.INSTANCE.match(request));

    }


    @Test
    public void testMatchNegative() {

        final Map paramMap = mock(Map.class);
        when(paramMap.containsKey("_wadl")).thenReturn(false);
        when(request.getParameterMap()).thenReturn(paramMap);

        Assert.assertFalse(CxfJaxRsRequestMatcher.INSTANCE.match(request));


    }
    

}