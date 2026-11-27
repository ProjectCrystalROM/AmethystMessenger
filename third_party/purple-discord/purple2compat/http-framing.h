/* HTTP/1.1 response body framing shared by the compatibility client and tests. */
#ifndef PURPLE_HTTP_FRAMING_H
#define PURPLE_HTTP_FRAMING_H

typedef enum {
	PURPLE_HTTP_BODY_NONE,
	PURPLE_HTTP_BODY_CHUNKED,
	PURPLE_HTTP_BODY_CONTENT_LENGTH,
	PURPLE_HTTP_BODY_CLOSE_DELIMITED
} PurpleHttpBodyMode;

PurpleHttpBodyMode purple_http_get_body_mode(const char *request_method,
	int response_code, int has_content_length, int is_chunked);

#endif
