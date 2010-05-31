/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import org.junit.*;
import static org.mockito.Mockito.*;

import java.io.PrintWriter;
import javax.servlet.FilterChain;
import javax.servlet.ServletOutputStream;
import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletResponse;


public class WadlXsltFilterTest {


    WadlXsltFilter filter;

    ServletRequest request;
    HttpServletResponse response;
    FilterChain chain;
    PrintWriter responseOut;


    @Before
    public void setUp() throws Exception {


        filter = new WadlXsltFilter();

        request = mock(ServletRequest.class);
        response = mock(HttpServletResponse.class);
        chain = mock(FilterChain.class);
        responseOut = mock(PrintWriter.class);

        when(response.getWriter()).thenReturn(responseOut);

    }

    @Test
    public void testFilterAddXsl() throws Exception {


        RequestMatcher yesMan = mock(RequestMatcher.class);
        when(yesMan.match(request)).thenReturn(true);


        filter.setRequestMatcher(yesMan);
        filter.setStylesheetUrl("test.xsl");

        

        filter.doFilter(request, response, chain);

        verify(responseOut).append("<?xml-stylesheet href=\"test.xsl\" type=\"text/xsl\"?>\n");

    }

    @Test
    public void testFilterNoXsl() throws Exception {

        RequestMatcher noMan = mock(RequestMatcher.class);
        when(noMan.match(request)).thenReturn(false);
        
        filter.setRequestMatcher(noMan);
        filter.setStylesheetUrl("test.xsl");

        filter.doFilter(request, response, chain);

        verify(responseOut, never()).append("<?xml-stylesheet href=\"test.xsl\" type=\"text/xsl\"?>\n");

    }


    @Test
    public void testInit() throws Exception {
        filter.init(null);
    }


    @Test
    public void testDestroy() throws Exception {
        filter.destroy();
    }


    @Test
    public void testByteBufferResponseWrapperGetServletOutputStream() throws Exception {

        WadlXsltFilter.ByteBufferResponseWrapper wrapper = new WadlXsltFilter.ByteBufferResponseWrapper(response);
        ServletOutputStream sos = wrapper.getOutputStream();
        sos.print("Hello World");

        Assert.assertEquals(wrapper.toString(), "Hello World");

    }



}