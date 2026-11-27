#include "http-framing.h"

#include <string.h>

PurpleHttpBodyMode
purple_http_get_body_mode(const char *request_method, int response_code,
			  int has_content_length, int is_chunked)
{
	if ((request_method != NULL && strcmp(request_method, "HEAD") == 0) ||
	    (response_code >= 100 && response_code < 200) ||
	    response_code == 204 || response_code == 304)
		return PURPLE_HTTP_BODY_NONE;

	/* Transfer-Encoding has precedence over Content-Length (RFC 9112 6.3). */
	if (is_chunked)
		return PURPLE_HTTP_BODY_CHUNKED;
	if (has_content_length)
		return PURPLE_HTTP_BODY_CONTENT_LENGTH;
	return PURPLE_HTTP_BODY_CLOSE_DELIMITED;
}
