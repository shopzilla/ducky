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