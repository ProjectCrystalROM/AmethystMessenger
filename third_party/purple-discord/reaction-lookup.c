#include "reaction-lookup.h"

#include <errno.h>

#define DISCORD_EPOCH_MS G_GUINT64_CONSTANT(1420070400000)

gboolean
discord_reaction_parse_snowflake(JsonObject *object, const gchar *member,
				 guint64 *value)
{
	JsonNode *node;
	const gchar *text;
	gchar *end = NULL;
	unsigned long long parsed;

	if (object == NULL || !json_object_has_member(object, member))
		return FALSE;
	if (value == NULL)
		return FALSE;
	node = json_object_get_member(object, member);
	if (node == NULL || !JSON_NODE_HOLDS_VALUE(node) ||
	    json_node_get_value_type(node) != G_TYPE_STRING)
		return FALSE;
	text = json_node_get_string(node);
	if (text == NULL || *text == '\0')
		return FALSE;
	for (const gchar *p = text; *p != '\0'; p++) {
		if (!g_ascii_isdigit(*p))
			return FALSE;
	}
	errno = 0;
	parsed = g_ascii_strtoull(text, &end, 10);
	if (errno != 0 || end == text || *end != '\0')
		return FALSE;
	*value = (guint64)parsed;
	return TRUE;
}

JsonObject *
discord_reaction_find_message(JsonNode *node, guint64 target_id)
{
	JsonArray *messages;
	guint i;

	if (node == NULL || !JSON_NODE_HOLDS_ARRAY(node))
		return NULL;
	messages = json_node_get_array(node);
	if (messages == NULL)
		return NULL;

	for (i = 0; i < json_array_get_length(messages); i++) {
		JsonNode *message_node = json_array_get_element(messages, i);
		JsonObject *message;
		guint64 message_id;

		if (message_node == NULL || !JSON_NODE_HOLDS_OBJECT(message_node))
			continue;
		message = json_node_get_object(message_node);
		if (discord_reaction_parse_snowflake(message, "id", &message_id) &&
		    message_id == target_id)
			return message;
	}

	return NULL;
}

JsonObject *
discord_reaction_find_message_at_time(JsonNode *node, time_t target_time)
{
	JsonArray *messages;
	JsonObject *best = NULL;
	guint64 best_id = G_MAXUINT64;
	guint i;

	if (node == NULL || !JSON_NODE_HOLDS_ARRAY(node))
		return NULL;
	messages = json_node_get_array(node);
	if (messages == NULL)
		return NULL;

	for (i = 0; i < json_array_get_length(messages); i++) {
		JsonNode *message_node = json_array_get_element(messages, i);
		JsonObject *message;
		guint64 message_id;
		guint64 seconds;

		if (message_node == NULL || !JSON_NODE_HOLDS_OBJECT(message_node))
			continue;
		message = json_node_get_object(message_node);
		if (!discord_reaction_parse_snowflake(message, "id", &message_id))
			continue;
		seconds = ((message_id >> 22) + DISCORD_EPOCH_MS) / 1000;
		if (seconds == (guint64)target_time && message_id < best_id) {
			best = message;
			best_id = message_id;
		}
	}

	return best;
}
