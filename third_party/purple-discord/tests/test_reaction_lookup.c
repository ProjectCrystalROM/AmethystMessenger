#include "../reaction-lookup.h"

#include <assert.h>
#include <string.h>

static JsonNode *
parse_json(const gchar *text)
{
	JsonParser *parser = json_parser_new();
	GError *error = NULL;
	assert(json_parser_load_from_data(parser, text, -1, &error));
	assert(error == NULL);
	JsonNode *node = json_node_copy(json_parser_get_root(parser));
	g_object_unref(parser);
	return node;
}

int main(void)
{
	JsonNode *node;
	JsonObject *message;
	guint64 id;
	time_t target_time = 1700000000;
	guint64 snowflake = (((guint64)target_time * 1000 - G_GUINT64_CONSTANT(1420070400000)) << 22);
	gchar *time_json = g_strdup_printf("[{\"id\":\"%" G_GUINT64_FORMAT "\"},{\"id\":\"%" G_GUINT64_FORMAT "\"}]", snowflake + (G_GUINT64_CONSTANT(1) << 22), snowflake);

	g_type_init();
	assert(discord_reaction_find_message(NULL, 42) == NULL);
	node = parse_json("{}");
	assert(discord_reaction_find_message(node, 42) == NULL);
	json_node_free(node);

	node = parse_json("[]");
	assert(discord_reaction_find_message(node, 42) == NULL);
	json_node_free(node);

	node = parse_json("[{\"id\":\"41\"},{\"id\":\"42\",\"author\":{\"id\":\"9\"},\"content\":\"target\"},{\"id\":\"43\"}]");
	message = discord_reaction_find_message(node, 42);
	assert(message != NULL);
	assert(strcmp(json_object_get_string_member(message, "content"), "target") == 0);
	assert(discord_reaction_parse_snowflake(message, "id", &id) && id == 42);
	json_node_free(node);

	node = parse_json("[{\"id\":\"41\"},{\"id\":\"43\"}]");
	assert(discord_reaction_find_message(node, 42) == NULL);
	json_node_free(node);

	node = parse_json("[null,{}, {\"id\":null}, {\"id\":\"42x\"}, {\"id\":42}]");
	assert(discord_reaction_find_message(node, 42) == NULL);
	json_node_free(node);

	node = parse_json(time_json);
	message = discord_reaction_find_message_at_time(node, target_time);
	assert(message != NULL);
	assert(discord_reaction_parse_snowflake(message, "id", &id) && id == snowflake);
	assert(discord_reaction_find_message_at_time(node, target_time + 1) == NULL);
	json_node_free(node);
	g_free(time_json);

	node = parse_json("{\"id\":\"42\"}");
	assert(!discord_reaction_parse_snowflake(json_node_get_object(node), "missing", &id));
	assert(discord_reaction_parse_snowflake(json_node_get_object(node), "id", &id) && id == 42);
	json_node_free(node);
	return 0;
}
