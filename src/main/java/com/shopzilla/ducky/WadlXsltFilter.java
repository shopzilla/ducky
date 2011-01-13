/*
 *
 * Copyright (C) 2010 Shopzilla, Inc
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *
 *
 * http://tech.shopzilla.com
 *
 *
 */
package com.shopzilla.ducky;

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
import javax.servlet.http.HttpServletRequest;
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

    private String stylesheetPath ="app/wadl-doc.xsl";
    
    private RequestMatcher requestMatcher = CxfJaxRsRequestMatcher.INSTANCE;


    /**
     * Controls where the stylesheet is sourced from. The path should NOT begin with a '/' character,
     * and should be relative to the Servlet context path.
     * @param stylesheetPath
     */
    public void setStylesheetPath(String stylesheetPath) {
        this.stylesheetPath = stylesheetPath;
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
            String styleSheetPath = makeProcessingInstruction(request);

            chain.doFilter(request, wrapper);

            wrapper.getWriter().flush();
            String responseStr = injectStyleSheet(wrapper.toString(), styleSheetPath);
            response.setContentLength(responseStr.length());
            PrintWriter out = response.getWriter();
            out.append(responseStr);
            out.flush();

        } else {

            LOG.debug("NOT adding transform");
            // just pass it along
            chain.doFilter(request, response);
        }
    }

    String injectStyleSheet(String original, String styleSheetPath) {
        StringBuffer sb = new StringBuffer();
        if (hasXmlPrologue(original)) {
            String[] parts = original.split("\n", 2);
            sb.append(parts[0]).append("\n"); // xml prologue
            sb.append(styleSheetPath).append("\n");
            sb.append(parts[1]); // the rest 
        } else {
            sb.append(styleSheetPath).append("\n");
            sb.append(original); // the content 
        }
        return sb.toString();
    }

    boolean hasXmlPrologue(String responseStr) {
        return responseStr.startsWith("<?xml ");
    }

    String makeProcessingInstruction(ServletRequest request) {

        String basePath = "";
        if(request instanceof HttpServletRequest) {
            basePath = ((HttpServletRequest)request).getContextPath() + "/";
        }

        return "<?xml-stylesheet href=\"" + basePath + this.stylesheetPath + "\" type=\"text/xsl\"?>";
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

