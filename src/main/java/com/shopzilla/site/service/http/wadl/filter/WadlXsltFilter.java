/**
 * Copyright (C) 2004-2010 Shopzilla, Inc.
 * All rights reserved. Unauthorized disclosure or distribution is prohibited.
 */
package com.shopzilla.site.service.http.wadl.filter;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.ByteArrayOutputStream;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletResponseWrapper;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


/**
 * Filter which prepends an xml-stylesheet processing instruction to WADL documents in order to
 * allow client-side transformation of the document into HTML.  The intent is to only apply that
 * instruction to documents which contain WADL data.
 * 
 * @author Will Gage <wgage@shopzilla.com>
 */
public final class WadlXsltFilter implements Filter {


    private static final Log LOG = LogFactory.getLog(WadlXsltFilter.class);

    private String stylesheetUrl="../app/wadl-doc.xsl";
    
    private RequestMatcher requestMatcher = CxfJaxRsRequestMatcher.INSTANCE;

    /**
     * Controls where the stylesheet is sourced from.
     * @param stylesheetUrl
     */
    public void setStylesheetUrl(String stylesheetUrl) {
        this.stylesheetUrl = stylesheetUrl;
    }

    /**
     * Plug in a RequestMatcher to control which requests will get modified.
     * Default value is a CxfJaxRsRequestMatcher.
     * @param requestMatcher
     */
    public void setRequestMatcher(RequestMatcher requestMatcher) {
        this.requestMatcher = requestMatcher;
    }

    public void init(FilterConfig filterConfig) throws ServletException {
        /* Do nothing */
    }


    public void doFilter(ServletRequest request,
                         ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        if (this.requestMatcher.match(request)) {

            LOG.debug("adding transform");

            ByteBufferResponseWrapper wrapper =
                    new ByteBufferResponseWrapper(
                            (HttpServletResponse) response);

            wrapper.getWriter().append(makeProcessingInstruction()).append("\n").flush();

            chain.doFilter(request, wrapper);

            PrintWriter out = response.getWriter();

            out.append(wrapper.toString());
            out.flush();

        } else {

            LOG.debug("NOT adding transform");
            // just pass it along
            chain.doFilter(request, response);
        }
    }


    String makeProcessingInstruction() {
        return "<?xml-stylesheet href=\"" + this.stylesheetUrl + "\" type=\"text/xsl\"?>";
    }

    public void destroy() {
        /* Do nothing */
    }

    /**
     * Simple response wrapper that buffers the bytes of the response.
     */
    static class ByteBufferResponseWrapper extends HttpServletResponseWrapper {

        private final ByteArrayOutputStream buffer;

        public String toString() {
            return this.buffer.toString();
        }

        public ByteBufferResponseWrapper(HttpServletResponse response) {
            super(response);
            this.buffer = new ByteArrayOutputStream();
        }

        public PrintWriter getWriter() {
            return new PrintWriter(this.buffer);
        }

        public ServletOutputStream getOutputStream() {
            return new ServletOutputStreamWrapper(this.buffer);
        }


    }

    /**
     * Simple ServletOutputStream that operates on the same buffer as the enclosing
     * ByteBufferResponseWrapper
     */
    static class ServletOutputStreamWrapper extends ServletOutputStream {

        private final ByteArrayOutputStream buffer;

        public ServletOutputStreamWrapper(ByteArrayOutputStream buffer) {
            super();
            this.buffer = buffer;

        }

        @Override
        public void write(int b) throws IOException {
            this.buffer.write(b);
        }
    }


}

