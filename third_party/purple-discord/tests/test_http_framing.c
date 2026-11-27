#include "../purple2compat/http-framing.h"

#include <assert.h>

int main(void)
{
	assert(purple_http_get_body_mode("GET", 200, 1, 0) == PURPLE_HTTP_BODY_CONTENT_LENGTH);
	assert(purple_http_get_body_mode("GET", 204, 0, 0) == PURPLE_HTTP_BODY_NONE);
	assert(purple_http_get_body_mode("GET", 204, 1, 0) == PURPLE_HTTP_BODY_NONE);
	assert(purple_http_get_body_mode("GET", 304, 0, 0) == PURPLE_HTTP_BODY_NONE);
	assert(purple_http_get_body_mode("HEAD", 200, 1, 0) == PURPLE_HTTP_BODY_NONE);
	assert(purple_http_get_body_mode("GET", 200, 0, 1) == PURPLE_HTTP_BODY_CHUNKED);
	assert(purple_http_get_body_mode("GET", 200, 1, 1) == PURPLE_HTTP_BODY_CHUNKED);
	assert(purple_http_get_body_mode("GET", 101, 0, 0) == PURPLE_HTTP_BODY_NONE);
	assert(purple_http_get_body_mode("GET", 200, 0, 0) == PURPLE_HTTP_BODY_CLOSE_DELIMITED);
	return 0;
}
